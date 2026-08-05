"""WebSocket endpoint for real-time sync (habit log updates across devices,
camera session status, location request acknowledgements)."""
import asyncio
import json
import logging
import uuid
from collections import defaultdict

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.security import decode_token

log = logging.getLogger(__name__)
router = APIRouter()


class ConnectionManager:
    """user_id -> set of live sockets (one per device)."""

    def __init__(self) -> None:
        self._conns: dict[uuid.UUID, set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def connect(self, user_id: uuid.UUID, ws: WebSocket) -> None:
        await ws.accept()
        async with self._lock:
            self._conns[user_id].add(ws)

    async def disconnect(self, user_id: uuid.UUID, ws: WebSocket) -> None:
        async with self._lock:
            self._conns[user_id].discard(ws)
            if not self._conns[user_id]:
                del self._conns[user_id]

    async def broadcast_to_user(self, user_id: uuid.UUID, event: dict) -> None:
        payload = json.dumps(event)
        async with self._lock:
            sockets = list(self._conns.get(user_id, ()))
        for ws in sockets:
            try:
                await ws.send_text(payload)
            except Exception:
                await self.disconnect(user_id, ws)


manager = ConnectionManager()


@router.websocket("/ws")
async def websocket_endpoint(ws: WebSocket, token: str) -> None:
    """Authenticate with `?token=<access_token>`; events are pushed as JSON."""
    payload = decode_token(token, "access")
    if payload is None:
        await ws.close(code=4401, reason="Invalid token")
        return
    user_id = uuid.UUID(payload["sub"])
    await manager.connect(user_id, ws)
    try:
        while True:
            # Client messages: ping keep-alives and read-receipts.
            msg = await ws.receive_text()
            if msg == "ping":
                await ws.send_text('{"type":"pong"}')
    except WebSocketDisconnect:
        pass
    finally:
        await manager.disconnect(user_id, ws)
