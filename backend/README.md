# Backend (FastAPI)

```
backend/
├── .env.example              Copy to .env — single staff account config
└── app/
    ├── main.py                FastAPI app, CORS, startup banner, WebSocket hub, loads .env
    ├── models/
    │   └── schemas.py         Pydantic request/response models — the contract
    ├── services/
    │   ├── store.py           Firestore-or-in-memory storage (auto-detects)
    │   ├── events.py          Console logger (the pretty demo terminal output)
    │   └── ws_manager.py       WebSocket broadcast to Flutter (live order/robot updates)
    └── routers/
        ├── auth.py            Passenger mock-OTP (legacy) + the single staff account
        ├── menu.py             Menu CRUD, availability toggle
        ├── orders.py           Cart→order, status transitions, prep-time calc
        ├── payments.py         Prepaid-ticket verification only — UPI is client-side
        ├── esp32.py            Robot registration, heartbeat, IP status, marker events
        ├── otp.py              Delivery OTP generation + strict multi-field verification
        ├── security.py         Tamper alerts from ESP32 → staff
        └── analytics.py        (legacy summary endpoint — Flutter now computes this locally)
```

Every router only touches `services/store.py`. That's the seam: it
auto-detects `backend/serviceAccountKey.json` and switches from an
in-memory dict to real Cloud Firestore transparently — nothing above it
needs to change either way. See `../FIREBASE_SETUP.md`.

## Staff account

Copy `.env.example` to `.env` in this folder and set your real mobile
number and password:

```bash
cp .env.example .env
# then edit .env
```

`.env` is gitignored — never commit real credentials. There's a single
staff account by design (`auth.py` reads `STAFF_MOBILE` / `STAFF_PASSWORD`
/ `STAFF_NAME`); this isn't configurable from inside the app for security.

## Payments

UPI payment links/QR codes are built entirely in Flutter
(`services/upi_service.dart`) from a UPI ID (VPA) configured in Staff →
Settings — this backend has no payment gateway involvement and holds no
payment credentials. It's a direct peer-to-peer transfer, so there's no
webhook to verify payment; the order's `paymentStatus` is set to `PAID`
only after the passenger confirms in-app that they've completed the
transfer.

## Live updates to Flutter

`ws_manager.py` keeps a set of connected Flutter clients (passenger app +
staff dashboard) and broadcasts JSON events on a single WebSocket channel
(`/ws`) whenever anything changes — new order, status change, robot marker
detected, OTP result, security alert. Flutter's `api_service.dart` listens
on this socket when not using Firestore directly; once Firebase is
configured, Flutter prefers Firestore's own real-time listeners instead
(see `FIREBASE_SETUP.md`), so both paths stay live either way.

## API docs

Once running: `http://localhost:8000/docs` (Swagger UI, auto-generated).
