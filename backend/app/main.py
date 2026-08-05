"""FastAPI application entrypoint."""
import logging
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.deps import rate_limit
from app.api.v1 import admin, auth, camera, habits, location, notifications, photos, ws
from app.core.config import settings

logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("app")


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        from app.services.storage import ensure_bucket
        await ensure_bucket()
    except Exception:
        log.warning("MinIO not reachable at startup; will retry on first upload")
    yield


app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    docs_url="/docs" if settings.ENVIRONMENT != "production" else None,
    redoc_url=None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)


@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"
    if settings.ENVIRONMENT == "production":
        response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains"
    return response


@app.exception_handler(Exception)
async def unhandled(request: Request, exc: Exception):
    log.exception("unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


@app.get("/health", tags=["ops"])
async def health() -> dict:
    """Liveness probe for Docker/Nginx/monitoring."""
    return {"status": "ok", "app": settings.APP_NAME, "env": settings.ENVIRONMENT}


prefix = settings.API_V1_PREFIX
app.include_router(auth.router, prefix=prefix)
app.include_router(habits.router, prefix=prefix, dependencies=[Depends(rate_limit)])
app.include_router(photos.router, prefix=prefix, dependencies=[Depends(rate_limit)])
app.include_router(location.router, prefix=prefix, dependencies=[Depends(rate_limit)])
app.include_router(camera.router, prefix=prefix, dependencies=[Depends(rate_limit)])
app.include_router(notifications.router, prefix=prefix, dependencies=[Depends(rate_limit)])
app.include_router(admin.router, prefix=prefix)
app.include_router(ws.router, prefix=prefix)
