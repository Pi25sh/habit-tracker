"""Photo upload/list with validation and presigned access."""
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import audit, get_current_user, rate_limit
from app.db.session import get_db
from app.models.models import HabitLog, Photo, User
from app.schemas.schemas import PhotoOut
from app.services.storage import delete_object, presigned_url, validate_and_store_image

router = APIRouter(tags=["photos"])

DB = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]


@router.post("/upload-photo", status_code=201)
async def upload_photo(
    db: DB, user: CurrentUser,
    file: UploadFile = File(...),
    habit_log_id: uuid.UUID | None = Form(default=None),
) -> PhotoOut:
    if habit_log_id:
        log = await db.get(HabitLog, habit_log_id)
        if log is None or log.user_id != user.id:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Habit log not found")
    key, mime, size, digest = await validate_and_store_image(file, user.id)
    photo = Photo(user_id=user.id, habit_log_id=habit_log_id, object_key=key,
                  content_type=mime, size_bytes=size, sha256=digest)
    db.add(photo)
    await audit(db, user_id=user.id, action="photo.uploaded", resource=f"photo:{photo.id}")
    await db.commit()
    out = PhotoOut.model_validate(photo)
    out.url = await presigned_url(key)
    return out


@router.get("/photos")
async def list_photos(db: DB, user: CurrentUser,
                      habit_log_id: uuid.UUID | None = None) -> list[PhotoOut]:
    q = select(Photo).where(Photo.user_id == user.id).order_by(Photo.created_at.desc()).limit(200)
    if habit_log_id:
        q = q.where(Photo.habit_log_id == habit_log_id)
    photos = (await db.scalars(q)).all()
    out = []
    for p in photos:
        item = PhotoOut.model_validate(p)
        item.url = await presigned_url(p.object_key)
        out.append(item)
    return out


@router.delete("/photos/{photo_id}", status_code=204)
async def delete_photo(photo_id: uuid.UUID, db: DB, user: CurrentUser) -> None:
    photo = await db.get(Photo, photo_id)
    if photo is None or photo.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Photo not found")
    await delete_object(photo.object_key)
    await db.delete(photo)
    await audit(db, user_id=user.id, action="photo.deleted", resource=f"photo:{photo_id}")
    await db.commit()
