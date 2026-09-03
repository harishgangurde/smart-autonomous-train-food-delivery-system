# Smart Train Food Delivery System

Two independent projects, talking over REST:

```
train_delivery_system/
├── backend/          FastAPI service — validation, coordination, ESP32 bridge
└── flutter_app/       Flutter app — Passenger + Staff, runs on mobile AND Chrome (web)
```

Golden rule used everywhere in this codebase:

> **Flutter** displays and requests → **FastAPI** validates and coordinates →
> **Firebase** persists → **ESP32** senses and physically acts.

## Running the backend

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The terminal will print live event logs (ESP32 connect, orders, OTP checks,
security alerts) exactly like the demo-log format we designed — this is what
you show during your project demonstration.

Currently the backend uses an **in-memory store** (`app/services/store.py`)
standing in for Firestore, so you can run the whole system with zero cloud
setup. Swap `store.py`'s internals for `firebase-admin` calls later — every
router only talks to `store.py`, so nothing else needs to change.

## Running the Flutter app

```bash
cd flutter_app
flutter pub get
flutter run -d chrome          # staff big-screen / testing
flutter run                    # mobile device/emulator
```

Set the backend URL in `lib/services/api_service.dart` (`baseUrl`). For
Chrome + local backend, `http://localhost:8000` works out of the box.

## Firebase (real phone-OTP login + real-time storage)

The whole system is written to work with **zero cloud setup** by default
(Simulation login + in-memory backend store) and to automatically switch
to **real Firebase** the moment it's configured — no code changes needed.
Follow `FIREBASE_SETUP.md` in this folder when you're ready; it covers
creating the project, enabling Phone Auth, Firestore, and connecting both
the Flutter app and the FastAPI backend to the same project.

## Simulation mode

Staff → Settings has a **Simulation / Live** toggle. In Simulation mode, all
screens (robot track, ESP32 status, order progression) are fed by
`lib/services/simulation_service.dart`, a fake event generator matching the
exact same data shapes the real backend sends. Flip the switch and the UI
should behave identically driven by real events — that's the point of
building it this way. This lets you demo without hardware in the room.

## Where things live

See `backend/README.md` and `flutter_app/README.md` for per-project detail.
