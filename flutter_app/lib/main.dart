import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'state/cart_state.dart';
import 'state/menu_state.dart';
import 'state/order_state.dart';
import 'state/robot_state.dart';
import 'state/security_state.dart';
import 'services/settings_service.dart';
import 'screens/auth_gate.dart';

/// True once Firebase.initializeApp() has succeeded. Kept as a plain
/// top-level flag (checked before runApp) rather than inside AppState so
/// every *_State constructor — which reads AppState synchronously as soon
/// as MultiProvider builds — sees the correct value from the very first
/// frame, with no async race.
bool _firebaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted settings (backend URL, ESP32 IP, UPI details) BEFORE
  // building the widget tree, so AppState's constructor can read them
  // synchronously — no loading spinner needed on first frame.
  final settings = SettingsService();
  await settings.load();

  final options = DefaultFirebaseOptions.currentPlatform;
  if (options.apiKey == 'REPLACE_ME') {
    // firebase_options.dart is still the placeholder — don't even attempt
    // init (a half-configured Firebase project can behave inconsistently
    // rather than failing cleanly). Run `flutterfire configure` to fix —
    // see FIREBASE_SETUP.md.
    debugPrint('[Firebase] firebase_options.dart is still a placeholder — '
        'run `flutterfire configure` (see FIREBASE_SETUP.md).');
  } else {
    try {
      await Firebase.initializeApp(options: options);
      _firebaseReady = true;
    } catch (e) {
      debugPrint('[Firebase] Init failed, continuing without it: $e');
      _firebaseReady = false;
    }
  }

  runApp(TrainDeliveryApp(settings: settings));
}

class TrainDeliveryApp extends StatelessWidget {
  final SettingsService settings;
  const TrainDeliveryApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final appState = AppState(settings);
          appState.setFirebaseAvailable(_firebaseReady);
          if (appState.simulationMode) {
            appState.simulation.start();
          } else {
            appState.api.connectWebSocket();
          }
          return appState;
        }),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProxyProvider<AppState, MenuState>(
          create: (ctx) => MenuState(ctx.read<AppState>()),
          update: (ctx, appState, previous) => previous ?? MenuState(appState),
        ),
        ChangeNotifierProxyProvider<AppState, OrderState>(
          create: (ctx) => OrderState(ctx.read<AppState>()),
          update: (ctx, appState, previous) => previous ?? OrderState(appState),
        ),
        ChangeNotifierProxyProvider<AppState, RobotState>(
          create: (ctx) => RobotState(ctx.read<AppState>()),
          update: (ctx, appState, previous) => previous ?? RobotState(appState),
        ),
        ChangeNotifierProxyProvider<AppState, SecurityState>(
          create: (ctx) => SecurityState(ctx.read<AppState>()),
          update: (ctx, appState, previous) =>
              previous ?? SecurityState(appState),
        ),
      ],
      child: MaterialApp(
        title: 'RailDine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}
