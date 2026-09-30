# 🚄 RailDine

**Autonomous overhead-rail food delivery for Indian luxury trains — order from your seat, robot delivers, OTP unlocks it.**

RailDine is a full-stack system pairing a Flutter app (Passenger + Staff) with a FastAPI backend, Firebase (Auth/Firestore/Storage), and an ESP32-controlled overhead delivery robot. Built for high-speed rail services like Vande Bharat and Rajdhani Express, where onboard catering is currently manual, slow, and inconsistent.

**🔗 Live demo:** [train-delivery-system.firebaseapp.com](https://train-delivery-system.firebaseapp.com)

---

## ✨ Features

### Passenger app
- Scan a seat QR → phone-OTP login (Firebase Phone Auth) → auto-restores session on reopen
- Enter coach + seat once, remembered across sessions
- Bistro tab — browse menu by category, live availability (out-of-stock items auto-grey out)
- Real UPI payment — scan QR or open GPay/PhonePe/Paytm directly, no payment gateway middleman
- Prepaid-ticket payment path (demo PNR verification, swappable for a real railway API)
- Live order tracking — status timeline, live robot transit visualization, OTP-gated compartment unlock
- Order history

### Staff dashboard (mobile + Chrome desktop)
- Kanban-style live order board (Placed → Confirmed → Preparing → Ready → Dispatched)
- Menu management — add/edit/delete items, toggle availability, upload photos straight from gallery (Firebase Storage)
- Robot Track — live overhead-track visualization; manual Dispatch/Recall controls in Simulation Mode
- Analytics — real order data in Live Mode, illustrative demo data in Simulation Mode
- Security Alerts — siren + full-screen alert on ESP32 tamper detection, works in both modes
- Settings — UPI details, backend URL, ESP32 IP, Simulation/Live toggle (all sync live across every device via Firestore)

### Backend + hardware
- FastAPI service coordinating orders, OTP generation/verification, ESP32 registration & heartbeats
- Firestore-or-in-memory storage — runs with zero cloud setup, upgrades to real Firestore the moment `serviceAccountKey.json` is added
- ESP32 firmware reference (ino) — WiFi auto-connect, self-registration, heartbeat, marker detection, tamper alert, servo unlock
- Single staff account, no multi-tenant complexity by design

---

## 🧱 Architecture

```
┌───────────────────┐         ┌───────────────────┐         ┌──────────────────┐
│   Flutter App     │◄───────►│  FastAPI Backend  │◄───────►│  ESP32 + Robot   │
│ Passenger + Staff │  REST/  │ orders · OTP ·    │  WiFi   │ overhead track,  │
│  (mobile + web)   │   WS    │ menu · security   │  REST   │ servo, sensors   │
└────────┬──────────┘         └──────────┬────────┘         └─────┬────────────┘
         │                               │                        │
         │            Firestore (shared) │                        │
         └──────────────────►  orders · menu · robots ◄───────────┘
                        security_alerts · app_config
```

**Golden rule:** Flutter displays and requests → FastAPI validates and coordinates → Firestore persists → ESP32 senses and physically acts.

---

## 🛠️ Tech stack

| Layer | Tech |
|---|---|
| Frontend | Flutter (mobile + web), Provider |
| Backend | FastAPI, Python, WebSockets |
| Database / Auth | Firebase (Firestore, Auth, Storage) |
| Payments | UPI (direct QR/deep-link, no gateway) |
| Hardware | ESP32, Hall-effect sensors, servo lock, MPU6050 |

---

## 🚀 Getting started

### Prerequisites
- Flutter SDK (3.3+)
- Python 3.10+
- A Firebase project (see [`FIREBASE_SETUP.md`](./FIREBASE_SETUP.md))

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env            # set your own staff mobile/password
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Runs with an in-memory store out of the box. Add `backend/serviceAccountKey.json` (Firebase console → Project Settings → Service Accounts → Generate new private key) to switch to real Cloud Firestore — no code changes needed.

### Flutter app

```bash
cd flutter_app
flutter pub get
flutter run -d chrome      # staff dashboard / quick testing
flutter build apk --release   # real installable app — needed for silent OTP (see note below)
```

Full Firebase wiring (Phone Auth, Firestore, Storage) — see [`FIREBASE_SETUP.md`](./FIREBASE_SETUP.md).

> **Why build a real APK for passengers:** Firebase Phone Auth requires reCAPTCHA verification when running as a website in a browser. On a real installed Android app, this becomes a silent Play Integrity check instead — no browser popups. Use the web build for the Staff Chrome dashboard; use the installed APK for passengers.

---

## ⚙️ Configuration

Two kinds of settings, stored two different ways:

- **Device-local** (ESP32 IP) — set per-device in Staff → Settings, persisted via `shared_preferences`.
- **Business-wide** (UPI ID, backend URL, Simulation/Live mode) — set once from Staff → Settings, synced live to every device via a shared Firestore document (`app_config/main`). No passenger device ever needs manual configuration for these.

The single staff account lives in `backend/.env` (pre-Firebase) or is created directly in Firebase console under Authentication → Users (post-Firebase, recommended) — see [`backend/.env`](./backend/.env).

---

## 📁 Project structure

```
railDine/
├── backend/                FastAPI service
│   ├── app/
│   │   ├── main.py
│   │   ├── models/schemas.py
│   │   ├── services/       store.py (Firestore-or-memory), events.py, ws_manager.py
│   │   └── routers/        auth, menu, orders, payments, esp32, otp, security, analytics
│   └── .env
├── flutter_app/             Flutter app (Passenger + Staff)
│   ├── lib/
│   │   ├── screens/passenger/   Bistro, Track, Orders, Profile tabs
│   │   ├── screens/staff/       Orders, Menu, Robot Track, Analytics, Alerts, Settings
│   │   ├── state/                one ChangeNotifier per concern
│   │   ├── services/             api, firestore, firebase_auth, storage, upi, settings
│   │   └── theme/                single-file color palette
│   └── assets/icon/app_icon.png
├── esp32_firmware/          Reference Arduino sketch
└── FIREBASE_SETUP.md
```

---

## ⚠️ Known limitations / roadmap

- **UPI payments are self-confirmed** — this is a direct peer-to-peer transfer with no gateway, so there's no automatic payment verification. The passenger confirms in-app after completing the transfer (same trust model as any small UPI-accepting vendor today). A registered payment aggregator (Razorpay, Cashfree, etc.) is the natural upgrade path if automatic verification becomes necessary.
- **Prepaid ticket verification** uses a small demo table (`backend/app/services/store.py`), not a real railway PNR API — swap this out for production use.
- **Single staff account by design** — no multi-tenant / multi-staff-role support currently.
- **Physical robot hardware** — the ESP32 firmware is a working reference implementation; Simulation Mode lets the full software stack (orders, tracking, analytics, alerts) be demoed end-to-end before hardware is built.

---
## 🙋 Author

Built by Harish Keshav Gangurde — a train food delivery system combining Flutter, FastAPI, Firebase, and an overhead-rail delivery robot concept for Indian Railways.

