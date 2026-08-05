"""Pydantic request/response schemas."""
import uuid
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models.models import (
    CameraPurpose, CameraSessionStatus, HabitFrequency, HabitLogStatus, TimeOfDay, UserRole,
)


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# ---------------- auth ----------------

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=10, max_length=128)
    full_name: str = Field(min_length=1, max_length=120)
    timezone: str = "UTC"

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if v.lower() == v or v.upper() == v or not any(c.isdigit() for c in v):
            raise ValueError("Password must mix upper/lowercase letters and digits")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    device: "DeviceRegister | None" = None


class GoogleLoginRequest(BaseModel):
    id_token: str
    device: "DeviceRegister | None" = None


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshRequest(BaseModel):
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=10, max_length=128)


class UserOut(ORMModel):
    id: uuid.UUID
    email: EmailStr
    full_name: str
    role: UserRole
    is_email_verified: bool
    timezone: str
    created_at: datetime


class SessionOut(ORMModel):
    id: uuid.UUID
    device_id: uuid.UUID | None
    ip_address: str | None
    user_agent: str | None
    created_at: datetime
    expires_at: datetime
    revoked_at: datetime | None


# ---------------- devices ----------------

class DeviceRegister(BaseModel):
    name: str = Field(max_length=120)
    platform: str = Field(pattern="^(android|ios|web|windows|macos|linux)$")
    model: str | None = None
    fcm_token: str | None = None
    app_version: str | None = None


class DeviceOut(ORMModel):
    id: uuid.UUID
    name: str
    platform: str
    model: str | None
    location_sharing_enabled: bool
    location_history_enabled: bool
    last_seen_at: datetime | None
    is_active: bool
    created_at: datetime


# ---------------- habits ----------------

class HabitCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    description: str | None = None
    category_id: uuid.UUID | None = None
    icon: str = "check_circle"
    color: str = Field(default="#6750A4", pattern=r"^#[0-9A-Fa-f]{6,8}$")
    frequency: HabitFrequency = HabitFrequency.daily
    frequency_config: dict | None = None
    time_of_day: TimeOfDay = TimeOfDay.anytime
    goal_target: int = Field(default=1, ge=1, le=1000)
    goal_unit: str = Field(default="times", max_length=32)
    start_date: date | None = None
    stacked_after_habit_id: uuid.UUID | None = None


class HabitUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=120)
    description: str | None = None
    category_id: uuid.UUID | None = None
    icon: str | None = None
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6,8}$")
    frequency: HabitFrequency | None = None
    frequency_config: dict | None = None
    time_of_day: TimeOfDay | None = None
    goal_target: int | None = Field(default=None, ge=1, le=1000)
    goal_unit: str | None = None
    stacked_after_habit_id: uuid.UUID | None = None
    is_archived: bool | None = None
    sort_order: int | None = None


class HabitOut(ORMModel):
    id: uuid.UUID
    name: str
    description: str | None
    category_id: uuid.UUID | None
    icon: str
    color: str
    frequency: HabitFrequency
    frequency_config: dict | None
    time_of_day: TimeOfDay
    goal_target: int
    goal_unit: str
    start_date: date
    stacked_after_habit_id: uuid.UUID | None
    is_archived: bool
    sort_order: int
    created_at: datetime
    # computed
    current_streak: int = 0
    best_streak: int = 0
    completion_rate_30d: float = 0.0


class HabitLogCreate(BaseModel):
    habit_id: uuid.UUID
    log_date: date
    status: HabitLogStatus = HabitLogStatus.completed
    value: int = Field(default=1, ge=0, le=10000)
    note: str | None = Field(default=None, max_length=2000)


class HabitLogOut(ORMModel):
    id: uuid.UUID
    habit_id: uuid.UUID
    log_date: date
    status: HabitLogStatus
    value: int
    note: str | None


class CategoryCreate(BaseModel):
    name: str = Field(max_length=64)
    icon: str = "category"
    color: str = Field(default="#6750A4", pattern=r"^#[0-9A-Fa-f]{6,8}$")


class CategoryOut(ORMModel):
    id: uuid.UUID
    name: str
    icon: str
    color: str
    sort_order: int


class HabitStats(BaseModel):
    habit_id: uuid.UUID
    current_streak: int
    best_streak: int
    total_completions: int
    completion_rate_30d: float
    completion_rate_all: float
    heatmap: dict[str, int]  # "YYYY-MM-DD" -> value


# ---------------- photos ----------------

class PhotoOut(ORMModel):
    id: uuid.UUID
    habit_log_id: uuid.UUID | None
    content_type: str
    size_bytes: int
    created_at: datetime
    url: str | None = None  # presigned, filled by service


# ---------------- location ----------------

class LocationSharingToggle(BaseModel):
    device_id: uuid.UUID
    history_enabled: bool = False


class LocationPing(BaseModel):
    """Sent BY a device that has sharing enabled, in response to an owner request."""
    device_id: uuid.UUID
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    accuracy_m: int | None = Field(default=None, ge=0)


class DeviceLocationOut(BaseModel):
    device_id: uuid.UUID
    latitude: float
    longitude: float
    accuracy_m: int | None
    recorded_at: datetime


class GeofenceCreate(BaseModel):
    habit_id: uuid.UUID | None = None
    name: str = Field(max_length=120)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    radius_meters: int = Field(default=150, ge=50, le=5000)
    trigger_on: str = Field(default="enter", pattern="^(enter|exit)$")


class GeofenceOut(BaseModel):
    id: uuid.UUID
    habit_id: uuid.UUID | None
    name: str
    latitude: float
    longitude: float
    radius_meters: int
    trigger_on: str
    is_enabled: bool


# ---------------- camera ----------------

class CameraSessionRequest(BaseModel):
    target_device_id: uuid.UUID
    purpose: CameraPurpose


class CameraSessionResponse(BaseModel):
    session_id: uuid.UUID
    nonce: str          # echoed from the push payload; proves the device received the prompt
    approved: bool      # the human's decision on the full-screen prompt


class CameraSessionOut(ORMModel):
    id: uuid.UUID
    target_device_id: uuid.UUID
    purpose: CameraPurpose
    status: CameraSessionStatus
    expires_at: datetime
    created_at: datetime


# ---------------- notifications ----------------

class SendNotificationRequest(BaseModel):
    """Admin-only broadcast, or user self-notification test."""
    user_id: uuid.UUID | None = None   # admin may target any user; users may only target self
    title: str = Field(max_length=200)
    body: str = Field(max_length=2000)
    data: dict | None = None


class NotificationOut(ORMModel):
    id: uuid.UUID
    title: str
    body: str
    data: dict | None
    sent_at: datetime | None
    read_at: datetime | None
    created_at: datetime


LoginRequest.model_rebuild()
GoogleLoginRequest.model_rebuild()
