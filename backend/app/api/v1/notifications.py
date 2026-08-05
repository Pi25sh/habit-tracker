"""Notifications: send, list, mark read; reminder schedule CRUD."""
import uuid
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import audit, get_current_user
from app.db.session import get_db
from app.models.models import (
    Device, Habit, Notification, NotificationChannel, ReminderSchedule, User, UserRole,
)
from app.schemas.schemas import NotificationOut, SendNotificationRequest
from app.services.fcm import send_push

router = APIRouter(tags=["notifications"])

DB = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]


@router.post("/send-notification", status_code=201)
async def send_notification(body: SendNotificationRequest, db: DB,
                            user: CurrentUser) -> dict:
    """Users may notify themselves (e.g. test); admins may target any user."""
    target_id = body.user_id or user.id
    if target_id != user.id and user.role != UserRole.admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN,
                            "Only admins can notify other users")
    devices = (await db.scalars(select(Device).where(
        Device.user_id == target_id, Device.is_active.is_(True),
        Device.fcm_token.is_not(None)))).all()
    notif = Notification(user_id=target_id, channel=NotificationChannel.push,
                         title=body.title, body=body.body, data=body.data,
                         sent_at=datetime.now(timezone.utc))
    db.add(notif)
    delivered = 0
    for d in devices:
        if await send_push(d.fcm_token, body.title, body.body, body.data):
            delivered += 1
    await audit(db, user_id=user.id, action="notification.sent",
                resource=f"user:{target_id}", detail={"delivered": delivered})
    await db.commit()
    return {"detail": "Notification queued", "devices_reached": delivered}


@router.get("/notifications")
async def list_notifications(db: DB, user: CurrentUser,
                             unread_only: bool = False) -> list[NotificationOut]:
    q = select(Notification).where(Notification.user_id == user.id)
    if unread_only:
        q = q.where(Notification.read_at.is_(None))
    rows = await db.scalars(q.order_by(Notification.created_at.desc()).limit(100))
    return [NotificationOut.model_validate(n) for n in rows]


@router.post("/notifications/{notification_id}/read")
async def mark_read(notification_id: uuid.UUID, db: DB, user: CurrentUser) -> dict:
    n = await db.get(Notification, notification_id)
    if n is None or n.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Notification not found")
    n.read_at = datetime.now(timezone.utc)
    await db.commit()
    return {"detail": "Marked read"}


# ---------------- reminder schedules ----------------

class ReminderCreate(BaseModel):
    habit_id: uuid.UUID
    time_local: str = Field(pattern=r"^([01]\d|2[0-3]):[0-5]\d$")
    days_of_week: list[int] | None = None
    repeat_after_minutes: int | None = Field(default=None, ge=5, le=720)
    smart: bool = False


class ReminderOut(BaseModel):
    model_config = {"from_attributes": True}
    id: uuid.UUID
    habit_id: uuid.UUID
    time_local: str
    days_of_week: list[int] | None
    is_enabled: bool
    repeat_after_minutes: int | None
    smart: bool


@router.get("/reminders")
async def list_reminders(db: DB, user: CurrentUser) -> list[ReminderOut]:
    rows = await db.scalars(
        select(ReminderSchedule).join(Habit).where(Habit.user_id == user.id))
    return [ReminderOut.model_validate(r) for r in rows]


@router.post("/reminders", status_code=201)
async def create_reminder(body: ReminderCreate, db: DB, user: CurrentUser) -> ReminderOut:
    habit = await db.get(Habit, body.habit_id)
    if habit is None or habit.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Habit not found")
    r = ReminderSchedule(**body.model_dump())
    db.add(r)
    await db.commit()
    return ReminderOut.model_validate(r)


@router.delete("/reminders/{reminder_id}", status_code=204)
async def delete_reminder(reminder_id: uuid.UUID, db: DB, user: CurrentUser) -> None:
    r = await db.get(ReminderSchedule, reminder_id)
    if r is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Reminder not found")
    habit = await db.get(Habit, r.habit_id)
    if habit is None or habit.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Reminder not found")
    await db.delete(r)
    await db.commit()
