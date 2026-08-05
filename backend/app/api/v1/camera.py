"""Camera sessions — consent-gated remote camera requests.

Server-enforced invariants (mirroring the location module):
  * Only the device OWNER can create a session, and only targeting their own device.
  * The device shows a full-screen approval prompt; the camera opens ONLY after
    the human taps Approve. Approval is proven by echoing a one-time nonce that
    was delivered in the push payload — the server never opens anything itself.
  * Sessions expire in 2 minutes if unanswered.
  * Uploads are only accepted for sessions in `approved` state, and close the session.
  * Every transition (requested / approved / denied / expired / completed) is audit-logged.
  * There is deliberately NO code path that activates a camera silently.
"""
import hashlib
import uuid
from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile, status
from fastapi import Form
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import audit, get_current_user
from app.core.security import generate_opaque_token
from app.db.session import get_db
from app.models.models import (
    CameraSession, CameraSessionStatus, Device, Photo, User,
)
from app.schemas.schemas import (
    CameraSessionOut, CameraSessionRequest, CameraSessionResponse, PhotoOut,
)
from app.services.fcm import send_push
from app.services.storage import presigned_url, validate_and_store_image

router = APIRouter(tags=["camera"])

DB = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]

SESSION_TTL = timedelta(minutes=2)


def _hash_nonce(nonce: str) -> str:
    return hashlib.sha256(nonce.encode()).hexdigest()


@router.post("/request-camera-session", status_code=201)
async def request_camera_session(body: CameraSessionRequest, request: Request,
                                 db: DB, user: CurrentUser) -> CameraSessionOut:
    device = await db.get(Device, body.target_device_id)
    if device is None or device.user_id != user.id or not device.is_active:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Device not found")
    if not device.fcm_token:
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Device has no push channel; open the app on it instead")

    nonce = generate_opaque_token()
    session = CameraSession(
        user_id=user.id, target_device_id=device.id, purpose=body.purpose,
        nonce_hash=_hash_nonce(nonce),
        expires_at=datetime.now(timezone.utc) + SESSION_TTL)
    db.add(session)
    await db.flush()
    await audit(db, user_id=user.id, action="camera.session.requested",
                resource=f"device:{device.id}",
                detail={"session_id": str(session.id), "purpose": body.purpose.value},
                ip=request.client.host if request.client else None)
    await db.commit()

    # Visible push -> the app shows a FULL-SCREEN approval prompt. Nothing opens
    # until the human on that device taps Approve.
    await send_push(device.fcm_token,
                    "Camera request",
                    f"A camera session ({body.purpose.value.replace('_', ' ')}) was "
                    f"requested from your account. Approve or deny on this device.",
                    data={"type": "camera_request", "session_id": str(session.id),
                          "purpose": body.purpose.value, "nonce": nonce})
    return CameraSessionOut.model_validate(session)


@router.post("/camera-session-response")
async def camera_session_response(body: CameraSessionResponse, request: Request,
                                  db: DB, user: CurrentUser) -> CameraSessionOut:
    """Called by the TARGET device after the user answers the full-screen prompt."""
    session = await db.get(CameraSession, body.session_id)
    if session is None or session.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Session not found")
    if session.status != CameraSessionStatus.pending:
        raise HTTPException(status.HTTP_409_CONFLICT, f"Session already {session.status.value}")
    if datetime.now(timezone.utc) > session.expires_at:
        session.status = CameraSessionStatus.expired
        await audit(db, user_id=user.id, action="camera.session.expired",
                    detail={"session_id": str(session.id)})
        await db.commit()
        raise HTTPException(status.HTTP_410_GONE, "Session expired")
    if _hash_nonce(body.nonce) != session.nonce_hash:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid session nonce")

    session.status = (CameraSessionStatus.approved if body.approved
                      else CameraSessionStatus.denied)
    session.responded_at = datetime.now(timezone.utc)
    await audit(db, user_id=user.id,
                action=f"camera.session.{'approved' if body.approved else 'denied'}",
                resource=f"device:{session.target_device_id}",
                detail={"session_id": str(session.id)},
                ip=request.client.host if request.client else None)
    await db.commit()
    return CameraSessionOut.model_validate(session)


@router.post("/upload-camera-photo", status_code=201)
async def upload_camera_photo(
    db: DB, user: CurrentUser, request: Request,
    session_id: uuid.UUID = Form(...),
    file: UploadFile = File(...),
    habit_log_id: uuid.UUID | None = Form(default=None),
) -> PhotoOut:
    """Accepts media only for an APPROVED session, then closes it (single use)."""
    session = await db.get(CameraSession, session_id)
    if session is None or session.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Session not found")
    if session.status != CameraSessionStatus.approved:
        raise HTTPException(status.HTTP_403_FORBIDDEN,
                            "Upload requires an approved camera session")
    key, mime, size, digest = await validate_and_store_image(file, user.id, prefix="camera")
    photo = Photo(user_id=user.id, habit_log_id=habit_log_id,
                  camera_session_id=session.id, object_key=key,
                  content_type=mime, size_bytes=size, sha256=digest)
    session.status = CameraSessionStatus.completed
    db.add(photo)
    await audit(db, user_id=user.id, action="camera.session.completed",
                resource=f"device:{session.target_device_id}",
                detail={"session_id": str(session.id), "photo_id": str(photo.id)},
                ip=request.client.host if request.client else None)
    await db.commit()
    out = PhotoOut.model_validate(photo)
    out.url = await presigned_url(key)
    return out


@router.get("/camera-sessions")
async def list_camera_sessions(db: DB, user: CurrentUser) -> list[CameraSessionOut]:
    from sqlalchemy import select
    rows = await db.scalars(
        select(CameraSession).where(CameraSession.user_id == user.id)
        .order_by(CameraSession.created_at.desc()).limit(50))
    return [CameraSessionOut.model_validate(s) for s in rows]
