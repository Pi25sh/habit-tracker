"""Shared pytest fixtures: in-memory SQLite DB, fake Redis, app client."""
import os
import uuid

os.environ.setdefault("SECRET_KEY", "test-secret-key-not-for-production-0000")
os.environ.setdefault("LOCATION_ENCRYPTION_KEY", "MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDA=")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///./test.db")
os.environ.setdefault("S3_ACCESS_KEY", "test")
os.environ.setdefault("S3_SECRET_KEY", "test")

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

import app.api.deps as deps
from app.db.session import get_db
from app.main import app
from app.models.models import Base


@pytest_asyncio.fixture
async def db_engine():
    engine = create_async_engine(
        "sqlite+aiosqlite://", poolclass=StaticPool,
        connect_args={"check_same_thread": False})
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def db(db_engine) -> AsyncSession:
    maker = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with maker() as session:
        yield session


@pytest_asyncio.fixture
async def client(db_engine):
    import fakeredis.aioredis
    maker = async_sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)

    async def _get_db():
        async with maker() as session:
            yield session

    fake = fakeredis.aioredis.FakeRedis(decode_responses=True)

    async def _get_redis():
        return fake

    app.dependency_overrides[get_db] = _get_db
    deps.get_redis = _get_redis
    # patch modules that imported get_redis directly
    import app.api.v1.location as loc_mod
    loc_mod.get_redis = _get_redis

    async with AsyncClient(transport=ASGITransport(app=app),
                           base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def auth_headers(client) -> dict:
    """Register + login a fresh user; return Authorization headers."""
    email = f"user-{uuid.uuid4().hex[:8]}@test.dev"
    await client.post("/api/v1/auth/register", json={
        "email": email, "password": "Sup3rSecretPwd", "full_name": "Test User"})
    resp = await client.post("/api/v1/auth/login", json={
        "email": email, "password": "Sup3rSecretPwd",
        "device": {"name": "Test Phone", "platform": "android"}})
    tokens = resp.json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}
