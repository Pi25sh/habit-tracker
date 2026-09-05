"""Sync endpoint for frontend offline-first data synchronization."""
import json
import uuid
from datetime import datetime, timezone
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from redis.asyncio import Redis

from app.api.deps import get_current_user, get_redis
from app.db.session import get_db
from app.models.models import User
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(tags=["sync"])

DB = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]
RedisClient = Annotated[Redis, Depends(get_redis)]


class SyncRequest(BaseModel):
    value: str  # JSON string of the data
    updated_at: int  # Timestamp in milliseconds


class SyncResponse(BaseModel):
    value: str  # JSON string of the data
    updated_at: int  # Timestamp in milliseconds


def _get_store_key(user_id: uuid.UUID, key: str) -> str:
    return f"sync:{user_id}:{key}"


@router.get("/sync/{key}")
async def get_sync_data(key: str, user: CurrentUser, redis: RedisClient) -> SyncResponse | None:
    """
    Get synced data for a specific key.
    Returns the data if it exists and is newer than what the client has.
    """
    store_key = _get_store_key(user.id, key)
    data = await redis.get(store_key)

    if data is None:
        # Return 404 or empty response - the client will push its data
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No sync data found")

    parsed = json.loads(data)
    return SyncResponse(
        value=parsed["value"],
        updated_at=parsed["updated_at"]
    )


@router.post("/sync/{key}")
async def set_sync_data(key: str, request: SyncRequest, user: CurrentUser, redis: RedisClient) -> dict:
    """
    Store synced data for a specific key.
    Uses last-write-wins based on updated_at timestamp.
    """
    store_key = _get_store_key(user.id, key)
    existing = await redis.get(store_key)

    # If existing data is newer, don't overwrite
    if existing:
        existing_parsed = json.loads(existing)
        if existing_parsed["updated_at"] > request.updated_at:
            return {"status": "conflict", "message": "Server has newer data"}

    # Store the new data
    await redis.set(store_key, json.dumps({
        "value": request.value,
        "updated_at": request.updated_at
    }))

    return {"status": "ok"}


@router.delete("/sync/{key}")
async def clear_sync_data(key: str, user: CurrentUser, redis: RedisClient) -> dict:
    """Clear synced data for a specific key."""
    store_key = _get_store_key(user.id, key)
    await redis.delete(store_key)
    return {"status": "ok"}


@router.get("/sync")
async def list_sync_keys(user: CurrentUser, redis: RedisClient) -> dict:
    """List all sync keys for the current user."""
    prefix = f"sync:{user.id}:"
    keys = []
    cursor = 0
    while True:
        cursor, found = await redis.scan(cursor, match=f"{prefix}*", count=100)
        for key in found:
            keys.append(key[len(prefix):])
        if cursor == 0:
            break
    return {"keys": keys}