# Architecture

## System diagram

```mermaid
flowchart LR
    subgraph Clients
        A[Flutter Android/iOS]
        W[Flutter Web]
        D[Flutter Desktop]
    end

    subgraph Edge
        N[Nginx<br/>TLS · rate limits · HSTS]
    end

    subgraph Backend
        API[FastAPI<br/>REST + WebSocket]
        SCH[Scheduler<br/>reminders · reports · retention]
    end

    subgraph Data
        PG[(PostgreSQL 16)]
        RD[(Redis 7<br/>rate limits · loc cache · locks)]
        MC[(MinIO<br/>SSE-AES256 photos)]
    end

    FCM[Firebase Cloud Messaging]
    SMTP[SMTP]

    A & W & D -->|HTTPS/WSS| N --> API
    API --> PG & RD & MC
    SCH --> PG & RD
    API & SCH --> FCM --> A
    API & SCH --> SMTP
```

## Consent flows

### Find My Device
```mermaid
sequenceDiagram
    participant Owner as Owner (device A)
    participant S as Server
    participant Dev as Device B (target)
    Note over Dev: User enabled sharing +<br/>OS permission granted.<br/>Banner visible while ON.
    Owner->>S: GET /device-location
    S->>S: verify ownership + sharing enabled<br/>audit-log the read
    alt recent fix cached (10-min TTL)
        S-->>Owner: coordinates (decrypted for owner)
    else no recent fix
        S->>Dev: FCM data push "location_request"
        Dev->>Dev: check sharing toggle still ON
        Dev->>S: POST /location-ping (403 if disabled)
        Owner->>S: retry GET → coordinates
    end
```

### Remote camera
```mermaid
sequenceDiagram
    participant Owner as Owner (device A)
    participant S as Server
    participant Dev as Device B (target)
    Owner->>S: POST /request-camera-session
    S->>S: create pending session,<br/>hash one-time nonce, 2-min TTL, audit
    S->>Dev: visible push + nonce
    Dev->>Dev: FULL-SCREEN approval prompt<br/>(camera stays closed)
    alt user taps Approve
        Dev->>S: POST /camera-session-response {nonce, approved:true}
        S->>S: verify nonce hash, audit "approved"
        Dev->>Dev: open in-app camera<br/>with CAMERA ACTIVE indicator
        Dev->>S: POST /upload-camera-photo (approved sessions only)
        S->>S: close session, audit "completed"
    else deny / timeout
        Dev->>S: approved:false → audit "denied"
        S->>S: scheduler expires unanswered sessions
    end
```

## ER diagram

```mermaid
erDiagram
    USERS ||--o{ DEVICES : owns
    USERS ||--o{ USER_SESSIONS : "logs in"
    USERS ||--o{ HABITS : creates
    USERS ||--|| USER_SETTINGS : has
    USERS ||--o{ CATEGORIES : "may define"
    USERS ||--o{ AUDIT_LOGS : generates
    HABITS ||--o{ HABIT_LOGS : "tracked by"
    HABITS ||--o{ REMINDER_SCHEDULES : "reminded by"
    HABITS ||--o{ MILESTONES : targets
    HABITS |o--o| HABITS : "stacked after"
    CATEGORIES ||--o{ HABITS : groups
    HABIT_LOGS ||--o{ PHOTOS : attaches
    DEVICES ||--o{ LOCATION_HISTORY : "opt-in records"
    DEVICES ||--o{ CAMERA_SESSIONS : targets
    CAMERA_SESSIONS |o--o{ PHOTOS : produces
    USERS ||--o{ GEOFENCE_LOCATIONS : defines
    USERS ||--o{ NOTIFICATIONS : receives

    USERS { uuid id PK "email UK, argon2 hash, role, google_sub, timezone" }
    DEVICES { uuid id PK "platform, fcm_token, location_sharing_enabled=false" }
    USER_SESSIONS { uuid id PK "refresh_token_hash, expires_at, revoked_at" }
    HABITS { uuid id PK "frequency+config JSONB, goal, time_of_day, color" }
    HABIT_LOGS { uuid id PK "UK(habit,date), status, value, note" }
    CAMERA_SESSIONS { uuid id PK "purpose, status, nonce_hash, expires_at" }
    LOCATION_HISTORY { uuid id PK "lat/lon Fernet-encrypted, 30-day retention" }
    GEOFENCE_LOCATIONS { uuid id PK "lat/lon encrypted, radius, enter/exit" }
    AUDIT_LOGS { uuid id PK "append-only: action, resource, ip, detail" }
```

## Key decisions

- **Offline-first client**: SQLite cache is the read model; writes mark rows
  dirty and sync when connectivity returns. Server-side `(habit_id, log_date)`
  upsert makes sync idempotent.
- **Refresh rotation with reuse detection**: each refresh invalidates the prior
  token; presenting a stale one kills the whole session (theft signal).
- **Privacy enforced server-side**: the location/camera rules live in the API,
  not the UI — a modified client still cannot read a paused device's location
  or upload without an approved session.
- **Encryption layers**: TLS in transit; Fernet for coordinates at rest;
  SSE-AES256 for photo objects; Argon2id for passwords; SHA-256 for token/nonce
  storage (only hashes persisted).
- **Horizontal scale**: stateless API replicas behind nginx; Redis locks keep
  the scheduler single-firing across replicas.
