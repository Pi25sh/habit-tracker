"""Habit statistics: streaks, completion rates, heatmap data."""
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import Habit, HabitFrequency, HabitLog, HabitLogStatus


def _is_scheduled(habit: Habit, d: date) -> bool:
    """Is this habit due on day `d` given its frequency rules?"""
    if d < habit.start_date:
        return False
    cfg = habit.frequency_config or {}
    if habit.frequency == HabitFrequency.daily:
        return True
    if habit.frequency == HabitFrequency.weekly:
        days = cfg.get("days_of_week", [1])  # ISO: 1=Mon
        return d.isoweekday() in days
    if habit.frequency == HabitFrequency.monthly:
        return d.day in cfg.get("days_of_month", [1])
    # custom
    if "days_of_week" in cfg:
        return d.isoweekday() in cfg["days_of_week"]
    if "interval_days" in cfg:
        return (d - habit.start_date).days % max(cfg["interval_days"], 1) == 0
    if "times_per_week" in cfg:
        return True  # any day counts; streaks measured weekly
    return True


async def compute_streaks(db: AsyncSession, habit: Habit, today: date | None = None
                          ) -> tuple[int, int]:
    """Return (current_streak, best_streak) in scheduled-day units."""
    today = today or date.today()
    rows = await db.execute(
        select(HabitLog.log_date, HabitLog.status)
        .where(HabitLog.habit_id == habit.id)
        .order_by(HabitLog.log_date))
    done = {r.log_date for r in rows if r.status == HabitLogStatus.completed}

    if not done:
        return 0, 0

    # Walk from the first log to today, counting runs over *scheduled* days only.
    best = cur = 0
    run = 0
    d = min(min(done), habit.start_date)
    while d <= today:
        if _is_scheduled(habit, d):
            if d in done:
                run += 1
                best = max(best, run)
            elif d < today:   # today isn't a break until it's over
                run = 0
        d += timedelta(days=1)
    cur = run
    return cur, best


async def completion_rate(db: AsyncSession, habit: Habit, days: int | None = 30,
                          today: date | None = None) -> float:
    today = today or date.today()
    start = habit.start_date if days is None else max(habit.start_date, today - timedelta(days=days))
    scheduled = [d for d in _daterange(start, today) if _is_scheduled(habit, d)]
    if not scheduled:
        return 0.0
    rows = await db.execute(
        select(HabitLog.log_date).where(
            HabitLog.habit_id == habit.id,
            HabitLog.status == HabitLogStatus.completed,
            HabitLog.log_date >= start, HabitLog.log_date <= today))
    done = {r.log_date for r in rows}
    return round(len([d for d in scheduled if d in done]) / len(scheduled), 4)


async def heatmap(db: AsyncSession, habit: Habit, days: int = 365) -> dict[str, int]:
    start = date.today() - timedelta(days=days)
    rows = await db.execute(
        select(HabitLog.log_date, HabitLog.value).where(
            HabitLog.habit_id == habit.id,
            HabitLog.status == HabitLogStatus.completed,
            HabitLog.log_date >= start))
    return {r.log_date.isoformat(): r.value for r in rows}


def _daterange(start: date, end: date):
    d = start
    while d <= end:
        yield d
        d += timedelta(days=1)
