"""API + integration tests: auth flow, habit CRUD, RBAC, and the consent
invariants of the location & camera modules."""
import uuid

import pytest


@pytest.mark.asyncio
async def test_register_login_refresh_logout(client):
    email = "flow@test.dev"
    r = await client.post("/api/v1/auth/register", json={
        "email": email, "password": "Sup3rSecretPwd", "full_name": "Flow"})
    assert r.status_code == 201

    # duplicate registration rejected
    r = await client.post("/api/v1/auth/register", json={
        "email": email, "password": "Sup3rSecretPwd", "full_name": "Flow"})
    assert r.status_code == 409

    r = await client.post("/api/v1/auth/login", json={
        "email": email, "password": "Sup3rSecretPwd"})
    assert r.status_code == 200
    tokens = r.json()

    # wrong password
    r = await client.post("/api/v1/auth/login", json={
        "email": email, "password": "nope-nope-1A"})
    assert r.status_code == 401

    # refresh rotates the token
    r = await client.post("/api/v1/auth/refresh",
                          json={"refresh_token": tokens["refresh_token"]})
    assert r.status_code == 200
    rotated = r.json()

    # reusing the OLD refresh token revokes the session
    r = await client.post("/api/v1/auth/refresh",
                          json={"refresh_token": tokens["refresh_token"]})
    assert r.status_code == 401
    r = await client.post("/api/v1/auth/refresh",
                          json={"refresh_token": rotated["refresh_token"]})
    assert r.status_code == 401  # whole session dead after reuse detection


@pytest.mark.asyncio
async def test_weak_password_rejected(client):
    r = await client.post("/api/v1/auth/register", json={
        "email": "weak@test.dev", "password": "alllowercase", "full_name": "W"})
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_habit_crud_and_logging(client, auth_headers):
    r = await client.post("/api/v1/habits", headers=auth_headers, json={
        "name": "Meditate", "frequency": "daily", "goal_target": 1})
    assert r.status_code == 201
    habit = r.json()

    r = await client.get("/api/v1/habits", headers=auth_headers)
    assert len(r.json()) == 1

    r = await client.put(f"/api/v1/habits/{habit['id']}", headers=auth_headers,
                         json={"name": "Meditate 10m"})
    assert r.json()["name"] == "Meditate 10m"

    from datetime import date
    r = await client.post("/api/v1/habit-log", headers=auth_headers, json={
        "habit_id": habit["id"], "log_date": date.today().isoformat(),
        "status": "completed"})
    assert r.status_code == 201

    # same-day log upserts, not duplicates
    r = await client.post("/api/v1/habit-log", headers=auth_headers, json={
        "habit_id": habit["id"], "log_date": date.today().isoformat(),
        "status": "completed", "value": 2})
    assert r.status_code == 201
    r = await client.get("/api/v1/habit-history", headers=auth_headers,
                         params={"habit_id": habit["id"]})
    assert len(r.json()) == 1
    assert r.json()[0]["value"] == 2

    # future logging rejected
    from datetime import timedelta
    r = await client.post("/api/v1/habit-log", headers=auth_headers, json={
        "habit_id": habit["id"],
        "log_date": (date.today() + timedelta(days=1)).isoformat()})
    assert r.status_code == 422

    r = await client.get(f"/api/v1/habits/{habit['id']}/stats", headers=auth_headers)
    assert r.json()["current_streak"] == 1

    r = await client.delete(f"/api/v1/habits/{habit['id']}", headers=auth_headers)
    assert r.status_code == 204


@pytest.mark.asyncio
async def test_cross_user_isolation(client, auth_headers):
    r = await client.post("/api/v1/habits", headers=auth_headers,
                          json={"name": "Private"})
    habit_id = r.json()["id"]

    # second user cannot see or touch it
    other = await client.post("/api/v1/auth/register", json={
        "email": "other@test.dev", "password": "Sup3rSecretPwd", "full_name": "O"})
    login = await client.post("/api/v1/auth/login", json={
        "email": "other@test.dev", "password": "Sup3rSecretPwd"})
    h2 = {"Authorization": f"Bearer {login.json()['access_token']}"}
    assert (await client.get(f"/api/v1/habits/{habit_id}", headers=h2)).status_code == 404
    assert (await client.delete(f"/api/v1/habits/{habit_id}", headers=h2)).status_code == 404


@pytest.mark.asyncio
async def test_admin_requires_role(client, auth_headers):
    r = await client.get("/api/v1/admin/users", headers=auth_headers)
    assert r.status_code == 403
    r = await client.get("/api/v1/admin/users")
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_location_disabled_by_default_and_gated(client, auth_headers):
    devices = (await client.get("/api/v1/auth/devices", headers=auth_headers)).json()
    device_id = devices[0]["id"]
    assert devices[0]["location_sharing_enabled"] is False  # OFF by default

    # Reading location while sharing is disabled -> 403, even for the owner.
    r = await client.get("/api/v1/device-location", headers=auth_headers,
                         params={"device_id": device_id})
    assert r.status_code == 403

    # Device pings are also rejected while disabled.
    r = await client.post("/api/v1/location-ping", headers=auth_headers, json={
        "device_id": device_id, "latitude": 12.9, "longitude": 77.5})
    assert r.status_code == 403

    # Enable, ping, read.
    r = await client.post("/api/v1/enable-location-sharing", headers=auth_headers,
                          json={"device_id": device_id, "history_enabled": False})
    assert r.status_code == 200
    r = await client.post("/api/v1/location-ping", headers=auth_headers, json={
        "device_id": device_id, "latitude": 12.9716, "longitude": 77.5946,
        "accuracy_m": 10})
    assert r.status_code == 200
    r = await client.get("/api/v1/device-location", headers=auth_headers,
                         params={"device_id": device_id})
    assert r.status_code == 200
    assert abs(r.json()["latitude"] - 12.9716) < 1e-6

    # Disable again -> reads blocked immediately.
    await client.post("/api/v1/disable-location-sharing", headers=auth_headers,
                      json={"device_id": device_id})
    r = await client.get("/api/v1/device-location", headers=auth_headers,
                         params={"device_id": device_id})
    assert r.status_code == 403


@pytest.mark.asyncio
async def test_camera_session_requires_device_approval(client, auth_headers):
    devices = (await client.get("/api/v1/auth/devices", headers=auth_headers)).json()
    device_id = devices[0]["id"]

    # No FCM token registered -> cannot even create a remote session.
    r = await client.post("/api/v1/request-camera-session", headers=auth_headers,
                          json={"target_device_id": device_id,
                                "purpose": "progress_photo"})
    assert r.status_code == 409

    # A wrong nonce can never approve a session (tested via response endpoint
    # against a nonexistent session).
    r = await client.post("/api/v1/camera-session-response", headers=auth_headers,
                          json={"session_id": str(uuid.uuid4()),
                                "nonce": "forged", "approved": True})
    assert r.status_code == 404

    # Targeting someone else's device is a 404 (no information leak).
    r = await client.post("/api/v1/request-camera-session", headers=auth_headers,
                          json={"target_device_id": str(uuid.uuid4()),
                                "purpose": "qr_scan"})
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_health(client):
    r = await client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"
