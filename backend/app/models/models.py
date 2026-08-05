"""SQLAlchemy ORM models — the normalized PostgreSQL schema.

Tables: users, devices, user_sessions, categories, habits, habit_logs, photos,
notifications, reminder_schedules, geofence_locations, location_history,
camera_sessions, user_settings, audit_logs, system_logs.
"""
import enum
import uuid
from datetime import datetime, date, timezone

from sqlalchemy import (
    Boolean, Date, DateTime, Enum, ForeignKey, Index, Integer, String, Text,
    UniqueConstraint, func,
)
from sqlalchemy import JSON, Uuid
from sqlalchemy.dialects.postgresql import JSONB

# JSONB on Postgres, plain JSON elsewhere (keeps unit tests runnable on SQLite).
JSONType = JSON().with_variant(JSONB(), "postgresql")
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class Base(DeclarativeBase):
    pass


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


# ---------------------------------------------------------------- enums

class UserRole(str, enum.Enum):
    user = "user"
    admin = "admin"


class AuthProvider(str, enum.Enum):
    email = "email"
    google = "google"


class HabitFrequency(str, enum.Enum):
    daily = "daily"
    weekly = "weekly"
    monthly = "monthly"
    custom = "custom"


class TimeOfDay(str, enum.Enum):
    morning = "morning"
    afternoon = "afternoon"
    evening = "evening"
    anytime = "anytime"


class HabitLogStatus(str, enum.Enum):
    completed = "completed"
    skipped = "skipped"
    missed = "missed"


class NotificationChannel(str, enum.Enum):
    push = "push"
    local = "local"
    email = "email"


class CameraSessionStatus(str, enum.Enum):
    pending = "pending"       # owner requested; awaiting device-side approval
    approved = "approved"     # user on the device explicitly approved
    denied = "denied"         # user on the device declined
    expired = "expired"       # no response within TTL
    completed = "completed"   # media uploaded, session closed


class CameraPurpose(str, enum.Enum):
    progress_photo = "progress_photo"
    qr_scan = "qr_scan"
    document_scan = "document_scan"
    habit_attachment = "habit_attachment"


# ---------------------------------------------------------------- identity

class User(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    password_hash: Mapped[str | None] = mapped_column(String(255))  # null for google-only accounts
    full_name: Mapped[str] = mapped_column(String(120))
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), default=UserRole.user)
    auth_provider: Mapped[AuthProvider] = mapped_column(Enum(AuthProvider), default=AuthProvider.email)
    google_sub: Mapped[str | None] = mapped_column(String(64), unique=True)
    is_email_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    avatar_key: Mapped[str | None] = mapped_column(String(255))
    timezone: Mapped[str] = mapped_column(String(64), default="UTC")

    devices: Mapped[list["Device"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    habits: Mapped[list["Habit"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    settings: Mapped["UserSettings"] = relationship(back_populates="user", uselist=False,
                                                   cascade="all, delete-orphan")


class Device(TimestampMixin, Base):
    """A registered physical device (phone / tablet / desktop) owned by one user."""
    __tablename__ = "devices"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(120))               # "Pixel 8", "Work laptop"
    platform: Mapped[str] = mapped_column(String(32))            # android | ios | web | windows | macos
    model: Mapped[str | None] = mapped_column(String(120))
    fcm_token: Mapped[str | None] = mapped_column(String(512))   # push messaging address
    app_version: Mapped[str | None] = mapped_column(String(32))
    # Location sharing is OFF by default and only ever enabled by explicit user action.
    location_sharing_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    location_history_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    user: Mapped["User"] = relationship(back_populates="devices")


class UserSession(TimestampMixin, Base):
    """One row per login; a refresh-token family. Revoking kills the session."""
    __tablename__ = "user_sessions"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    device_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("devices.id", ondelete="SET NULL"))
    refresh_token_hash: Mapped[str] = mapped_column(String(128), index=True)  # sha256 of current refresh token
    ip_address: Mapped[str | None] = mapped_column(String(45))
    user_agent: Mapped[str | None] = mapped_column(String(255))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


# ---------------------------------------------------------------- habits

class Category(TimestampMixin, Base):
    __tablename__ = "categories"
    __table_args__ = (UniqueConstraint("user_id", "name", name="uq_category_user_name"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID | None] = mapped_column(  # null => built-in global category
        ForeignKey("users.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(64))
    icon: Mapped[str] = mapped_column(String(64), default="category")
    color: Mapped[str] = mapped_column(String(9), default="#6750A4")
    sort_order: Mapped[int] = mapped_column(Integer, default=0)


class Habit(TimestampMixin, Base):
    __tablename__ = "habits"
    __table_args__ = (Index("ix_habits_user_archived", "user_id", "is_archived"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    category_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("categories.id", ondelete="SET NULL"))
    name: Mapped[str] = mapped_column(String(120))
    description: Mapped[str | None] = mapped_column(Text)
    icon: Mapped[str] = mapped_column(String(64), default="check_circle")
    color: Mapped[str] = mapped_column(String(9), default="#6750A4")
    frequency: Mapped[HabitFrequency] = mapped_column(Enum(HabitFrequency), default=HabitFrequency.daily)
    # custom frequency: {"days_of_week":[1,3,5]} or {"times_per_week":3} or {"interval_days":2}
    frequency_config: Mapped[dict | None] = mapped_column(JSONType)
    time_of_day: Mapped[TimeOfDay] = mapped_column(Enum(TimeOfDay), default=TimeOfDay.anytime)
    goal_target: Mapped[int] = mapped_column(Integer, default=1)     # e.g. 8 (glasses of water)
    goal_unit: Mapped[str] = mapped_column(String(32), default="times")
    start_date: Mapped[date] = mapped_column(Date, default=date.today)
    # Habit stacking: do this habit after another one ("After I brush teeth, I meditate")
    stacked_after_habit_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("habits.id", ondelete="SET NULL"))
    is_archived: Mapped[bool] = mapped_column(Boolean, default=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

    user: Mapped["User"] = relationship(back_populates="habits")
    logs: Mapped[list["HabitLog"]] = relationship(back_populates="habit", cascade="all, delete-orphan")
    reminders: Mapped[list["ReminderSchedule"]] = relationship(
        back_populates="habit", cascade="all, delete-orphan")
    milestones: Mapped[list["Milestone"]] = relationship(
        back_populates="habit", cascade="all, delete-orphan")


class HabitLog(TimestampMixin, Base):
    __tablename__ = "habit_logs"
    __table_args__ = (
        UniqueConstraint("habit_id", "log_date", name="uq_habitlog_habit_date"),
        Index("ix_habitlogs_habit_date", "habit_id", "log_date"),
    )

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    habit_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("habits.id", ondelete="CASCADE"), index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    log_date: Mapped[date] = mapped_column(Date)
    status: Mapped[HabitLogStatus] = mapped_column(Enum(HabitLogStatus))
    value: Mapped[int] = mapped_column(Integer, default=1)  # progress toward goal_target
    note: Mapped[str | None] = mapped_column(Text)

    habit: Mapped["Habit"] = relationship(back_populates="logs")
    photos: Mapped[list["Photo"]] = relationship(back_populates="habit_log")


class Milestone(TimestampMixin, Base):
    __tablename__ = "milestones"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    habit_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("habits.id", ondelete="CASCADE"), index=True)
    title: Mapped[str] = mapped_column(String(120))          # "30-day streak"
    target_streak: Mapped[int] = mapped_column(Integer)      # days
    achieved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    habit: Mapped["Habit"] = relationship(back_populates="milestones")


class Photo(TimestampMixin, Base):
    __tablename__ = "photos"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    habit_log_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("habit_logs.id", ondelete="SET NULL"))
    camera_session_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("camera_sessions.id", ondelete="SET NULL"))
    object_key: Mapped[str] = mapped_column(String(255), unique=True)   # MinIO key
    content_type: Mapped[str] = mapped_column(String(64))
    size_bytes: Mapped[int] = mapped_column(Integer)
    sha256: Mapped[str] = mapped_column(String(64))

    habit_log: Mapped["HabitLog"] = relationship(back_populates="photos")


# ---------------------------------------------------------------- reminders & notifications

class ReminderSchedule(TimestampMixin, Base):
    __tablename__ = "reminder_schedules"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    habit_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("habits.id", ondelete="CASCADE"), index=True)
    time_local: Mapped[str] = mapped_column(String(5))       # "07:30" in the user's timezone
    days_of_week: Mapped[list | None] = mapped_column(JSONType)  # [1..7], null = every scheduled day
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    repeat_after_minutes: Mapped[int | None] = mapped_column(Integer)  # nag again if not done
    smart: Mapped[bool] = mapped_column(Boolean, default=False)  # engine shifts time based on completion history

    habit: Mapped["Habit"] = relationship(back_populates="reminders")


class Notification(TimestampMixin, Base):
    __tablename__ = "notifications"
    __table_args__ = (Index("ix_notifications_user_read", "user_id", "read_at"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    channel: Mapped[NotificationChannel] = mapped_column(Enum(NotificationChannel))
    title: Mapped[str] = mapped_column(String(200))
    body: Mapped[str] = mapped_column(Text)
    data: Mapped[dict | None] = mapped_column(JSONType)  # deep-link payload
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


# ---------------------------------------------------------------- location (privacy-first)

class GeofenceLocation(TimestampMixin, Base):
    """User-defined places that trigger habit reminders (e.g. 'gym')."""
    __tablename__ = "geofence_locations"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    habit_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("habits.id", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(120))
    # Coordinates encrypted at rest (Fernet) — decrypted only for the owner.
    latitude_enc: Mapped[str] = mapped_column(Text)
    longitude_enc: Mapped[str] = mapped_column(Text)
    radius_meters: Mapped[int] = mapped_column(Integer, default=150)
    trigger_on: Mapped[str] = mapped_column(String(8), default="enter")  # enter | exit
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)


class LocationHistory(Base):
    """Optional, user-opt-in location history. Encrypted at rest; owner-only reads."""
    __tablename__ = "location_history"
    __table_args__ = (Index("ix_lochistory_device_time", "device_id", "recorded_at"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    device_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("devices.id", ondelete="CASCADE"), index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    latitude_enc: Mapped[str] = mapped_column(Text)
    longitude_enc: Mapped[str] = mapped_column(Text)
    accuracy_m: Mapped[int | None] = mapped_column(Integer)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


# ---------------------------------------------------------------- camera sessions (consent-gated)

class CameraSession(TimestampMixin, Base):
    """A remote camera request. The camera NEVER opens unless the person holding the
    target device explicitly approves via a full-screen prompt. Every state change
    is audit-logged."""
    __tablename__ = "camera_sessions"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    target_device_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("devices.id", ondelete="CASCADE"))
    requesting_device_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("devices.id", ondelete="SET NULL"))
    purpose: Mapped[CameraPurpose] = mapped_column(Enum(CameraPurpose))
    status: Mapped[CameraSessionStatus] = mapped_column(
        Enum(CameraSessionStatus), default=CameraSessionStatus.pending)
    # One-time nonce the device must echo back with its approval; prevents replay.
    nonce_hash: Mapped[str] = mapped_column(String(128))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    responded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


# ---------------------------------------------------------------- settings & logs

class UserSettings(TimestampMixin, Base):
    __tablename__ = "user_settings"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    theme: Mapped[str] = mapped_column(String(8), default="system")  # light | dark | system
    week_starts_on: Mapped[int] = mapped_column(Integer, default=1)  # 1 = Monday
    notifications_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    weekly_summary_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    monthly_report_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    google_fit_connected: Mapped[bool] = mapped_column(Boolean, default=False)
    google_calendar_connected: Mapped[bool] = mapped_column(Boolean, default=False)
    biometric_login_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    extra: Mapped[dict | None] = mapped_column(JSONType)

    user: Mapped["User"] = relationship(back_populates="settings")


class AuditLog(Base):
    """Security-relevant events: logins, permission changes, every location read,
    every camera session state transition. Append-only."""
    __tablename__ = "audit_logs"
    __table_args__ = (Index("ix_audit_user_time", "user_id", "created_at"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))
    actor_ip: Mapped[str | None] = mapped_column(String(45))
    action: Mapped[str] = mapped_column(String(64), index=True)   # e.g. "camera.session.approved"
    resource: Mapped[str | None] = mapped_column(String(120))     # e.g. "device:<uuid>"
    detail: Mapped[dict | None] = mapped_column(JSONType)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class SystemLog(Base):
    __tablename__ = "system_logs"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    level: Mapped[str] = mapped_column(String(16), index=True)
    source: Mapped[str] = mapped_column(String(64))
    message: Mapped[str] = mapped_column(Text)
    context: Mapped[dict | None] = mapped_column(JSONType)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True),
                                                 server_default=func.now(), index=True)
