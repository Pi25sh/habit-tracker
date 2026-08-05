"""Application configuration loaded from environment variables.

All secrets come from the environment (.env in dev, injected secrets in prod).
Nothing sensitive is ever hardcoded.
"""
from functools import lru_cache
from pydantic import PostgresDsn, RedisDsn
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # --- App ---
    APP_NAME: str = "Habit Tracker"
    ENVIRONMENT: str = "development"  # development | staging | production
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"
    FRONTEND_URL: str = "http://localhost:3000"
    # Comma-separated in the environment; use `allowed_origins` for the parsed list.
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:8080"

    @property
    def allowed_origins(self) -> list[str]:
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",") if o.strip()]

    # --- Security ---
    SECRET_KEY: str  # openssl rand -hex 64
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    EMAIL_VERIFY_TOKEN_EXPIRE_HOURS: int = 24
    PASSWORD_RESET_TOKEN_EXPIRE_MINUTES: int = 30
    # Field-level encryption key for location data at rest (Fernet, base64 32B)
    LOCATION_ENCRYPTION_KEY: str

    # --- Database ---
    DATABASE_URL: PostgresDsn
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20

    # --- Redis ---
    REDIS_URL: RedisDsn = "redis://redis:6379/0"

    # --- MinIO / S3 ---
    S3_ENDPOINT: str = "http://minio:9000"
    S3_PUBLIC_ENDPOINT: str = "http://localhost:9000"
    S3_ACCESS_KEY: str
    S3_SECRET_KEY: str
    S3_BUCKET_PHOTOS: str = "habit-photos"
    S3_REGION: str = "us-east-1"
    UPLOAD_MAX_BYTES: int = 10 * 1024 * 1024  # 10 MB
    ALLOWED_IMAGE_TYPES: list[str] = ["image/jpeg", "image/png", "image/webp", "image/heic"]

    # --- Email ---
    SMTP_HOST: str = "mailhog"
    SMTP_PORT: int = 1025
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_TLS: bool = False
    EMAIL_FROM: str = "noreply@habittracker.app"

    # --- Google ---
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""

    # --- Firebase Cloud Messaging ---
    FCM_CREDENTIALS_FILE: str = "/run/secrets/fcm-service-account.json"

    # --- Rate limiting ---
    RATE_LIMIT_DEFAULT: str = "120/minute"
    RATE_LIMIT_AUTH: str = "10/minute"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
