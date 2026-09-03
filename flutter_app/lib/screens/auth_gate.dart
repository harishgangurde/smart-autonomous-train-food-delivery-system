import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'login_selection_screen.dart';
import 'passenger/coach_seat_screen.dart';
import 'passenger/passenger_shell_screen.dart';
import 'staff/staff_dashboard_screen.dart';

/// The app's actual home widget. Firebase Auth already persists a signed-in
/// session across app restarts on its own (this is standard Firebase
/// behaviour, not something we built) — this widget is what makes use of
/// that fact: check on startup whether someone's already authenticated,
/// and if so route straight back into the app instead of asking them to
/// log in again every time they close and reopen it.
///
/// Distinguishes passenger vs staff by how they authenticated: passengers
/// sign in with phone OTP (their Firebase user has a phoneNumber), staff
/// sign in with email/password (no phoneNumber, has an email). See
/// services/firebase_auth_service.dart.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Widget? _resolved;

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame — AppState mutations (loginPassenger
    // etc.) call notifyListeners(), which isn't safe to trigger mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  void _resolve() {
    final appState = context.read<AppState>();

    if (!appState.firebaseAvailable) {
      setState(() => _resolved = const LoginSelectionScreen());
      return;
    }

    final user = appState.firebaseAuth.currentUser;
    if (user == null) {
      setState(() => _resolved = const LoginSelectionScreen());
      return;
    }

    if (user.phoneNumber != null) {
      // Passenger session, restored automatically.
      appState.loginPassenger(passengerId: user.uid, mobile: user.phoneNumber!);
      final savedCoach = appState.settings.lastCoachNo;
      final savedSeat = appState.settings.lastSeatNo;
      if (savedCoach.isNotEmpty && savedSeat.isNotEmpty) {
        appState.setCoachSeat(savedCoach, savedSeat);
        setState(() => _resolved = const PassengerShellScreen());
      } else {
        setState(() => _resolved = const CoachSeatScreen());
      }
    } else {
      // Staff session, restored automatically.
      appState.loginStaff(staffId: user.uid, name: user.email ?? 'Staff');
      setState(() => _resolved = const StaffDashboardScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _resolved ??
        const Scaffold(
          backgroundColor: Color(0xFF08080C),
          body: Center(child: CircularProgressIndicator()),
        );
  }
}
