# Deployment Guide

## Local setup (development)

Prerequisites: Docker Desktop, Flutter SDK (for native builds), Git.

```bash
git clone <repo> habit-tracker && cd habit-tracker
cp .env.example .env
```

Generate secrets and paste into `.env`:

```bash
openssl rand -hex 64                                    # SECRET_KEY
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"  # LOCATION_ENCRYPTION_KEY
openssl rand -hex 24                                    # POSTGRES_PASSWORD / S3_SECRET_KEY
```

Start everything (MailHog captures dev email):

```bash
docker compose --profile dev up -d --build
docker compose run --rm migrate       # apply Alembic migrations
```

Verify: `curl http://localhost:8000/health` → `{"status":"ok"}`.
Swagger UI at `http://localhost:8000/docs`.

Flutter (native device/emulator):

```bash
cd frontend && flutter pub get
flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api/v1   # Android emulator
```

Firebase: add `google-services.json` (Android) / `GoogleService-Info.plist`
(iOS), and mount the FCM service-account JSON at
`/run/secrets/fcm-service-account.json` for the API container. Push features
degrade gracefully when absent.

## Production deployment

1. **Server**: any Docker host (2 vCPU / 4 GB min). Clone to `/opt/habit-tracker`.
2. **Secrets**: create `.env` with `ENVIRONMENT=production`, `DEBUG=false`,
   strong unique values for every `change-me`. Never commit it.
3. **TLS**: place `fullchain.pem` / `privkey.pem` in `nginx/certs/`
   (certbot or your CA). nginx redirects all HTTP → HTTPS and sets HSTS.
4. **Start**:
   ```bash
   docker compose up -d --build
   docker compose run --rm migrate
   ```
5. **CI/CD**: GitHub Actions (`.github/workflows/ci.yml`) lints, tests,
   verifies migrations up+down, builds images, and on `main` deploys over SSH
   using the `DEPLOY_HOST` / `DEPLOY_USER` / `DEPLOY_SSH_KEY` secrets
   (configure a `production` environment with required reviewers for gating).
6. **Monitoring**: `docker compose --profile monitoring up -d` starts
   Prometheus (`:9090`) and Grafana (`:3001`). The API `/health` and
   `/api/v1/admin/health-detail` endpoints expose liveness and dependency
   status; Docker healthchecks restart unhealthy containers.
7. **Backups**: cron the backup script and ship archives off-host:
   ```
   0 3 * * * cd /opt/habit-tracker && ./scripts/backup.sh >> /var/log/habit-backup.log 2>&1
   ```
   Restore with `./scripts/restore.sh backups/backup-<stamp>.tar.gz`
   (interactive confirmation required).

### Scaling notes

- API is stateless → `docker compose up -d --scale api=3` behind nginx.
- Run exactly the scheduler service once per cluster (Redis locks tolerate
  accidental duplicates, but one is cheapest).
- Move PostgreSQL/Redis to managed services by changing `DATABASE_URL` /
  `REDIS_URL`; MinIO swaps for S3 by changing the `S3_*` endpoints/keys.

## Developer guide

- **Backend style**: routers stay thin; domain logic in `app/services`;
  every table change gets an Alembic revision
  (`alembic revision --autogenerate -m "..."`). Run `ruff check` + `pytest`
  before pushing — CI enforces both.
- **Adding an endpoint**: schema in `schemas.py` → router function with
  `get_current_user` (or `require_admin`) → audit-log anything
  security-relevant → tests in `tests/test_api.py`.
- **Frontend style**: one folder per feature under `lib/features/`; state in
  Riverpod providers, navigation via GoRouter only; anything touching device
  hardware (camera/location) must request runtime permission and show the
  relevant visible indicator.
- **Privacy invariants** (do not weaken): location sharing default-off and
  server-enforced; camera opens only from the approval screen; every
  location read and camera transition audit-logged; coordinates never stored
  in plaintext.
