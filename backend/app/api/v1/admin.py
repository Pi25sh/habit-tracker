"""Admin dashboard API — RBAC-protected (admin role only)."""
import uuid
from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import audit, get_redis, require_admin
from app.db.session import get_db
from app.models.models import (
    AuditLog, Device, Habit, HabitLog, Photo, SystemLog, User, UserSession,
)
from app.schemas.schemas import DeviceOut, UserOut

router = APIRouter(prefix="/admin", tags=["admin"],
                   dependencies=[Depends(require_admin)])

DB = Annotated[AsyncSession, Depends(get_db)]
Admin = Annotated[User, Depends(require_admin)]


@router.get("/users")
async def list_users(db: DB, offset: int = 0, limit: int = 50,
                     search: str | None = None) -> dict:
    q = select(User)
    if search:
        q = q.where(User.email.ilike(f"%{search}%") | User.full_name.ilike(f"%{search}%"))
    total = await db.scalar(select(func.count()).select_from(q.subquery()))
    rows = await db.scalars(q.order_by(User.created_at.desc()).offset(offset).limit(min(limit, 200)))
    return {"total": total, "items": [UserOut.model_validate(u) for u in rows]}


@router.post("/users/{user_id}/deactivate")
async def deactivate_user(user_id: uuid.UUID, db: DB, admin: Admin) -> dict:
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    if user.id == admin.id:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "You cannot deactivate your own account")
    user.is_active = False
    now = datetime.now(timezone.utc)
    for s in await db.scalars(select(UserSession).where(
            UserSession.user_id == user.id, UserSession.revoked_at.is_(None))):
        s.revoked_at = now
    await audit(db, user_id=admin.id, action="admin.user_deactivated",
                resource=f"user:{user_id}")
    await db.commit()
    return {"detail": "User deactivated and sessions revoked"}


@router.post("/users/{user_id}/activate")
async def activate_user(user_id: uuid.UUID, db: DB, admin: Admin) -> dict:
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    user.is_active = True
    await audit(db, user_id=admin.id, action="admin.user_activated", resource=f"user:{user_id}")
    await db.commit()
    return {"detail": "User activated"}


@router.get("/devices")
async def list_all_devices(db: DB, offset: int = 0, limit: int = 50) -> dict:
    total = await db.scalar(select(func.count(Device.id)))
    rows = await db.scalars(select(Device).order_by(Device.created_at.desc())
                            .offset(offset).limit(min(limit, 200)))
    return {"total": total, "items": [DeviceOut.model_validate(d) for d in rows]}


@router.get("/habits")
async def list_all_habits(db: DB, user_id: uuid.UUID | None = None,
                          offset: int = 0, limit: int = 50) -> dict:
    q = select(Habit)
    if user_id:
        q = q.where(Habit.user_id == user_id)
    total = await db.scalar(select(func.count()).select_from(q.subquery()))
    rows = (await db.scalars(q.order_by(Habit.created_at.desc())
                             .offset(offset).limit(min(limit, 200)))).all()
    return {"total": total, "items": [
        {"id": str(h.id), "user_id": str(h.user_id), "name": h.name,
         "frequency": h.frequency.value, "is_archived": h.is_archived,
         "created_at": h.created_at.isoformat()} for h in rows]}


@router.delete("/habits/{habit_id}", status_code=204)
async def admin_delete_habit(habit_id: uuid.UUID, db: DB, admin: Admin) -> None:
    habit = await db.get(Habit, habit_id)
    if habit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Habit not found")
    await db.delete(habit)
    await audit(db, user_id=admin.id, action="admin.habit_deleted", resource=f"habit:{habit_id}")
    await db.commit()


@router.get("/analytics")
async def analytics(db: DB) -> dict:
    """Aggregated, privacy-preserving platform metrics."""
    week_ago = datetime.now(timezone.utc) - timedelta(days=7)
    return {
        "users_total": await db.scalar(select(func.count(User.id))),
        "users_active_7d": await db.scalar(select(func.count(func.distinct(HabitLog.user_id)))
                                           .where(HabitLog.created_at >= week_ago)),
        "devices_total": await db.scalar(select(func.count(Device.id))
                                         .where(Device.is_active.is_(True))),
        "habits_total": await db.scalar(select(func.count(Habit.id))
                                        .where(Habit.is_archived.is_(False))),
        "logs_7d": await db.scalar(select(func.count(HabitLog.id))
                                   .where(HabitLog.created_at >= week_ago)),
        "photos_total": await db.scalar(select(func.count(Photo.id))),
        "storage_bytes": await db.scalar(select(func.coalesce(
            func.sum(Photo.size_bytes), 0))),
    }


@router.get("/audit-logs")
async def audit_logs(db: DB, user_id: uuid.UUID | None = None,
                     action: str | None = None,
                     offset: int = 0, limit: int = 100) -> dict:
    q = select(AuditLog)
    if user_id:
        q = q.where(AuditLog.user_id == user_id)
    if action:
        q = q.where(AuditLog.action.startswith(action))
    total = await db.scalar(select(func.count()).select_from(q.subquery()))
    rows = (await db.scalars(q.order_by(AuditLog.created_at.desc())
                             .offset(offset).limit(min(limit, 500)))).all()
    return {"total": total, "items": [
        {"id": str(a.id), "user_id": str(a.user_id) if a.user_id else None,
         "action": a.action, "resource": a.resource, "detail": a.detail,
         "ip": a.actor_ip, "at": a.created_at.isoformat()} for a in rows]}


@router.get("/system-logs")
async def system_logs(db: DB, level: str | None = None,
                      offset: int = 0, limit: int = 100) -> dict:
    q = select(SystemLog)
    if level:
        q = q.where(SystemLog.level == level.upper())
    total = await db.scalar(select(func.count()).select_from(q.subquery()))
    rows = (await db.scalars(q.order_by(SystemLog.created_at.desc())
                             .offset(offset).limit(min(limit, 500)))).all()
    return {"total": total, "items": [
        {"id": str(s.id), "level": s.level, "source": s.source,
         "message": s.message, "context": s.context,
         "at": s.created_at.isoformat()} for s in rows]}


@router.get("/health-detail")
async def health_detail(db: DB) -> dict:
    """DB / Redis / storage reachability for the admin monitor page."""
    checks: dict[str, str] = {}
    try:
        await db.execute(select(1))
        checks["postgres"] = "ok"
    except Exception as e:
        checks["postgres"] = f"error: {e.__class__.__name__}"
    try:
        redis = await get_redis()
        await redis.ping()
        checks["redis"] = "ok"
    except Exception as e:
        checks["redis"] = f"error: {e.__class__.__name__}"
    try:
        from app.services.storage import ensure_bucket
        await ensure_bucket()
        checks["minio"] = "ok"
    except Exception as e:
        checks["minio"] = f"error: {e.__class__.__name__}"
    checks["status"] = "ok" if all(v == "ok" for k, v in checks.items()) else "degraded"
    return checks
