"""MinIO/S3 storage: validated uploads, presigned downloads."""
import hashlib
import uuid

import aioboto3
from fastapi import HTTPException, UploadFile, status

from app.core.config import settings

_session = aioboto3.Session()

# Magic-byte signatures — never trust the client's Content-Type header alone.
_SIGNATURES = {
    b"\xff\xd8\xff": "image/jpeg",
    b"\x89PNG\r\n\x1a\n": "image/png",
    b"RIFF": "image/webp",  # + WEBP at offset 8, checked below
}


def _client():
    return _session.client(
        "s3", endpoint_url=settings.S3_ENDPOINT,
        aws_access_key_id=settings.S3_ACCESS_KEY,
        aws_secret_access_key=settings.S3_SECRET_KEY,
        region_name=settings.S3_REGION)


def _sniff(head: bytes) -> str | None:
    for sig, mime in _SIGNATURES.items():
        if head.startswith(sig):
            if mime == "image/webp" and head[8:12] != b"WEBP":
                continue
            return mime
    if head[4:12] in (b"ftypheic", b"ftypheix", b"ftypmif1"):
        return "image/heic"
    return None


async def validate_and_store_image(file: UploadFile, user_id: uuid.UUID,
                                   prefix: str = "habit") -> tuple[str, str, int, str]:
    """Validate size + magic bytes, store under a random key.
    Returns (object_key, content_type, size, sha256)."""
    data = await file.read(settings.UPLOAD_MAX_BYTES + 1)
    if len(data) > settings.UPLOAD_MAX_BYTES:
        raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                            f"Max upload size is {settings.UPLOAD_MAX_BYTES // (1024*1024)} MB")
    mime = _sniff(data[:16])
    if mime is None or mime not in settings.ALLOWED_IMAGE_TYPES:
        raise HTTPException(status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                            "Only JPEG, PNG, WebP or HEIC images are accepted")
    digest = hashlib.sha256(data).hexdigest()
    ext = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp", "image/heic": "heic"}[mime]
    key = f"{prefix}/{user_id}/{uuid.uuid4().hex}.{ext}"
    async with _client() as s3:
        await s3.put_object(
            Bucket=settings.S3_BUCKET_PHOTOS, Key=key, Body=data,
            ContentType=mime, ServerSideEncryption="AES256",
            Metadata={"owner": str(user_id), "sha256": digest})
    return key, mime, len(data), digest


async def presigned_url(key: str, expires_s: int = 900) -> str:
    async with _client() as s3:
        url = await s3.generate_presigned_url(
            "get_object", Params={"Bucket": settings.S3_BUCKET_PHOTOS, "Key": key},
            ExpiresIn=expires_s)
    # rewrite internal endpoint for browser access
    return url.replace(settings.S3_ENDPOINT, settings.S3_PUBLIC_ENDPOINT)


async def delete_object(key: str) -> None:
    async with _client() as s3:
        await s3.delete_object(Bucket=settings.S3_BUCKET_PHOTOS, Key=key)


async def ensure_bucket() -> None:
    async with _client() as s3:
        try:
            await s3.head_bucket(Bucket=settings.S3_BUCKET_PHOTOS)
        except Exception:
            await s3.create_bucket(Bucket=settings.S3_BUCKET_PHOTOS)
