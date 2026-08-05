# Habit Tracker

Enterprise-grade habit tracker and personal device management platform, inspired by Habitify.
Flutter (Android / iOS / Web / Windows / macOS) + FastAPI + PostgreSQL + Redis + MinIO, fully Dockerized.

## Feature highlights

- **Habits**: daily/weekly/monthly/custom frequencies, categories, goals & milestones,
  streaks, heat maps, progress charts, calendar view, notes, photo attachments,
  habit stacking, morning/afternoon/evening routines.
- **Auth**: email + verification, Google Sign-In, Argon2id hashing, short-lived JWT
  access tokens with rotating refresh tokens (reuse detection), biometric unlock,
  multi-device sessions with per-session revocation.
- **Notifications**: FCM push, local notifications, smart reminders, repeat & missed-habit
  nags, weekly summary and monthly report emails.
- **Find My Device (privacy-first)**: per-device opt-in location sharing, owner-only
  location reads, optional history with 30-day retention, geofenced habit reminders,
  Fernet-encrypted coordinates at rest, a persistent in-app banner whenever sharing
  is active, and an audit-log entry for every read.
- **Camera (consent-gated)**: remote camera requests require a full-screen approval
  on the target device, proven by a one-time nonce; sessions expire in 2 minutes;
  a visible "CAMERA ACTIVE" indicator is always shown; every transition is audit-logged.
  There is no code path that opens a camera silently or in the background.
- **Admin dashboard API**: user/device/habit management, aggregated analytics,
  audit & system logs, health monitoring — all RBAC-protected.

## Repository layout

```
habit-tracker/
├── backend/               # FastAPI application
│   ├── app/
│   │   ├── api/v1/        # auth, habits, photos, location, camera, notifications, admin, ws
│   │   ├── core/          # config (env), security (Argon2/JWT/Fernet)
│   │   ├── db/            # async engine/session
│   │   ├── models/        # SQLAlchemy ORM (15 tables)
│   │   ├── schemas/       # Pydantic request/response models
│   │   ├── services/      # stats, storage (MinIO), email, FCM
│   │   └── tasks/         # background scheduler (reminders, reports, retention)
│   ├── alembic/           # migrations
│   └── tests/             # unit + integration + API tests (pytest)
├── frontend/              # Flutter app (Riverpod + GoRouter + Material 3)
│   ├── lib/
│   │   ├── app/           # theme, router, responsive shell
│   │   ├── core/          # Dio client w/ token refresh, SQLite offline cache
│   │   └── features/      # auth, habits, stats, location, camera, notifications, settings
│   └── test/              # widget tests
├── nginx/                 # TLS-terminating reverse proxy + rate limiting
├── monitoring/            # Prometheus config (Grafana via compose profile)
├── scripts/               # backup.sh / restore.sh
├── docs/                  # API docs, ER & architecture diagrams, guides
├── .github/workflows/     # CI: lint, tests, migration check, build, deploy
└── docker-compose.yml
```

## Quick start (development)

```bash
cp .env.example .env
# generate secrets:
#   SECRET_KEY:              openssl rand -hex 64
#   LOCATION_ENCRYPTION_KEY: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
docker compose --profile dev up -d --build
docker compose run --rm migrate
```

- API: http://localhost:8000/docs (Swagger; disabled in production)
- Flutter web: served through nginx at http://localhost
- MinIO console: http://localhost:9001 · MailHog: http://localhost:8025

Run the Flutter app natively:

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE=http://localhost:8000/api/v1
```

Run backend tests:

```bash
cd backend
python -m venv .venv && . .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt -r requirements-dev.txt
pytest
```

## Security model (summary)

| Layer | Control |
|---|---|
| Passwords | Argon2id (t=3, m=64 MiB, p=4) |
| Tokens | 15-min JWT access + 30-day rotating refresh; reuse revokes the session |
| Transport | TLS 1.2/1.3 at nginx, HSTS in production |
| Location data | Fernet-encrypted at rest, owner-only, opt-in, audited |
| Camera | Full-screen device-side approval + nonce proof, 2-min TTL, audited |
| Uploads | Magic-byte sniffing, 10 MB cap, SSE-AES256 in MinIO |
| Rate limits | nginx edge zones + Redis per-user/IP buckets (stricter on auth) |
| RBAC | `user` / `admin` roles enforced by dependency injection |
| Injection/XSS | SQLAlchemy bound params, strict CSP + nosniff/deny headers |
| Auditing | Append-only `audit_logs` for every sensitive action |

More docs in [`docs/`](docs/): API reference, ER diagram, architecture,
local setup, production deployment, developer guide.
