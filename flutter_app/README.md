# Flutter App

```
lib/
├── main.dart                          Loads settings + Firebase, then builds the app
├── firebase_options.dart              Placeholder until `flutterfire configure` runs
├── theme/
│   └── app_theme.dart                 "TRAIN_TECH_OS" theme: near-black bg, violet accent
├── models/                            Dart mirrors of backend/app/models/schemas.py
├── services/
│   ├── api_service.dart               REST calls + WebSocket live stream to FastAPI
│   ├── simulation_service.dart        Fake ESP32/robot event generator (hardware demo only)
│   ├── settings_service.dart          Persists backend URL / ESP32 IP / UPI details on-device
│   ├── upi_service.dart               Builds the UPI payment deep link / QR payload
│   ├── firebase_auth_service.dart     Phone-OTP login, direct to Firebase
│   └── firestore_service.dart         Live Firestore streams (menu/orders/robots/alerts)
├── state/                             One ChangeNotifier per concern; screens only read these
├── widgets/                           Shared UI: brand header, category pills, food cards,
│                                       OTP boxes, timeline stepper, glass cards
└── screens/
    ├── login_selection_screen.dart
    ├── passenger/
    │   ├── passenger_shell_screen.dart    Bottom-nav shell: Bistro / Track / Orders / Profile
    │   ├── bistro_tab.dart, track_tab.dart, orders_tab.dart, profile_tab.dart
    │   ├── food_detail_screen.dart, cart_screen.dart, payment_screen.dart (real UPI)
    │   └── coach_seat_screen.dart, passenger_login_screen.dart
    └── staff/
        ├── staff_dashboard_screen.dart     Side-nav (wide) / bottom-nav (mobile) shell
        ├── orders_view.dart, menu_management_view.dart, robot_track_view.dart,
        │   admin_analytics_view.dart, security_alerts_view.dart, settings_view.dart
        └── staff_login_screen.dart
```

## Design language

Near-black background, a single vivid violet accent, fully-rounded pill
buttons/chips/inputs, minimal chrome — the "TRAIN_TECH_OS" look. See
`theme/app_theme.dart` for the token values (`AppColors.primary`,
`AppColors.primaryBright`, etc.) — every screen reads from there, so a
future palette change is a one-file edit.

## Two independent toggles

- **`AppState.firebaseAvailable`** — true once Firebase is actually
  configured (`flutterfire configure` + `backend/serviceAccountKey.json`).
  Controls passenger login (Firebase Phone Auth vs a mock OTP fallback)
  and whether menu/orders/robots/alerts stream live from Firestore.
- **`AppState.simulationMode`** — ESP32/robot hardware only. Lets you
  demo the whole ordering + tracking flow before physical hardware
  exists. Independent of Firebase — orders, payments and menu are real
  (once Firebase is on) regardless of this toggle.

Both are configurable from Staff → Settings, and persist across restarts
via `settings_service.dart` (backed by `shared_preferences`).

## Payments

`payment_screen.dart` builds a UPI deep link / QR code from the UPI ID
(VPA) configured in Staff → Settings (`services/upi_service.dart`). This
is a direct transfer, not a payment gateway — there's no automatic
verification, so the passenger explicitly confirms completion in-app
before the order is created with `paymentStatus: PAID`.
