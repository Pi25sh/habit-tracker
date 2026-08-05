"""Password hashing (Argon2id), JWT issuance/validation, and misc token helpers."""
import secrets
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Literal

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError, InvalidHashError
from cryptography.fernet import Fernet
from jose import jwt, JWTError

from app.core.config import settings

# Argon2id with OWASP-recommended parameters.
_ph = PasswordHasher(time_cost=3, memory_cost=65536, parallelism=4)

TokenType = Literal["access", "refresh", "email_verify", "password_reset"]


def hash_password(password: str) -> str:
    return _ph.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    try:
        return _ph.verify(hashed, password)
    except (VerifyMismatchError, InvalidHashError):
        return False


def needs_rehash(hashed: str) -> bool:
    return _ph.check_needs_rehash(hashed)


def _create_token(sub: str, token_type: TokenType, expires_delta: timedelta,
                  extra: dict[str, Any] | None = None) -> str:
    now = datetime.now(timezone.utc)
    payload: dict[str, Any] = {
        "sub": sub,
        "type": token_type,
        "iat": now,
        "exp": now + expires_delta,
        "jti": uuid.uuid4().hex,
    }
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_access_token(user_id: str, session_id: str, role: str) -> str:
    return _create_token(
        user_id, "access",
        timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        {"sid": session_id, "role": role},
    )


def create_refresh_token(user_id: str, session_id: str) -> str:
    return _create_token(
        user_id, "refresh",
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        {"sid": session_id},
    )


def create_email_token(user_id: str) -> str:
    return _create_token(user_id, "email_verify",
                         timedelta(hours=settings.EMAIL_VERIFY_TOKEN_EXPIRE_HOURS))


def create_password_reset_token(user_id: str) -> str:
    return _create_token(user_id, "password_reset",
                         timedelta(minutes=settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES))


def decode_token(token: str, expected_type: TokenType) -> dict[str, Any] | None:
    """Return the payload if the token is valid and of the expected type, else None."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    except JWTError:
        return None
    if payload.get("type") != expected_type:
        return None
    return payload


def generate_opaque_token(nbytes: int = 32) -> str:
    """URL-safe random token for device pairing / camera session nonces."""
    return secrets.token_urlsafe(nbytes)


# --- Field-level encryption for location data at rest ---
_fernet = Fernet(settings.LOCATION_ENCRYPTION_KEY.encode())


def encrypt_field(plaintext: str) -> str:
    return _fernet.encrypt(plaintext.encode()).decode()


def decrypt_field(ciphertext: str) -> str:
    return _fernet.decrypt(ciphertext.encode()).decode()
