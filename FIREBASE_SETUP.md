# Firebase Setup Guide

Everything in this codebase already expects Firebase — this is the
checklist to make it real. Follow it top to bottom; each step says exactly
what to click/run and how to know it worked.

Until you do this, the app runs perfectly well without it (Simulation
login + in-memory backend storage), so there's no rush — do it whenever
you're ready to move off demo data.

---

## 1. Create the Firebase project

1. Go to https://console.firebase.google.com/ and sign in with your
   Google account.
2. Click **Add project** → name it (e.g. `smart-train-delivery`) → you can
   disable Google Analytics for this project, it isn't needed → **Create
   project**.

## 2. Enable Phone Authentication

1. In the left sidebar: **Build → Authentication → Get started**.
2. Under **Sign-in method**, click **Phone** → toggle **Enable** → **Save**.
3. While you're here, go to **Settings → Authorized domains** and confirm
   `localhost` is listed (needed for `flutter run -d chrome` during dev).
4. **Testing without burning real SMS quota:** still on the Sign-in method
   page, scroll to **Phone numbers for testing** and add e.g.
   `+91 9999999999` with a fixed code `123456`. Logging in with that exact
   number will always accept `123456` as the OTP — no real SMS is sent.
   Great for development; remove it before a public launch.

## 3. Create the Firestore database

1. **Build → Firestore Database → Create database**.
2. Choose **Start in test mode** for now (open read/write for 30 days —
   fine while you're building; see the security rules note at the bottom
   before going anywhere near production).
3. Pick a location close to you → **Enable**.

## 4. Connect the Flutter app (passenger + staff)

From your machine, inside `flutter_app/`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This will:
- Ask you to log in (opens a browser)
- Ask which Firebase project to use — pick the one you just created
- Ask which platforms to generate config for — select at least **Web** (for
  Chrome/staff dashboard); add **Android**/**iOS** too if you'll build those
- **Overwrite `lib/firebase_options.dart`** with real, working keys

That's it on the Flutter side — `main.dart` already calls
`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
at startup. Run the app; Staff → Settings should now show **"Firebase
Connected"**, and Passenger Login should show a **"Firebase Phone Auth"**
badge instead of "Demo Login".

## 5. Connect the FastAPI backend

The backend writes to the *same* Firestore project via `firebase-admin`, so
ESP32 events (marker detection, security alerts) and staff order updates
show up live in the app instantly.

1. In the Firebase console: **Project settings (gear icon) → Service
   accounts → Generate new private key**. This downloads a `.json` file.
2. Rename it `serviceAccountKey.json` and place it at:
   ```
   train_delivery_system/backend/serviceAccountKey.json
   ```
   (This path is already in `.gitignore` — **never commit this file**, it's
   a full-access credential for your Firebase project.)
3. Restart the backend:
   ```bash
   cd backend
   uvicorn app.main:app --reload
   ```
   The startup banner will now print `Storage backend : CLOUD FIRESTORE`
   instead of `IN-MEMORY (local dev)`.

## 6. Verify it end-to-end

1. `flutter run -d chrome` → log in as Passenger with your test phone
   number + the fixed test code from step 2.
2. Place an order.
3. Open a second Chrome window → Staff login → Orders tab — the order
   should appear live, with no manual refresh.
4. In the Firebase console, open **Firestore Database** — you should see
   `orders`, `menu`, `robots`, `users` collections populated with real
   documents.

If the staff Orders view is empty the first time, that's expected — the
`menu` collection auto-seeds 5 demo items on first backend startup, but
`orders` only has documents once someone places one.

---

## Collections this system uses

| Collection         | Written by                          | Read live by                     |
|---------------------|--------------------------------------|-----------------------------------|
| `menu`               | Backend (staff menu management API) | Flutter (passenger + staff)       |
| `orders`             | Backend (order creation/status API) | Flutter (passenger + staff)       |
| `robots`             | Backend (ESP32 register/heartbeat/marker events) | Flutter (staff robot track + analytics) |
| `security_alerts`    | Backend (ESP32 tamper alert)        | Flutter (staff security tab)      |
| `users`              | Flutter (on passenger login)        | —  (order history lookups by `passengerId`) |

## Payments

UPI payments are a direct peer-to-peer transfer, not a gateway — no
Firebase involvement, no KYC needed. Configure your UPI ID in Staff →
Settings once the app is running. See `backend/.env` for the
single staff account setup (separate from Firebase, works regardless of
whether Firebase is configured).

## Before going to production

- **Firestore security rules:** test mode allows anyone to read/write
  everything. Before a real deployment, write rules restricting writes to
  the backend's service account and reads to authenticated users for their
  own data. This is a normal Firebase project step, not specific to this
  codebase — see https://firebase.google.com/docs/firestore/security/get-started
- **Remove the test phone number** from Authentication settings once real
  SMS delivery is confirmed working.
- **Rotate `serviceAccountKey.json`** if it's ever accidentally exposed
  (Project settings → Service accounts → you can revoke old keys there).
