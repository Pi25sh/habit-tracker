"""Authentication: register, verify, login (email + Google), refresh rotation,
logout, forgot/reset password, session & device management."""
import uuid
from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, status
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import audit, auth_rate_limit, get_current_user, hash_refresh_token
from app.core.config import settings
from app.core.security import (
    create_access_token, create_email_token, create_password_reset_token,
    create_refresh_token, decode_token, hash_password, verify_password,
)
from app.db.session import get_db
from app.models.models import AuthProvider, Device, User, UserSession, UserSettings
from app.schemas.schemas import (
    DeviceOut, DeviceRegister, ForgotPasswordRequest, GoogleLoginRequest, LoginRequest,
    RefreshRequest, RegisterRequest, ResetPasswordRequest, SessionOut, TokenPair, UserOut,
)
from app.services.email import send_password_reset_email, send_verification_email

router = APIRouter(prefix="/auth", tags=["auth"])

DB = Annotated[AsyncSession, Depends(get_db)]


async def _register_device(db: AsyncSession, user_id: uuid.UUID,
                           reg: DeviceRegister | None) -> Device | None:
    if reg is None:
        return None
    device = Device(user_id=user_id, name=reg.name, platform=reg.platform,
                    model=reg.model, fcm_token=reg.fcm_token, app_version=reg.app_version,
                    last_seen_at=datetime.now(timezone.utc))
    db.add(device)
    await db.flush()
    return device


async def _issue_tokens(db: AsyncSession, request: Request, user: User,
                        device: Device | None) -> TokenPair:
    session = UserSession(
        user_id=user.id, device_id=device.id if device else None,
        refresh_token_hash="",  # set below once we have the token
        ip_address=request.client.host if request.client else None,
        user_agent=(request.headers.get("user-agent") or "")[:255],
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS))
    db.add(session)
    await db.flush()
    refresh = create_refresh_token(str(user.id), str(session.id))
    session.refresh_token_hash = hash_refresh_token(refresh)
    access = create_access_token(str(user.id), str(session.id), user.role.value)
    return TokenPair(access_token=access, refresh_token=refresh,
                     expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)


@router.post("/register", status_code=201,
             dependencies=[Depends(auth_rate_limit("register"))])
async def register(body: RegisterRequest, request: Request, db: DB) -> UserOut:
    existing = await db.scalar(select(User).where(User.email == body.email.lower()))
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "Email already registered")
    user = User(email=body.email.lower(), password_hash=hash_password(body.password),
                full_name=body.full_name, timezone=body.timezone)
    user.settings = UserSettings()
    db.add(user)
    await db.flush()
    await audit(db, user_id=user.id, action="auth.register",
                ip=request.client.host if request.client else None)
    await db.commit()
    await send_verification_email(user.email, create_email_token(str(user.id)))
    return UserOut.model_validate(user)


@router.post("/verify-email")
async def verify_email(token: str, db: DB) -> dict:
    payload = decode_token(token, "email_verify")
    if payload is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid or expired verification link")
    user = await db.get(User, uuid.UUID(payload["sub"]))
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    user.is_email_verified = True
    await audit(db, user_id=user.id, action="auth.email_verified")
    await db.commit()
    return {"detail": "Email verified"}


@router.post("/login", dependencies=[Depends(auth_rate_limit("login"))])
async def login(body: LoginRequest, request: Request, db: DB) -> TokenPair:
    user = await db.scalar(select(User).where(User.email == body.email.lower()))
    # Constant-shape response for wrong email vs wrong password.
    if user is None or user.password_hash is None or not verify_password(
            body.password, user.password_hash):
        await audit(db, user_id=user.id if user else None, action="auth.login_failed",
                    ip=request.client.host if request.client else None)
        await db.commit()
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid email or password")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account disabled")
    device = await _register_device(db, user.id, body.device)
    tokens = await _issue_tokens(db, request, user, device)
    await audit(db, user_id=user.id, action="auth.login",
                ip=request.client.host if request.client else None)
    await db.commit()
    return tokens


@router.post("/google", dependencies=[Depends(auth_rate_limit("google"))])
async def google_login(body: GoogleLoginRequest, request: Request, db: DB) -> TokenPair:
    try:
        info = google_id_token.verify_oauth2_token(
            body.id_token, google_requests.Request(), settings.GOOGLE_CLIENT_ID)
    except ValueError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid Google token")
    email = info["email"].lower()
    user = await db.scalar(select(User).where(User.google_sub == info["sub"]))
    if user is None:
        user = await db.scalar(select(User).where(User.email == email))
        if user:  # link google to existing email account
            user.google_sub = info["sub"]
        else:
            user = User(email=email, full_name=info.get("name", email.split("@")[0]),
                        auth_provider=AuthProvider.google, google_sub=info["sub"],
                        is_email_verified=info.get("email_verified", False))
            user.settings = UserSettings()
            db.add(user)
            await db.flush()
    device = await _register_device(db, user.id, body.device)
    tokens = await _issue_tokens(db, request, user, device)
    await audit(db, user_id=user.id, action="auth.google_login",
                ip=request.client.host if request.client else None)
    await db.commit()
    return tokens


@router.post("/refresh")
async def refresh(body: RefreshRequest, request: Request, db: DB) -> TokenPair:
    """Rotate the refresh token. Reuse of a rotated token revokes the whole session."""
    payload = decode_token(body.refresh_token, "refresh")
    if payload is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid refresh token")
    session = await db.get(UserSession, uuid.UUID(payload["sid"]))
    if session is None or session.revoked_at is not None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Session revoked")
    if session.refresh_token_hash != hash_refresh_token(body.refresh_token):
        # Token reuse — likely theft. Kill the session.
        session.revoked_at = datetime.now(timezone.utc)
        await audit(db, user_id=session.user_id, action="auth.refresh_reuse_detected",
                    resource=f"session:{session.id}")
        await db.commit()
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token reuse detected; session revoked")
    user = await db.get(User, session.user_id)
    if user is None or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Account disabled")
    new_refresh = create_refresh_token(str(user.id), str(session.id))
    session.refresh_token_hash = hash_refresh_token(new_refresh)
    access = create_access_token(str(user.id), str(session.id), user.role.value)
    await db.commit()
    return TokenPair(access_token=access, refresh_token=new_refresh,
                     expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)


@router.post("/logout")
async def logout(request: Request, db: DB,
                 user: Annotated[User, Depends(get_current_user)]) -> dict:
    session = await db.get(UserSession, request.state.session_id)
    if session:
        session.revoked_at = datetime.now(timezone.utc)
    await audit(db, user_id=user.id, action="auth.logout")
    await db.commit()
    return {"detail": "Logged out"}


@router.post("/forgot-password", dependencies=[Depends(auth_rate_limit("forgot"))])
async def forgot_password(body: ForgotPasswordRequest, db: DB) -> dict:
    user = await db.scalar(select(User).where(User.email == body.email.lower()))
    if user and user.password_hash is not None:
        await send_password_reset_email(user.email, create_password_reset_token(str(user.id)))
    # Same response either way — don't leak which emails exist.
    return {"detail": "If that email is registered, a reset link has been sent"}


@router.post("/reset-password")
async def reset_password(body: ResetPasswordRequest, db: DB) -> dict:
    payload = decode_token(body.token, "password_reset")
    if payload is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid or expired reset link")
    user = await db.get(User, uuid.UUID(payload["sub"]))
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    user.password_hash = hash_password(body.new_password)
    # Revoke all sessions after a password reset.
    sessions = await db.scalars(select(UserSession).where(
        UserSession.user_id == user.id, UserSession.revoked_at.is_(None)))
    now = datetime.now(timezone.utc)
    for s in sessions:
        s.revoked_at = now
    await audit(db, user_id=user.id, action="auth.password_reset")
    await db.commit()
    return {"detail": "Password updated; please log in again"}


# ---- session & device management (multi-device login) ----

@router.get("/sessions")
async def list_sessions(db: DB, user: Annotated[User, Depends(get_current_user)]
                        ) -> list[SessionOut]:
    rows = await db.scalars(select(UserSession).where(
        UserSession.user_id == user.id, UserSession.revoked_at.is_(None))
        .order_by(UserSession.created_at.desc()))
    return [SessionOut.model_validate(s) for s in rows]


@router.delete("/sessions/{session_id}")
async def revoke_session(session_id: uuid.UUID, db: DB,
                         user: Annotated[User, Depends(get_current_user)]) -> dict:
    session = await db.get(UserSession, session_id)
    if session is None or session.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Session not found")
    session.revoked_at = datetime.now(timezone.utc)
    await audit(db, user_id=user.id, action="auth.session_revoked",
                resource=f"session:{session_id}")
    await db.commit()
    return {"detail": "Session revoked"}


@router.get("/devices")
async def list_devices(db: DB, user: Annotated[User, Depends(get_current_user)]
                       ) -> list[DeviceOut]:
    rows = await db.scalars(select(Device).where(
        Device.user_id == user.id, Device.is_active.is_(True)))
    return [DeviceOut.model_validate(d) for d in rows]


@router.post("/devices", status_code=201)
async def register_device(body: DeviceRegister, db: DB,
                          user: Annotated[User, Depends(get_current_user)]) -> DeviceOut:
    device = await _register_device(db, user.id, body)
    await audit(db, user_id=user.id, action="device.registered", resource=f"device:{device.id}")
    await db.commit()
    return DeviceOut.model_validate(device)


@router.delete("/devices/{device_id}")
async def remove_device(device_id: uuid.UUID, db: DB,
                        user: Annotated[User, Depends(get_current_user)]) -> dict:
    device = await db.get(Device, device_id)
    if device is None or device.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Device not found")
    device.is_active = False
    device.fcm_token = None
    device.location_sharing_enabled = False
    await audit(db, user_id=user.id, action="device.removed", resource=f"device:{device_id}")
    await db.commit()
    return {"detail": "Device removed"}


@router.get("/me")
async def me(user: Annotated[User, Depends(get_current_user)]) -> UserOut:
    return UserOut.model_validate(user)
