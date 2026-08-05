"""Firebase Cloud Messaging push delivery."""
import logging
import os

import firebase_admin
from firebase_admin import credentials, messaging

from app.core.config import settings

log = logging.getLogger(__name__)
_app: firebase_admin.App | None = None


def _init() -> firebase_admin.App | None:
    global _app
    if _app is None:
        if not os.path.exists(settings.FCM_CREDENTIALS_FILE):
            log.warning("FCM credentials missing; push disabled")
            return None
        _app = firebase_admin.initialize_app(
            credentials.Certificate(settings.FCM_CREDENTIALS_FILE))
    return _app


async def send_push(fcm_token: str, title: str, body: str,
                    data: dict[str, str] | None = None) -> bool:
    """Fire one push message. `data` carries deep-link / action payloads —
    e.g. camera session prompts ({"type": "camera_request", ...})."""
    if _init() is None:
        return False
    msg = messaging.Message(
        token=fcm_token,
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in (data or {}).items()},
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(payload=messaging.APNSPayload(
            aps=messaging.Aps(content_available=True))))
    try:
        messaging.send(msg)
        return True
    except Exception:
        log.exception("FCM send failed")
        return False


async def send_data_push(fcm_token: str, data: dict[str, str]) -> bool:
    """Data-only message (no visible notification) used to wake the app for
    owner-initiated location requests. The app itself decides whether to respond,
    and only does so when the user has location sharing enabled."""
    if _init() is None:
        return False
    try:
        messaging.send(messaging.Message(
            token=fcm_token, data={k: str(v) for k, v in data.items()},
            android=messaging.AndroidConfig(priority="high")))
        return True
    except Exception:
        log.exception("FCM data push failed")
        return False
