"""FastAPI dependencies: current user, RBAC, rate limiting, audit logging."""
import hashlib
import uuid
from typing import Annotated

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from redis.asyncio import Redis, from_url
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import decode_token
from app.db.session import get_db
from app.models.models import AuditLog, User, UserRole, UserSession

_bearer = HTTPBearer(auto_error=False)

_redis: Redis | None = None


async def get_redis() -> Redis:
    global _redis
    if _redis is None:
        _redis = from_url(str(settings.REDIS_URL), decode_responses=True)
    return _redis


def hash_refresh_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


async def get_current_user(
    request: Request,
    creds: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    if creds is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Not authenticated")
    payload = decode_token(creds.credentials, "access")
    if payload is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token")

    # Session must still be live (multi-device logout / revocation support).
    session = await db.get(UserSession, uuid.UUID(payload["sid"]))
    if session is None or session.revoked_at is not None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Session revoked")

    user = await db.get(User, uuid.UUID(payload["sub"]))
    if user is None or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Account disabled")
    request.state.session_id = session.id
    return user


async def require_admin(user: Annotated[User, Depends(get_current_user)]) -> User:
    if user.role != UserRole.admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin privileges required")
    return user


async def rate_limit(request: Request, limit: int = 120, window_s: int = 60,
                     bucket: str = "default") -> None:
    """Fixed-window limiter keyed on client IP (or user id when authenticated)."""
    redis = await get_redis()
    ident = getattr(request.state, "user_id", None) or (request.client.host if request.client else "?")
    key = f"rl:{bucket}:{ident}"
    n = await redis.incr(key)
    if n == 1:
        await redis.expire(key, window_s)
    if n > limit:
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "Rate limit exceeded")


def auth_rate_limit(bucket: str):
    """Stricter limiter for auth endpoints (brute-force protection)."""
    async def _dep(request: Request):
        await rate_limit(request, limit=10, window_s=60, bucket=bucket)
    return _dep


async def audit(db: AsyncSession, *, user_id: uuid.UUID | None, action: str,
                resource: str | None = None, detail: dict | None = None,
                ip: str | None = None) -> None:
    db.add(AuditLog(user_id=user_id, action=action, resource=resource,
                    detail=detail, actor_ip=ip))
    # committed alongside the caller's transaction
