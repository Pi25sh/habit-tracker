# API Reference

Base URL: `/api/v1`. All endpoints return JSON. Authenticated endpoints require
`Authorization: Bearer <access_token>`.

## Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/register` | – | Create account; sends verification email |
| POST | `/auth/verify-email?token=` | – | Confirm email address |
| POST | `/auth/login` | – | Email+password login; optional device registration; returns token pair |
| POST | `/auth/google` | – | Google ID-token login (creates/links account) |
| POST | `/auth/refresh` | – | Rotate refresh token → new pair. Reusing an old token revokes the session |
| POST | `/auth/logout` | ✓ | Revoke current session |
| POST | `/auth/forgot-password` | – | Email a reset link (response never reveals account existence) |
| POST | `/auth/reset-password` | – | Set new password; revokes all sessions |
| GET | `/auth/me` | ✓ | Current user profile |
| GET | `/auth/sessions` | ✓ | List active sessions (multi-device) |
| DELETE | `/auth/sessions/{id}` | ✓ | Revoke one session |
| GET/POST | `/auth/devices` | ✓ | List / register devices |
| DELETE | `/auth/devices/{id}` | ✓ | Deactivate a device (also disables its location sharing) |

### Token pair

```json
{"access_token": "...", "refresh_token": "...", "token_type": "bearer", "expires_in": 900}
```

## Habits

| Method | Path | Description |
|---|---|---|
| GET | `/habits` | List (computed streaks + 30-day rate included) |
| POST | `/habits` | Create — name, frequency (`daily/weekly/monthly/custom` + `frequency_config`), category, icon, color, goal, routine (`time_of_day`), `stacked_after_habit_id` |
| GET | `/habits/{id}` | Detail |
| PUT | `/habits/{id}` | Update / archive |
| DELETE | `/habits/{id}` | Delete with logs |
| GET | `/habits/{id}/stats` | Streaks, completion rates, 365-day heatmap |
| POST | `/habit-log` | Upsert a day's log (`completed/skipped/missed`, value, note). Future dates rejected |
| GET | `/habit-history` | Filterable log history (`habit_id`, `date_from`, `date_to`) |
| GET/POST | `/categories` · DELETE `/categories/{id}` | Category management (built-ins are read-only) |
| GET/POST | `/reminders` · DELETE `/reminders/{id}` | Reminder schedules (time, weekday mask, repeat-nag, smart flag) |

## Photos

| Method | Path | Description |
|---|---|---|
| POST | `/upload-photo` | multipart upload; magic-byte validated (JPEG/PNG/WebP/HEIC), ≤10 MB, stored SSE-encrypted |
| GET | `/photos` | List with 15-min presigned URLs |
| DELETE | `/photos/{id}` | Remove object + record |

## Location (owner-only, consent-gated)

| Method | Path | Description |
|---|---|---|
| POST | `/enable-location-sharing` | Device opts in (after OS runtime permission). Optional history |
| POST | `/disable-location-sharing` | Pause/disable at any time |
| POST | `/location-ping` | Device reports its position — **403 unless sharing is enabled** |
| GET | `/device-location?device_id=` | Owner reads last fix. 202 = request pushed to device, retry. **Every read is audit-logged** |
| GET/DELETE | `/location-history?device_id=` | Opt-in history (30-day retention) / clear it |
| GET/POST | `/geofences` · DELETE `/geofences/{id}` | Geofenced habit reminders (coordinates encrypted at rest) |

## Camera (approval required on the target device)

Flow: request → push with one-time nonce → **full-screen prompt on device** →
approve/deny → (if approved) capture → upload closes session.

| Method | Path | Description |
|---|---|---|
| POST | `/request-camera-session` | Owner requests a session for their own device (`purpose`: progress_photo / qr_scan / document_scan / habit_attachment). 409 if device unreachable |
| POST | `/camera-session-response` | Target device submits the human's decision + nonce proof. Expired sessions → 410 |
| POST | `/upload-camera-photo` | Accepted **only** for `approved` sessions; single-use |
| GET | `/camera-sessions` | Session history with statuses |

## Notifications

| Method | Path | Description |
|---|---|---|
| POST | `/send-notification` | Self-notify (any user) or target any user (admin only) |
| GET | `/notifications` | Inbox (`unread_only` filter) |
| POST | `/notifications/{id}/read` | Mark read |

## WebSocket

`GET /api/v1/ws?token=<access_token>` — JSON events: habit-log sync across
devices, camera session status changes. Send `ping` for keep-alive.

## Admin (role = admin)

`/admin/users` (+activate/deactivate), `/admin/devices`, `/admin/habits`,
`/admin/analytics`, `/admin/audit-logs`, `/admin/system-logs`, `/admin/health-detail`.

## Errors

Errors use `{"detail": "..."}` with conventional status codes:
401 (unauthenticated/expired), 403 (forbidden — includes disabled location sharing),
404 (not found — also returned for other users' resources, no existence leaks),
409 (conflict), 410 (expired session), 413/415 (upload validation),
422 (validation), 429 (rate limit).
