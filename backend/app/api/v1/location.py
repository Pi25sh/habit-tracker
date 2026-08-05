"""Location features — strictly owner-scoped and consent-gated.

Design invariants enforced here (not just in the client):
  1. Sharing is opt-in per device and can be paused/disabled at any time.
  2. Only the authenticated OWNER of a device can request or read its location.
  3. The server never commands a device to report; it forwards a *request* and the
     device app decides — it only responds while sharing is enabled and shows a
     visible privacy indicator when it does.
  4. Coordinates are Fernet-encrypted at rest and decrypted only for the owner.
  5. Every location read is written to the audit log.
"""
import uuid
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import audit, get_current_user, get_redis
from app.core.security import decrypt_field, encrypt_field
from app.db.session import get_db
from app.models.models import Device, GeofenceLocation, LocationHistory, User
from app.schemas.schemas import (
    DeviceLocationOut, GeofenceCreate, GeofenceOut, LocationPing, LocationSharingToggle,
)
from app.services.fcm import send_data_push

router = APIRouter(tags=["location"])

DB = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]


async def _owned_device(db: AsyncSession, user: User, device_id: uuid.UUID) -> Device:
    device = await db.get(Device, device_id)
    if device is None or device.user_id != user.id or not device.is_active:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Device not found")
    return device


@router.post("/enable-location-sharing")
async def enable_location_sharing(body: LocationSharingToggle, request: Request,
                                  db: DB, user: CurrentUser) -> dict:
    """Called from the device itself after the user grants runtime permission
    and flips the in-app toggle ('Find My Device' mode)."""
    device = await _owned_device(db, user, body.device_id)
    device.location_sharing_enabled = True
    device.location_history_enabled = body.history_enabled
    await audit(db, user_id=user.id, action="location.sharing_enabled",
                resource=f"device:{device.id}",
                detail={"history": body.history_enabled},
                ip=request.client.host if request.client else None)
    await db.commit()
    return {"detail": "Location sharing enabled", "history_enabled": body.history_enabled}


@router.post("/disable-location-sharing")
async def disable_location_sharing(body: LocationSharingToggle, request: Request,
                                   db: DB, user: CurrentUser) -> dict:
    device = await _owned_device(db, user, body.device_id)
    device.location_sharing_enabled = False
    device.location_history_enabled = False
    await audit(db, user_id=user.id, action="location.sharing_disabled",
                resource=f"device:{device.id}",
                ip=request.client.host if request.client else None)
    await db.commit()
    return {"detail": "Location sharing disabled"}


@router.post("/location-ping")
async def location_ping(body: LocationPing, db: DB, user: CurrentUser) -> dict:
    """Device reports its own position (in response to an owner request, or
    periodically if the user enabled history). Rejected unless sharing is on."""
    device = await _owned_device(db, user, body.device_id)
    if not device.location_sharing_enabled:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Location sharing is disabled on this device")
    device.last_seen_at = datetime.now(timezone.utc)
    # Latest fix cached in Redis (encrypted), 10-minute TTL.
    redis = await get_redis()
    payload = encrypt_field(f"{body.latitude},{body.longitude},{body.accuracy_m or ''}")
    await redis.set(f"loc:{device.id}", payload, ex=600)
    if device.location_history_enabled:
        db.add(LocationHistory(
            device_id=device.id, user_id=user.id,
            latitude_enc=encrypt_field(str(body.latitude)),
            longitude_enc=encrypt_field(str(body.longitude)),
            accuracy_m=body.accuracy_m))
    await db.commit()
    return {"detail": "Location recorded"}


@router.get("/device-location")
async def device_location(device_id: uuid.UUID, request: Request,
                          db: DB, user: CurrentUser) -> DeviceLocationOut:
    """Owner reads the latest known location of their own device.

    If no recent fix is cached, we send a data push asking the device to report;
    the device only answers while sharing is enabled and shows its indicator."""
    device = await _owned_device(db, user, device_id)
    if not device.location_sharing_enabled:
        raise HTTPException(status.HTTP_403_FORBIDDEN,
                            "Location sharing is disabled on this device")
    await audit(db, user_id=user.id, action="location.read",
                resource=f"device:{device.id}",
                ip=request.client.host if request.client else None)
    await db.commit()

    redis = await get_redis()
    cached = await redis.get(f"loc:{device.id}")
    if cached is None:
        # Ask the device to report; client polls this endpoint again.
        if device.fcm_token:
            await send_data_push(device.fcm_token, {
                "type": "location_request", "device_id": str(device.id)})
        raise HTTPException(status.HTTP_202_ACCEPTED,
                            "Location requested from device; retry shortly")
    lat, lon, acc = decrypt_field(cached).split(",")
    return DeviceLocationOut(
        device_id=device.id, latitude=float(lat), longitude=float(lon),
        accuracy_m=int(acc) if acc else None,
        recorded_at=device.last_seen_at or datetime.now(timezone.utc))


@router.get("/location-history")
async def location_history(device_id: uuid.UUID, request: Request, db: DB,
                           user: CurrentUser, limit: int = 100) -> list[DeviceLocationOut]:
    device = await _owned_device(db, user, device_id)
    await audit(db, user_id=user.id, action="location.history_read",
                resource=f"device:{device.id}",
                ip=request.client.host if request.client else None)
    rows = await db.scalars(
        select(LocationHistory).where(LocationHistory.device_id == device.id)
        .order_by(LocationHistory.recorded_at.desc()).limit(min(limit, 500)))
    await db.commit()
    return [DeviceLocationOut(
        device_id=device.id,
        latitude=float(decrypt_field(r.latitude_enc)),
        longitude=float(decrypt_field(r.longitude_enc)),
        accuracy_m=r.accuracy_m, recorded_at=r.recorded_at) for r in rows]


@router.delete("/location-history")
async def clear_location_history(device_id: uuid.UUID, db: DB, user: CurrentUser) -> dict:
    device = await _owned_device(db, user, device_id)
    await db.execute(delete(LocationHistory).where(LocationHistory.device_id == device.id))
    await audit(db, user_id=user.id, action="location.history_cleared",
                resource=f"device:{device.id}")
    await db.commit()
    return {"detail": "Location history deleted"}


# ---------------- geofences (habit reminders by place) ----------------

@router.get("/geofences")
async def list_geofences(db: DB, user: CurrentUser) -> list[GeofenceOut]:
    rows = await db.scalars(select(GeofenceLocation).where(
        GeofenceLocation.user_id == user.id))
    return [GeofenceOut(
        id=g.id, habit_id=g.habit_id, name=g.name,
        latitude=float(decrypt_field(g.latitude_enc)),
        longitude=float(decrypt_field(g.longitude_enc)),
        radius_meters=g.radius_meters, trigger_on=g.trigger_on,
        is_enabled=g.is_enabled) for g in rows]


@router.post("/geofences", status_code=201)
async def create_geofence(body: GeofenceCreate, db: DB, user: CurrentUser) -> GeofenceOut:
    g = GeofenceLocation(
        user_id=user.id, habit_id=body.habit_id, name=body.name,
        latitude_enc=encrypt_field(str(body.latitude)),
        longitude_enc=encrypt_field(str(body.longitude)),
        radius_meters=body.radius_meters, trigger_on=body.trigger_on)
    db.add(g)
    await audit(db, user_id=user.id, action="geofence.created", resource=f"geofence:{g.id}")
    await db.commit()
    return GeofenceOut(id=g.id, habit_id=g.habit_id, name=g.name,
                       latitude=body.latitude, longitude=body.longitude,
                       radius_meters=g.radius_meters, trigger_on=g.trigger_on,
                       is_enabled=True)


@router.delete("/geofences/{geofence_id}", status_code=204)
async def delete_geofence(geofence_id: uuid.UUID, db: DB, user: CurrentUser) -> None:
    g = await db.get(GeofenceLocation, geofence_id)
    if g is None or g.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Geofence not found")
    await db.delete(g)
    await db.commit()
