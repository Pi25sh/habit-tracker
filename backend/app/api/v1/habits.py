"""Habits CRUD, categories, logging, history, stats."""
import uuid
from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.models import Category, Habit, HabitLog, User
from app.schemas.schemas import (
    CategoryCreate, CategoryOut, HabitCreate, HabitLogCreate, HabitLogOut,
    HabitOut, HabitStats, HabitUpdate,
)
from app.services import stats as stats_svc

router = APIRouter(tags=["habits"])

DB = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]


async def _owned_habit(db: AsyncSession, user: User, habit_id: uuid.UUID) -> Habit:
    habit = await db.get(Habit, habit_id)
    if habit is None or habit.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Habit not found")
    return habit


async def _habit_out(db: AsyncSession, habit: Habit) -> HabitOut:
    out = HabitOut.model_validate(habit)
    out.current_streak, out.best_streak = await stats_svc.compute_streaks(db, habit)
    out.completion_rate_30d = await stats_svc.completion_rate(db, habit, 30)
    return out


@router.get("/habits")
async def list_habits(db: DB, user: CurrentUser,
                      include_archived: bool = False) -> list[HabitOut]:
    q = select(Habit).where(Habit.user_id == user.id).order_by(Habit.sort_order, Habit.created_at)
    if not include_archived:
        q = q.where(Habit.is_archived.is_(False))
    habits = (await db.scalars(q)).all()
    return [await _habit_out(db, h) for h in habits]


@router.post("/habits", status_code=201)
async def create_habit(body: HabitCreate, db: DB, user: CurrentUser) -> HabitOut:
    if body.stacked_after_habit_id:
        await _owned_habit(db, user, body.stacked_after_habit_id)
    habit = Habit(user_id=user.id, **body.model_dump(exclude={"start_date"}),
                  start_date=body.start_date or date.today())
    db.add(habit)
    await db.commit()
    return await _habit_out(db, habit)


@router.get("/habits/{habit_id}")
async def get_habit(habit_id: uuid.UUID, db: DB, user: CurrentUser) -> HabitOut:
    return await _habit_out(db, await _owned_habit(db, user, habit_id))


@router.put("/habits/{habit_id}")
async def update_habit(habit_id: uuid.UUID, body: HabitUpdate, db: DB,
                       user: CurrentUser) -> HabitOut:
    habit = await _owned_habit(db, user, habit_id)
    updates = body.model_dump(exclude_unset=True)
    if updates.get("stacked_after_habit_id"):
        if updates["stacked_after_habit_id"] == habit_id:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                                "A habit cannot be stacked after itself")
        await _owned_habit(db, user, updates["stacked_after_habit_id"])
    for k, v in updates.items():
        setattr(habit, k, v)
    await db.commit()
    return await _habit_out(db, habit)


@router.delete("/habits/{habit_id}", status_code=204)
async def delete_habit(habit_id: uuid.UUID, db: DB, user: CurrentUser) -> None:
    habit = await _owned_habit(db, user, habit_id)
    await db.delete(habit)
    await db.commit()


# ---------------- logging ----------------

@router.post("/habit-log", status_code=201)
async def log_habit(body: HabitLogCreate, db: DB, user: CurrentUser) -> HabitLogOut:
    habit = await _owned_habit(db, user, body.habit_id)
    if body.log_date > date.today():
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Cannot log the future")
    # Upsert per (habit, day) — idempotent offline sync.
    existing = await db.scalar(select(HabitLog).where(
        HabitLog.habit_id == habit.id, HabitLog.log_date == body.log_date))
    if existing:
        existing.status, existing.value, existing.note = body.status, body.value, body.note
        log = existing
    else:
        log = HabitLog(user_id=user.id, **body.model_dump())
        db.add(log)
    await db.commit()
    return HabitLogOut.model_validate(log)


@router.get("/habit-history")
async def habit_history(
    db: DB, user: CurrentUser,
    habit_id: uuid.UUID | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    limit: int = Query(default=200, le=1000),
) -> list[HabitLogOut]:
    q = select(HabitLog).where(HabitLog.user_id == user.id)
    if habit_id:
        q = q.where(HabitLog.habit_id == habit_id)
    if date_from:
        q = q.where(HabitLog.log_date >= date_from)
    if date_to:
        q = q.where(HabitLog.log_date <= date_to)
    rows = await db.scalars(q.order_by(HabitLog.log_date.desc()).limit(limit))
    return [HabitLogOut.model_validate(r) for r in rows]


@router.get("/habits/{habit_id}/stats")
async def habit_stats(habit_id: uuid.UUID, db: DB, user: CurrentUser) -> HabitStats:
    habit = await _owned_habit(db, user, habit_id)
    cur, best = await stats_svc.compute_streaks(db, habit)
    total = len((await db.scalars(select(HabitLog.id).where(
        HabitLog.habit_id == habit.id))).all())
    return HabitStats(
        habit_id=habit.id, current_streak=cur, best_streak=best,
        total_completions=total,
        completion_rate_30d=await stats_svc.completion_rate(db, habit, 30),
        completion_rate_all=await stats_svc.completion_rate(db, habit, None),
        heatmap=await stats_svc.heatmap(db, habit))


# ---------------- categories ----------------

@router.get("/categories")
async def list_categories(db: DB, user: CurrentUser) -> list[CategoryOut]:
    rows = await db.scalars(select(Category).where(
        (Category.user_id == user.id) | (Category.user_id.is_(None)))
        .order_by(Category.sort_order))
    return [CategoryOut.model_validate(c) for c in rows]


@router.post("/categories", status_code=201)
async def create_category(body: CategoryCreate, db: DB, user: CurrentUser) -> CategoryOut:
    cat = Category(user_id=user.id, **body.model_dump())
    db.add(cat)
    await db.commit()
    return CategoryOut.model_validate(cat)


@router.delete("/categories/{category_id}", status_code=204)
async def delete_category(category_id: uuid.UUID, db: DB, user: CurrentUser) -> None:
    cat = await db.get(Category, category_id)
    if cat is None or cat.user_id != user.id:  # built-ins (user_id None) can't be deleted
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
    await db.delete(cat)
    await db.commit()
