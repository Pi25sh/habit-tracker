"""Background tasks: smart reminders, missed-habit nags, weekly summaries,
monthly reports, camera-session expiry, location-history retention.

Run with:  python -m app.tasks.scheduler
A single asyncio process using Redis locks so multiple replicas don't double-send.
"""
import asyncio
import logging
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from redis.asyncio import from_url
from sqlalchemy import delete, select

from app.core.config import settings
from app.db.session import AsyncSessionLocal
from app.models.models import (
    CameraSession, CameraSessionStatus, Device, Habit, HabitLog, HabitLogStatus,
    LocationHistory, ReminderSchedule, User, UserSettings,
)
from app.services import stats as stats_svc
from app.services.email import send_weekly_summary
from app.services.fcm import send_push

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("scheduler")

LOCATION_HISTORY_RETENTION_DAYS = 30


async def _with_lock(redis, name: str, ttl: int, coro) -> None:
    """Cross-replica mutex so a task fires exactly once per tick."""
    if await redis.set(f"lock:{name}", "1", nx=True, ex=ttl):
        try:
            await coro
        except Exception:
            log.exception("task %s failed", name)


async def fire_due_reminders() -> None:
    """Every minute: find reminders whose local time == now in the user's TZ."""
    now_utc = datetime.now(timezone.utc)
    async with AsyncSessionLocal() as db:
        rows = (await db.execute(
            select(ReminderSchedule, Habit, User)
            .join(Habit, ReminderSchedule.habit_id == Habit.id)
            .join(User, Habit.user_id == User.id)
            .where(ReminderSchedule.is_enabled.is_(True),
                   Habit.is_archived.is_(False)))).all()
        for reminder, habit, user in rows:
            try:
                local = now_utc.astimezone(ZoneInfo(user.timezone))
            except Exception:
                local = now_utc
            if local.strftime("%H:%M") != reminder.time_local:
                continue
            if reminder.days_of_week and local.isoweekday() not in reminder.days_of_week:
                continue
            # Skip if already completed today.
            done = await db.scalar(select(HabitLog.id).where(
                HabitLog.habit_id == habit.id,
                HabitLog.log_date == local.date(),
                HabitLog.status == HabitLogStatus.completed))
            if done:
                continue
            devices = (await db.scalars(select(Device).where(
                Device.user_id == user.id, Device.is_active.is_(True),
                Device.fcm_token.is_not(None)))).all()
            for d in devices:
                await send_push(d.fcm_token, f"Time for: {habit.name}",
                                f"Keep your {habit.name} streak going 💪",
                                {"type": "habit_reminder", "habit_id": str(habit.id)})


async def missed_habit_nags() -> None:
    """At each user's local 20:00: nag about habits still incomplete today."""
    now_utc = datetime.now(timezone.utc)
    async with AsyncSessionLocal() as db:
        users = (await db.scalars(select(User).where(User.is_active.is_(True)))).all()
        for user in users:
            try:
                local = now_utc.astimezone(ZoneInfo(user.timezone))
            except Exception:
                continue
            if local.strftime("%H:%M") != "20:00":
                continue
            habits = (await db.scalars(select(Habit).where(
                Habit.user_id == user.id, Habit.is_archived.is_(False)))).all()
            pending = []
            for h in habits:
                if not stats_svc._is_scheduled(h, local.date()):
                    continue
                done = await db.scalar(select(HabitLog.id).where(
                    HabitLog.habit_id == h.id, HabitLog.log_date == local.date(),
                    HabitLog.status == HabitLogStatus.completed))
                if not done:
                    pending.append(h.name)
            if not pending:
                continue
            devices = (await db.scalars(select(Device).where(
                Device.user_id == user.id, Device.is_active.is_(True),
                Device.fcm_token.is_not(None)))).all()
            names = ", ".join(pending[:3]) + ("…" if len(pending) > 3 else "")
            for d in devices:
                await send_push(d.fcm_token, "Almost bedtime ⏰",
                                f"Still pending today: {names}",
                                {"type": "missed_habits"})


async def weekly_summaries() -> None:
    """Sunday 18:00 local: email each opted-in user their week."""
    now_utc = datetime.now(timezone.utc)
    async with AsyncSessionLocal() as db:
        rows = (await db.execute(
            select(User, UserSettings).join(UserSettings)
            .where(User.is_active.is_(True),
                   UserSettings.weekly_summary_enabled.is_(True)))).all()
        for user, _ in rows:
            try:
                local = now_utc.astimezone(ZoneInfo(user.timezone))
            except Exception:
                continue
            if not (local.isoweekday() == 7 and local.strftime("%H:%M") == "18:00"):
                continue
            habits = (await db.scalars(select(Habit).where(
                Habit.user_id == user.id, Habit.is_archived.is_(False)))).all()
            lines = []
            for h in habits:
                rate = await stats_svc.completion_rate(db, h, 7)
                cur, _best = await stats_svc.compute_streaks(db, h)
                lines.append(f"<li><b>{h.name}</b>: {rate:.0%} this week, "
                             f"streak {cur} days</li>")
            if lines:
                await send_weekly_summary(user.email, user.full_name,
                                          f"<ul>{''.join(lines)}</ul>")


async def expire_camera_sessions() -> None:
    async with AsyncSessionLocal() as db:
        rows = (await db.scalars(select(CameraSession).where(
            CameraSession.status == CameraSessionStatus.pending,
            CameraSession.expires_at < datetime.now(timezone.utc)))).all()
        for s in rows:
            s.status = CameraSessionStatus.expired
        await db.commit()


async def prune_location_history() -> None:
    cutoff = datetime.now(timezone.utc) - timedelta(days=LOCATION_HISTORY_RETENTION_DAYS)
    async with AsyncSessionLocal() as db:
        await db.execute(delete(LocationHistory).where(
            LocationHistory.recorded_at < cutoff))
        await db.commit()


async def main() -> None:
    redis = from_url(str(settings.REDIS_URL), decode_responses=True)
    log.info("scheduler started")
    while True:
        await _with_lock(redis, "reminders", 55, fire_due_reminders())
        await _with_lock(redis, "missed", 55, missed_habit_nags())
        await _with_lock(redis, "weekly", 55, weekly_summaries())
        await _with_lock(redis, "camexpire", 55, expire_camera_sessions())
        # retention prune hourly
        minute = datetime.now(timezone.utc).minute
        if minute == 0:
            await _with_lock(redis, "locprune", 3500, prune_location_history())
        await asyncio.sleep(60)


if __name__ == "__main__":
    asyncio.run(main())
