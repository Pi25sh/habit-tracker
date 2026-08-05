"""Transactional email (verification, password reset, reports) via SMTP."""
import logging
from email.message import EmailMessage

import aiosmtplib

from app.core.config import settings

log = logging.getLogger(__name__)


async def _send(to: str, subject: str, html: str) -> None:
    msg = EmailMessage()
    msg["From"] = settings.EMAIL_FROM
    msg["To"] = to
    msg["Subject"] = subject
    msg.set_content("This email requires an HTML-capable client.")
    msg.add_alternative(html, subtype="html")
    try:
        await aiosmtplib.send(
            msg, hostname=settings.SMTP_HOST, port=settings.SMTP_PORT,
            username=settings.SMTP_USER or None, password=settings.SMTP_PASSWORD or None,
            use_tls=settings.SMTP_TLS)
    except Exception:
        log.exception("email send failed to=%s subject=%s", to, subject)


async def send_verification_email(to: str, token: str) -> None:
    url = f"{settings.FRONTEND_URL}/verify-email?token={token}"
    await _send(to, "Verify your Habit Tracker email",
                f"<p>Welcome! Confirm your email:</p><p><a href='{url}'>Verify email</a></p>"
                f"<p>This link expires in {settings.EMAIL_VERIFY_TOKEN_EXPIRE_HOURS} hours.</p>")


async def send_password_reset_email(to: str, token: str) -> None:
    url = f"{settings.FRONTEND_URL}/reset-password?token={token}"
    await _send(to, "Reset your Habit Tracker password",
                f"<p>We received a password reset request.</p><p><a href='{url}'>Reset password</a></p>"
                f"<p>If this wasn't you, ignore this email — your password is unchanged.</p>")


async def send_weekly_summary(to: str, name: str, stats_html: str) -> None:
    await _send(to, "Your weekly habit summary",
                f"<h2>Hi {name}, here's your week</h2>{stats_html}")
