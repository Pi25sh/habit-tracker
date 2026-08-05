"""Unit tests: security primitives and streak math."""
import uuid
from datetime import date, timedelta

import pytest

from app.core import security
from app.models.models import Habit, HabitFrequency, HabitLog, HabitLogStatus
from app.services import stats


def test_password_hash_roundtrip():
    h = security.hash_password("CorrectHorse9")
    assert h != "CorrectHorse9"
    assert security.verify_password("CorrectHorse9", h)
    assert not security.verify_password("wrong", h)


def test_token_type_enforced():
    access = security.create_access_token("u1", "s1", "user")
    assert security.decode_token(access, "access") is not None
    assert security.decode_token(access, "refresh") is None
    assert security.decode_token("garbage", "access") is None


def test_field_encryption_roundtrip():
    ct = security.encrypt_field("12.9716,77.5946")
    assert ct != "12.9716,77.5946"
    assert security.decrypt_field(ct) == "12.9716,77.5946"


def _mk_habit(freq=HabitFrequency.daily, cfg=None, start=None):
    return Habit(id=uuid.uuid4(), user_id=uuid.uuid4(), name="t",
                 frequency=freq, frequency_config=cfg,
                 start_date=start or date.today() - timedelta(days=30))


def test_is_scheduled_daily():
    h = _mk_habit()
    assert stats._is_scheduled(h, date.today())
    assert not stats._is_scheduled(h, h.start_date - timedelta(days=1))


def test_is_scheduled_weekly():
    h = _mk_habit(HabitFrequency.weekly, {"days_of_week": [1]})  # Mondays
    d = date.today()
    while d.isoweekday() != 1:
        d -= timedelta(days=1)
    assert stats._is_scheduled(h, d)
    assert not stats._is_scheduled(h, d + timedelta(days=1))


def test_is_scheduled_interval():
    start = date(2026, 1, 1)
    h = _mk_habit(HabitFrequency.custom, {"interval_days": 3}, start=start)
    assert stats._is_scheduled(h, start)
    assert not stats._is_scheduled(h, start + timedelta(days=1))
    assert stats._is_scheduled(h, start + timedelta(days=3))


@pytest.mark.asyncio
async def test_streaks_consecutive(db):
    h = _mk_habit(start=date.today() - timedelta(days=10))
    db.add(h)
    await db.flush()
    # completed the last 4 days including today
    for i in range(4):
        db.add(HabitLog(habit_id=h.id, user_id=h.user_id,
                        log_date=date.today() - timedelta(days=i),
                        status=HabitLogStatus.completed))
    await db.flush()
    cur, best = await stats.compute_streaks(db, h)
    assert cur == 4
    assert best == 4


@pytest.mark.asyncio
async def test_streak_broken_by_gap(db):
    h = _mk_habit(start=date.today() - timedelta(days=10))
    db.add(h)
    await db.flush()
    for i in (0, 1, 3, 4, 5):  # gap at day-2
        db.add(HabitLog(habit_id=h.id, user_id=h.user_id,
                        log_date=date.today() - timedelta(days=i),
                        status=HabitLogStatus.completed))
    await db.flush()
    cur, best = await stats.compute_streaks(db, h)
    assert cur == 2      # today + yesterday
    assert best == 3     # days 3-5


@pytest.mark.asyncio
async def test_today_incomplete_does_not_break_streak(db):
    h = _mk_habit(start=date.today() - timedelta(days=10))
    db.add(h)
    await db.flush()
    for i in (1, 2, 3):  # done the 3 previous days, not yet today
        db.add(HabitLog(habit_id=h.id, user_id=h.user_id,
                        log_date=date.today() - timedelta(days=i),
                        status=HabitLogStatus.completed))
    await db.flush()
    cur, _ = await stats.compute_streaks(db, h)
    assert cur == 3
