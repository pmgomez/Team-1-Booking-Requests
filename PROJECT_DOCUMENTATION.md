# Diocese of Kalookan — Sacramental Booking System

> **Full-Stack Web Application** for digitizing and managing sacramental booking workflows at the Diocese of Kalookan.  
> Replaces paper-based processes with an online system for parishioners and diocesan staff.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Directory Structure](#3-directory-structure)
4. [Architecture](#4-architecture)
5. [Data Model](#5-data-model)
6. [API Reference](#6-api-reference)
7. [Authentication & Authorization](#7-authentication--authorization)
8. [Core Modules](#8-core-modules)
9. [Frontend (Flutter)](#9-frontend-flutter)
10. [Configuration](#10-configuration)
11. [Running the Project](#11-running-the-project)
12. [Testing](#12-testing)
13. [Security](#13-security)
14. [Deployment](#14-deployment)
15. [Contributing](#15-contributing)

---

## 1. Project Overview

### Purpose

A web-based booking system for the **Roman Catholic Diocese of Kalookan** that enables parishioners to request, manage, and track sacramental services online. The system handles the full lifecycle of sacramental bookings including scheduling, document submission, staff approvals, and email notifications.

### Sacraments Supported

| Sacrament | Booking Table | Description |
|-----------|--------------|-------------|
| Baptism | `baptism_bookings` | Infant/child baptism with godparent management |
| Wedding | `wedding_bookings` | Marriage ceremony with seminar tracking |
| Confirmation | `confirmation_bookings` | Confirmation of faith |
| First Eucharist | `eucharist_bookings` | First Holy Communion |
| Reconciliation | `reconciliation_bookings` | Confession scheduling |
| Anointing of the Sick | `anointing_sick_bookings` | Home/hospital visit requests |
| Funeral Mass | `funeral_mass_bookings` | Funeral and wake scheduling |
| Mass Intentions | `mass_intentions` | Mass offerings (For the Dead, Thanksgiving, Special Intention) |

### User Roles

| Role | Privileges |
|------|-----------|
| `parishioner` | Create/manage own bookings, upload documents |
| `parish_staff` | Manage bookings for their parish, view records |
| `priest` | View assigned schedules, manage sacraments |
| `parish_admin` | Full parish-level management, settings, users |
| `diocese_staff` | Cross-parish management, reporting |
| `diocese_admin` | Full system access, all configurations |

---

## 2. Tech Stack

### Backend

| Layer | Technology |
|-------|-----------|
| **Runtime** | Node.js ≥ 18 |
| **Framework** | Express 4.21 |
| **Language** | JavaScript (ES6+) |
| **Database** | PostgreSQL 15 (Supabase / Neon) |
| **ORM** | Sequelize 6 |
| **Auth** | JWT + Passport (Google OAuth, JWT strategy) |
| **API Docs** | Swagger UI (OpenAPI 3.0) |
| **File Storage** | Supabase Storage (local fallback) |
| **Email** | Nodemailer (SMTP) |
| **PDF** | PDFKit |
| **Validation** | express-validator |
| **Testing** | Jest + Supertest |
| **Linting** | ESLint + Prettier |

### Frontend

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter / Dart |
| **Platform Targets** | Android, iOS, Web, Windows, Linux, macOS |

### Infrastructure

| Tool | Purpose |
|------|---------|
| **Docker** | Local PostgreSQL container (postgres:15-alpine) |
| **Supabase** | Production database + file storage |
| **Neon** | Serverless PostgreSQL (alternative) |

---

## 3. Directory Structure

```
Team-1-Booking-Requests/
├── backend/                          # Express API server
│   ├── server.js                     # Entry point
│   ├── package.json
│   ├── openapi.json                  # OpenAPI specification
│   ├── .env.example                  # Environment template
│   ├── .env.development              # Dev environment config
│   ├── assets/                       # Static assets (logo)
│   ├── uploads/                      # Local file uploads
│   │   ├── documents/
│   │   └── temp/
│   ├── postman-tests/                # Postman collection
│   ├── src/
│   │   ├── app.js                    # Express app setup & routing
│   │   ├── config/
│   │   │   └── database.js           # Sequelize DB configuration
│   │   ├── container/
│   │   │   └── index.js              # Dependency Injection container
│   │   ├── controllers/              # HTTP adapters
│   │   ├── dto/                      # Data Transfer Objects
│   │   ├── middleware/               # Auth, upload, error, rate-limit
│   │   ├── models/                   # 22 Sequelize models
│   │   ├── repositories/            # Data access layer
│   │   │   ├── interfaces/          # Repository contracts
│   │   │   └── implementations/     # Concrete implementations
│   │   ├── routes/                   # Express routers
│   │   ├── scripts/                  # Migration & seed scripts
│   │   ├── services/                 # Business services
│   │   │   ├── interfaces/          # Service contracts
│   │   │   └── implementations/     # Concrete implementations
│   │   ├── tests/                    # Jest unit tests
│   │   │   └── unit/
│   │   ├── useCases/                 # Application business logic
│   │   │   ├── admin/
│   │   │   ├── auth/
│   │   │   ├── booking/
│   │   │   ├── massIntention/
│   │   │   └── user/
│   │   └── utils/                    # Utilities (password, permissions)
│   ├── test-*.js                     # Manual test scripts
│   └── *.md                          # Documentation files
│
├── frontend/                         # Flutter mobile/web app
│   ├── lib/                          # Dart source code
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── linux/
│   ├── macos/
│   ├── windows/
│   ├── assets/
│   ├── test/
│   └── pubspec.yaml
│
├── postgres/                         # Local PostgreSQL
│   ├── docker-compose.yml
│   ├── init.sql
│   └── README.md
│
├── requirement-spec                  # Requirements specification
├── README.md
├── RUNNING_APPS.md
└── *.md                              # Various documentation files
```

---

## 4. Architecture

### 4.1 Clean Architecture (Hexagonal / Onion)

The backend follows **Clean Architecture** principles with distinct layered separation:

```
┌────────────────────────────────────────────────────────┐
│  Frameworks & Drivers                                  │
│  (Express, Sequelize, Multer, Nodemailer, Supabase)    │
├────────────────────────────────────────────────────────┤
│  Interface Adapters                                    │
│  (Controllers → DTOs → Middleware)                     │
├────────────────────────────────────────────────────────┤
│  Application Business Rules                            │
│  (Use Cases — single-responsibility business logic)    │
├────────────────────────────────────────────────────────┤
│  Enterprise Business Rules                             │
│  (Domain Models / Sequelize Models)                    │
└────────────────────────────────────────────────────────┘
```

### 4.2 Design Patterns

| Pattern | Usage |
|---------|-------|
| **Repository Pattern** | Interfaces (`IUserRepository`) + Implementations (`UserRepository.js`) abstract data access |
| **Data Transfer Object (DTO)** | Shapes and validates data between layers |
| **Use Case / Interactor** | Each business operation is a single-responsibility class |
| **Dependency Injection** | Custom DI container (`container/index.js`) wires 28 services |
| **Controller as Adapter** | Thin HTTP handlers delegate to use cases |
| **Polymorphic Associations** | `BookingDocument`, `Godparent` use `bookingType` + `bookingId` |
| **Strategy Pattern** | Generic sacrament controller uses config-driven higher-order functions |
| **RBAC** | Role hierarchy with `authorizeRoles()` middleware |

### 4.3 Request Flow

```
HTTP Request
  → Express Router (routes/)
    → Auth Middleware (JWT verify + role check)
      → Rate Limiter (if applicable)
        → Controller (thin adapter)
          → DTO (validate & transform input)
            → Use Case (business logic)
              → Repository (data access abstraction)
                → Sequelize Model (ORM mapping)
                  → PostgreSQL
            → DTO (shape response)
          → JSON Response
```

### 4.4 Dependency Injection Container

The DI Container (`src/container/index.js`) manages the following wiring:

- **Models** → **Repositories** → **Use Cases** → **Controllers**
- **Services**: Email, Auth, File, Google Auth, Notification, Supabase Storage, Token
- All dependencies are lazily instantiated and singletons within the container

---

## 5. Data Model

### 5.1 Entity Relationship Overview

```
users ──────┐
            ├── parishes
            │
            │
baptism_bookings ───┐
wedding_bookings    ├── godparents (polymorphic)
confirmation_...    │
eucharist_...       ├── booking_documents (polymorphic)
reconciliation_...  
anointing_sick_...  
funeral_mass_...
mass_intentions
mass_schedules
parish_slot_settings
blackout_dates
system_configurations
token_blacklist
```

### 5.2 Core Tables

#### `users`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| email | VARCHAR(255) | Unique, not null |
| password_hash | VARCHAR(255) | bcrypt (12 rounds) |
| first_name, last_name | VARCHAR(100) | |
| phone | VARCHAR(20) | |
| role | ENUM | 6 roles (see §1) |
| assigned_parish_id | UUID FK → parishes | Staff assignment |
| preferred_parish_id | UUID FK → parishes | Parishioner's parish |
| google_id | VARCHAR(255) | Google OAuth |
| is_active | BOOLEAN | Account status |
| must_change_password | BOOLEAN | Force password reset |
| last_login_at | TIMESTAMP | |

#### `parishes`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| name | VARCHAR(255) | |
| address | TEXT | |
| contact_email, contact_phone, contact_person | | |
| schedule | JSONB | Weekly mass schedule |
| services_offered | TEXT[] | Array of service types |
| is_active | BOOLEAN | |

#### Sacrament Booking Tables (e.g., `baptism_bookings`)

All 7 dedicated booking tables share a similar pattern with type-specific fields:

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID FK → users | Submitter |
| parish_id | UUID FK → parishes | |
| priest_id | UUID FK → users (nullable) | Assigned priest |
| preferred_date | DATE | Requested date |
| time_slot | VARCHAR(20) | e.g., "09:00 AM" |
| status | ENUM | pending / approved / declined / cancelled / rescheduled |
| notes | JSONB[] | Array of {content, added_by, created_at} |
| created_at / updated_at | TIMESTAMP | |

**Type-specific columns:**

| Table | Notable Columns |
|-------|----------------|
| `baptism_bookings` | child_full_name, date_of_birth, father_name, mother_name |
| `wedding_bookings` | groom_full_name, bride_full_name, seminar_schedule |
| `confirmation_bookings` | confirmand_name, father_name, mother_name |
| `eucharist_bookings` | communicant_name, father_name, mother_name |
| `reconciliation_bookings` | penitent_name |
| `anointing_sick_bookings` | sick_person_name, contact_person, location |
| `funeral_mass_bookings` | deceased_full_name, date_of_death, representative, wake_location |

#### `mass_intentions`
| Column | Type | Notes |
|--------|------|-------|
| type | ENUM | For the Dead / Thanksgiving / Special Intention |
| intention_details | TEXT | |
| donor_name | VARCHAR(255) | |
| parish_id | UUID FK | |
| mass_schedule | JSONB | Target schedule |
| status | ENUM | pending / approved / declined / completed / cancelled |

#### `mass_schedules`
| Column | Type | Notes |
|--------|------|-------|
| day_of_week | ENUM | Mon–Sun |
| start_time, end_time | TIME | |
| priest_id | UUID FK | |
| intention_cutoff_time | TIME | |

#### `parish_slot_settings`
| Column | Type | Notes |
|--------|------|-------|
| service_type | ENUM | Which sacrament |
| daily_limit | INTEGER | Max per day |
| time_slots | JSONB[] | Available time slots |
| min_advance_days, max_advance_days | INTEGER | Booking window |

#### `blackout_dates`
| Column | Type | Notes |
|--------|------|-------|
| date | DATE | |
| is_recurring | BOOLEAN | |
| recurrence_pattern | ENUM | yearly / monthly / weekly |

#### Polymorphic Tables

**`godparents`** — `booking_type` (ENUM) + `booking_id` (UUID) reference any sacrament booking.

**`booking_documents`** — Same polymorphic pattern. Columns: `document_type`, `file_name`, `file_url`, `file_size`, `mime_type`, `is_verified`, `rejection_reason`.

#### `token_blacklist`
| Column | Type | Notes |
|--------|------|-------|
| token | VARCHAR(255) | Hashed JWT |
| expires_at | TIMESTAMP | Token expiration |
| blacklisted_at | TIMESTAMP | |
| reason | VARCHAR(50) | logout / etc. |

#### `system_configurations`
Generic JSON-based config per parish.

---

## 6. API Reference

Base URL: `http://localhost:3000/api` (dev)  
Swagger UI: `http://localhost:3000/api-docs`

### 6.1 Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | — | Register new parishioner |
| POST | `/api/auth/login` | — | Login (returns access + refresh tokens) |
| POST | `/api/auth/refresh` | — | Refresh expired access token |
| GET | `/api/auth/me` | JWT | Get current user profile |
| PUT | `/api/auth/me` | JWT | Update own profile |
| PATCH | `/api/auth/change-password` | JWT | Change current password |
| POST | `/api/auth/logout` | JWT | Blacklist current token |
| POST | `/api/auth/forgot-password` | — | Request 6-digit reset code |
| POST | `/api/auth/reset-password` | — | Reset with code |
| GET | `/api/auth/verify-reset-code/:code` | — | Verify reset code validity |

### 6.2 Baptism Bookings

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/baptisms` | JWT | Create booking |
| GET | `/api/baptisms` | JWT | List user's bookings |
| GET | `/api/baptisms/available-slots` | JWT | Available slots for a date |
| GET | `/api/baptisms/:id` | JWT | Get single booking |
| PUT | `/api/baptisms/:id` | JWT | Update booking |
| DELETE | `/api/baptisms/:id` | JWT | Cancel booking |
| PATCH | `/api/baptisms/:id/status` | Admin | Approve/decline |
| POST | `/api/baptisms/:id/document` | JWT | Attach document |
| DELETE | `/api/baptisms/:id/document/:docId` | JWT | Remove document |

### 6.3 Sacrament Bookings (6 Types)

Applies to: `weddings`, `confirmations`, `eucharist`, `reconciliations`, `anointing-sick`, `funeral-mass`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/sacraments/{type}` | JWT | Create booking |
| GET | `/api/sacraments/{type}` | JWT | List bookings |
| GET | `/api/sacraments/{type}/available-slots` | JWT | Check slot availability |
| GET | `/api/sacraments/{type}/:id` | JWT | Get single booking |
| PUT | `/api/sacraments/{type}/:id` | JWT | Update booking |
| DELETE | `/api/sacraments/{type}/:id` | JWT | Delete booking |
| PATCH | `/api/sacraments/{type}/:id/status` | Admin | Update status |
| POST | `/api/sacraments/{type}/:id/document` | JWT | Upload document |
| DELETE | `/api/sacraments/{type}/:id/document/:docId` | JWT | Delete document |

All 6 types share a single generic controller (`sacramentController.js`) driven by configuration.

### 6.4 Mass Intentions

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/mass-intentions` | JWT | Create intention |
| GET | `/api/mass-intentions` | JWT | List intentions |
| GET | `/api/mass-intentions/:id` | JWT | Get single intention |
| PUT | `/api/mass-intentions/:id` | JWT | Update intention |
| DELETE | `/api/mass-intentions/:id` | JWT | Delete intention |
| PATCH | `/api/mass-intentions/:id/status` | Admin | Change status |
| POST | `/api/mass-intentions/:id/approve` | Admin | Approve with notes |
| POST | `/api/mass-intentions/:id/decline` | Admin | Decline with reason |
| POST | `/api/mass-intentions/:id/document` | JWT | Attach document |

### 6.5 Mass Schedules

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/mass-schedules` | JWT | List all schedules |
| POST | `/api/mass-schedules` | Staff | Create schedule |
| GET | `/api/mass-schedules/:id` | JWT | Get single schedule |
| PUT | `/api/mass-schedules/:id` | Staff | Update schedule |
| DELETE | `/api/mass-schedules/:id` | Staff | Delete schedule |

### 6.6 Parish Settings

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/parish-settings/:parishId/slot-settings` | JWT | Get slot settings |
| POST | `/api/parish-settings/:parishId/slot-settings` | Admin | Create/update slot settings |
| GET | `/api/parish-settings/:parishId/blackout-dates` | JWT | Get blackout dates |
| POST | `/api/parish-settings/:parishId/blackout-dates` | Admin | Create blackout date |
| GET | `/api/parish-settings/:parishId/configuration` | JWT | Get parish config |
| PUT | `/api/parish-settings/:parishId/settings` | Admin | Update parish settings |

### 6.7 Admin Management

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/admin/dashboard` | Admin | Dashboard statistics |
| GET/POST | `/api/admin/users` | Admin | List / create users |
| GET/PUT/DELETE | `/api/admin/users/:id` | Admin | User CRUD |
| GET/POST | `/api/admin/parishes` | Admin | List / create parishes |
| GET/PUT/DELETE | `/api/admin/parishes/:id` | Admin | Parish CRUD |
| GET/PUT | `/api/admin/parishes/:id/configurations` | Admin | System config |
| GET/PUT/DELETE | `/api/admin/bookings` | Admin | Cross-booking management |
| GET | `/api/admin/priests` | All | List priests by parish |
| GET | `/api/admin/priest-schedule` | Priest | Priest's own schedule |

### 6.8 Utility

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/health` | — | Health check |
| GET | `/api` | — | API version info |
| GET | `/api-docs` | — | Swagger UI |

---

## 7. Authentication & Authorization

### 7.1 JWT Token Flow

```
Register / Login
     ↓
Access Token (15 min) + Refresh Token (7 days)
     ↓
Client sends: Authorization: Bearer <access_token>
     ↓
Middleware verifies → attaches req.user
     ↓
On 401 → client uses refresh token → gets new access token
     ↓
Logout → token added to blacklist
```

### 7.2 Role Hierarchy

```
diocese_admin (full access)
  └── diocese_staff (cross-parish operations)
       └── parish_admin (parish-level management)
            ├── priest (scheduling, sacraments)
            └── parish_staff (booking management)
                 └── parishioner (own bookings only)
```

Higher roles inherit permissions of lower roles.

### 7.3 Password Reset Flow

```
Forgot Password → 6-digit code sent via email
     ↓
Verify Code → GET /verify-reset-code/:code
     ↓
Reset Password → POST /reset-password with new password
```

---

## 8. Core Modules

### 8.1 Controllers (`src/controllers/`)

| File | Responsibility |
|------|---------------|
| `authController.js` | Register, login, refresh, logout, password reset |
| `baptismController.js` | Baptism booking CRUD, available slots, status changes |
| `sacramentController.js` | **Generic controller** — generates CRUD handlers for 6 sacrament types from `SACRAMENT_CONFIG` |
| `massIntentionController.js` | Mass intention CRUD + approve/decline |
| `massScheduleController.js` | Mass schedule CRUD |
| `parishController.js` | Parish CRUD |
| `parishSettingsController.js` | Slot settings, blackout dates, configurations |
| `adminController.js` | Dashboard, user management, priest listing |

### 8.2 Use Cases (`src/useCases/`)

Each use case class has a single `execute()` method and encapsulates one business operation.

**Auth:**
- `RegisterUserUseCase`, `LoginUserUseCase`, `RefreshTokenUseCase`, `LogoutUserUseCase`, `UpdateUserProfileUseCase`, `ChangePasswordUseCase`

**Booking:**
- `CreateBookingUseCase`, `GetAllBookingsUseCase`, `GetBookingByIdUseCase`, `UpdateBookingStatusUseCase`

**Mass Intention (fully refactored):**
- `CreateMassIntentionUseCase`, `GetAllMassIntentionsUseCase`, `GetMassIntentionByIdUseCase`
- `UpdateMassIntentionUseCase`, `DeleteMassIntentionUseCase`
- `ApproveMassIntentionUseCase`, `DeclineMassIntentionUseCase`, `UpdateMassIntentionStatusUseCase`

**User Management:**
- `CreateUserUseCase`, `GetAllUsersUseCase`, `GetUserByIdUseCase`, `UpdateUserUseCase`, `DeleteUserUseCase`

**Admin:**
- `GetDashboardStatsUseCase`

### 8.3 Services (`src/services/`)

| Service | Role |
|---------|------|
| `authService.js` | Token generation & verification |
| `emailService.js` | SMTP email sending |
| `fileService.js` | File upload/download (local) |
| `googleAuthService.js` | Google OAuth token exchange |
| `notificationService.js` | In-app / email notifications |
| `supabaseStorageService.js` | Supabase Storage operations |

### 8.4 Middleware (`src/middleware/`)

| Middleware | Function |
|-----------|----------|
| `auth.js` | JWT verification (`authenticate`) + role authorization (`authorizeRoles(...)`) |
| `errorHandler.js` | Global error handler (catches all uncaught errors) |
| `rateLimiter.js` | Rate limiting (auth: 5/15min, API: 100/window) |
| `upload.js` | Multer config (5MB max, MIME validation) |

### 8.5 DTOs (`src/dto/`)

| DTO | Validation |
|-----|-----------|
| `BookingDTO.js` | Booking creation/update fields |
| `MassIntentionDTO.js` | Intention creation, updates, approve/decline |
| `ParishDTO.js` | Parish data |
| `UserDTO.js` | Registration/login, safe user output (strips password_hash) |

---

## 9. Frontend (Flutter)

The Flutter frontend is a cross-platform mobile/desktop/web application located in `/frontend/`.

### Platform Targets

- **Android** — APK/AAB
- **iOS** — IPA (requires Xcode)
- **Web** — PWA (JavaScript bundle)
- **Linux** — Snap/Flatpak/AppImage
- **macOS** — DMG (requires Xcode)
- **Windows** — MSIX/EXE

### Key Directories

```
frontend/
├── lib/               # Dart source
│   ├── main.dart
│   ├── app/           # App configuration, routing
│   ├── models/        # Data models
│   ├── screens/       # UI screens
│   ├── services/      # API client services
│   ├── widgets/       # Reusable widgets
│   └── providers/     # State management
├── android/
├── ios/
├── web/
├── test/              # Flutter tests
└── assets/            # Images, fonts, etc.
```

### Build Commands

```bash
flutter pub get
flutter run                          # Run on connected device
flutter build apk                    # Android APK
flutter build ios                    # iOS build
flutter build web                    # Web build
flutter build linux                  # Linux build
```

---

## 10. Configuration

### 10.1 Environment Variables (`.env.development`)

```env
# App
NODE_ENV=development
PORT=3000
API_URL=http://localhost:3000

# PostgreSQL
DB_HOST=localhost
DB_PORT=5433
DB_NAME=diocese_db_dev
DB_USER=postgres
DB_PASSWORD=postgres
DB_SSL_REQUIRED=false

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=15m
REFRESH_SECRET=your-refresh-secret
REFRESH_EXPIRES_IN=7d

# Email (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email
SMTP_PASS=your-app-password
EMAIL_FROM=noreply@diocese.org

# Google OAuth
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret

# File Upload
MAX_FILE_SIZE=5242880
UPLOAD_PATH=./uploads
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/jpg,application/pdf

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key
SUPABASE_STORAGE_BUCKET=diocese-booking-documents

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
MAX_REQUESTS=100
AUTH_RATE_LIMIT_MAX=5

# Super Admin
SUPER_ADMIN_EMAIL=admin@diocese.org
SUPER_ADMIN_PASSWORD=Admin@123456
```

### 10.2 Local PostgreSQL (Docker)

```yaml
# postgres/docker-compose.yml
services:
  postgres:
    image: postgres:15-alpine
    ports:
      - "5433:5432"
    environment:
      POSTGRES_DB: diocese_db_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - pgdata:/var/lib/postgresql/data
```

Port `5433` is used to avoid conflicts with any existing PostgreSQL instance on port `5432`.

---

## 11. Running the Project

### 11.1 Prerequisites

- Node.js ≥ 18
- npm ≥ 9
- Docker & Docker Compose (for local DB)
- Flutter SDK ≥ 3.x (for frontend)

### 11.2 Quick Start (Backend)

```bash
# 1. Start PostgreSQL
cd postgres
docker-compose up -d

# 2. Install dependencies & configure
cd ../backend
cp .env.example .env.development
npm install

# 3. Initialize database
npm run migrate

# 4. (Optional) Seed sample data
npm run seed

# 5. Start dev server
npm run dev    # http://localhost:3000
```

### 11.3 Database Migration

```bash
npm run migrate
```

This runs `src/scripts/migrate.js` which calls `sequelize.sync({ alter: true })` to synchronize all models with the database schema. It does **not** use Sequelize Migrations CLI — it's a schema sync approach.

### 11.4 Seeding

```bash
npm run seed
```

Populates the database with sample parishes, users (all roles), and test data.

### 11.5 Frontend

```bash
cd frontend
flutter pub get
flutter run
```

### 11.6 Available npm Scripts

| Script | Command | Description |
|--------|---------|-------------|
| `npm start` | `node server.js` | Production start |
| `npm run dev` | `nodemon server.js` | Dev with auto-reload |
| `npm test` | `jest --forceExit` | Run tests |
| `npm run migrate` | `node src/scripts/migrate.js` | Sync DB schema |
| `npm run seed` | `node src/scripts/seed.js` | Seed sample data |
| `npm run lint` | `eslint .` | Lint all files |
| `npm run format` | `prettier --write .` | Format all files |

---

## 12. Testing

### 12.1 Unit Tests

**Framework:** Jest + Supertest  
**Config:** `jest.config.js` — 30s timeout, 50% coverage threshold  
**Location:** `src/tests/unit/`

**Test suites (34 tests passing):**

| Test File | Tests | Coverage |
|-----------|-------|----------|
| `MassIntentionDTO.test.js` | 10 | DTO creation, validation, allowed updates |
| `UserDTO.test.js` | 13 | Registration, login validation, safe output |
| `CreateMassIntentionUseCase.test.js` | 6 | Creation flow, validation, parish check, email |
| `LoginUserUseCase.test.js` | 5 | Invalid email, missing password, disabled account |

### 12.2 Running Tests

```bash
npm test
```

### 12.3 Manual Test Scripts

Located in `backend/`:

- `test-auth.js` — Authentication flow testing
- `test-mass-intention.js` — Mass intention CRUD testing
- `test-new-endpoints.js` — Endpoint smoke tests
- `test-notes-api.js` — Notes API testing
- `test-supabase-upload.js` — Supabase Storage upload testing

### 12.4 Postman Collection

A complete Postman collection and environment are available at:

```
backend/postman-tests/
├── Diocese-Booking-System.postman_collection.json
├── Diocese-Booking-System.postman_environment.json
└── POSTMAN_TESTS.md
```

---

## 13. Security

### 13.1 Authentication & Token Security

- **JWT access tokens**: 15-minute expiry, signed with `JWT_SECRET`
- **Refresh tokens**: 7-day expiry, signed with `REFRESH_SECRET`
- **Token blacklisting**: On logout, token hash stored in `token_blacklist` table until expiry
- **Token refresh**: Old refresh token invalidated on refresh

### 13.2 Password Security

- **Hashing**: bcrypt with 12 salt rounds
- **Strength requirements**: Minimum 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 symbol
- **Force password change**: Temporary passwords require change on first login
- **Password reset**: 6-digit numeric code sent via email, with expiry

### 13.3 Rate Limiting

- **Auth endpoints**: 5 requests per 15-minute window
- **General API**: 100 requests per configurable window

### 13.4 Input Validation

- **express-validator** on all endpoints
- **DTO validation** in the Clean Architecture layer
- **File upload restrictions**: MIME type validation (jpeg/png/pdf), extension check, 5MB max

### 13.5 HTTP Security (Helmet)

Standard Helmet middleware active on all routes for HTTP header security.

### 13.6 CORS

Restricted to configured origins (Flutter app URLs in production).

### 13.7 Other Measures

- `?` parameterized queries via Sequelize (prevents SQL injection)
- Role verification on every admin/staff endpoint
- Error handler strips stack traces in production

---

## 14. Deployment

### 14.1 Production Build

```bash
cd backend
NODE_ENV=production npm install --production
npm start
```

### 14.2 Database

The project supports two PostgreSQL providers:

1. **Supabase** — Managed PostgreSQL + Storage (recommended for production)

Environment variables control the connection. Use `DB_HOST`, `DB_PORT`, etc. for direct connections, or configure via Supabase URL/key.

### 14.3 File Storage

- **Production**: Supabase Storage (configured via `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `SUPABASE_STORAGE_BUCKET`)
- **Development**: Local filesystem (`./uploads/` directory) as fallback

### 14.4 Flutter Build

```bash
cd frontend
flutter build web          # Web deployment
flutter build apk          # Android APK
flutter build ios --no-codesign  # iOS (without signing)
```

---

## 15. Contributing

### Code Style

- ES6+ syntax with `const`/`let` (no `var`)
- Error-first patterns with async/await
- `camelCase` for variables/functions, `PascalCase` for classes/models
- Descriptive route paths with kebab-case

### Commit Conventions

Commits follow descriptive English messages summarizing the change. Examples:

```
Fixed delete issue on sacraments, edit schedule time format fix
Fixed mass intentions list/print bugs
Added mass intentions lists/print
Fixed additional notes, file upload, priest selection, used Supabase storage
```

### Clean Architecture Guidelines

When adding new features:

1. Create **Model** (Sequelize) if new table needed
2. Create **Repository Interface** + **Implementation**
3. Create **Use Case** class with single `execute()` method
4. Create **Controller** that delegates to use case
5. Create **Route** with validation middleware
6. Wire dependencies in `container/index.js`
7. Write **tests** (Jest + Supertest)

### File Organization

- One file per class/component
- Filename matches exported class/function name (`PascalCase`)
- Related files grouped in subdirectories (e.g., `useCases/auth/`)

---

## Appendix

### A. Key Files Reference

| File | Purpose |
|------|---------|
| `backend/server.js` | Entry point |
| `backend/src/app.js` | Express app setup, route mounting |
| `backend/src/container/index.js` | DI container wiring |
| `backend/src/config/database.js` | Sequelize connection config |
| `backend/src/models/index.js` | Model associations |
| `backend/openapi.json` | Full OpenAPI 3.0 specification |
| `backend/src/scripts/migrate.js` | Database migration script |
| `backend/src/scripts/seed.js` | Sample data seeder |

### B. Architecture Documentation

Additional docs within the repository:

| Document | Location |
|----------|----------|
| Backend Architecture | `backend/src/ARCHITECTURE.md` |
| Running the Apps | `RUNNING_APPS.md` |
| Admin Setup | `backend/ADMIN_SETUP.md` |
| Admin API | `backend/ADMIN_API.md` |
| Supabase Storage Setup | `backend/SUPABASE_STORAGE_SETUP.md` |
| API Audit Report | `API_AUDIT_REPORT.md` |
| Backend Integration Summary | `BACKEND_INTEGRATION_COMPLETE.md` |
| Implementation Summary | `backend/IMPLEMENTATION_SUMMARY.md` |
| Refactoring Summary | `backend/REFACTORING_COMPLETE.md` |
| Upload Fix Summary | `UPLOAD_FIX_SUMMARY.md` |
| Notes Migration Summary | `NOTES_MIGRATION_SUMMARY.md` |

### C. Dependencies (Backend)

**Production (47 packages):**

| Package | Version | Purpose |
|---------|---------|---------|
| express | ^4.21 | Web framework |
| sequelize | ^6 | ORM |
| pg, pg-hstore | ^8 | PostgreSQL driver |
| @neondatabase/serverless | ^0.9 | Serverless PostgreSQL |
| jsonwebtoken | ^9 | JWT |
| bcryptjs | ^2.4 | Password hashing |
| dotenv | ^16 | Environment variables |
| cors | ^2.8 | CORS headers |
| helmet | ^7 | Security headers |
| morgan | ^1.10 | HTTP logging |
| express-rate-limit | ^7 | Rate limiting |
| express-validator | ^7 | Input validation |
| multer | ^1.4 | File uploads |
| nodemailer | ^6 | Email |
| passport, passport-jwt | ^0.7/^4 | JWT auth strategy |
| passport-google-oauth20 | ^2 | Google OAuth |
| @supabase/supabase-js | ^2 | Supabase client |
| googleapis | ^134 | Google API client |
| axios | ^1 | HTTP client |
| pdfkit | ^0.15 | PDF generation |
| swagger-ui-express | ^5 | API docs UI |
| uuid | ^9 | UUID generation |

**Dev (5 packages):**

| Package | Version | Purpose |
|---------|---------|---------|
| jest | ^29 | Test runner |
| supertest | ^7 | HTTP testing |
| nodemon | ^3 | Auto-restart |
| eslint | ^8 | Linter |
| prettier | ^3 | Formatter |
