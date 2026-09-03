import 'package:shared_preferences/shared_preferences.dart';

/// Everything configurable from Staff Settings, persisted on-device so it
/// survives app restarts — a real deployment shouldn't need re-entering
/// the backend URL or UPI ID every time the app opens.
class SettingsService {
  static const _kBackendUrl = 'backend_url';
  static const _kEsp32Address = 'esp32_address';
  static const _kUpiVpa = 'upi_vpa';
  static const _kUpiPayeeName = 'upi_payee_name';
  static const _kSimulationMode = 'simulation_mode';

  late SharedPreferences _prefs;
  bool _loaded = false;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  String get backendUrl =>
      _prefs.getString(_kBackendUrl) ?? 'http://localhost:8000';
  Future<void> setBackendUrl(String value) =>
      _prefs.setString(_kBackendUrl, value);

  String get esp32Address => _prefs.getString(_kEsp32Address) ?? '';
  Future<void> setEsp32Address(String value) =>
      _prefs.setString(_kEsp32Address, value);

  /// Empty until staff configures it — the Payment screen and Settings
  /// both show a clear "not configured" state rather than a fake default,
  /// since a placeholder VPA would silently send money nowhere.
  String get upiVpa => _prefs.getString(_kUpiVpa) ?? '';
  Future<void> setUpiVpa(String value) => _prefs.setString(_kUpiVpa, value);

  String get upiPayeeName => _prefs.getString(_kUpiPayeeName) ?? '';
  Future<void> setUpiPayeeName(String value) =>
      _prefs.setString(_kUpiPayeeName, value);

  bool get simulationMode => _prefs.getBool(_kSimulationMode) ?? true;
  Future<void> setSimulationMode(bool value) =>
      _prefs.setBool(_kSimulationMode, value);

  bool get upiConfigured => upiVpa.trim().isNotEmpty;

  // ---- Passenger session persistence ----
  //
  // Firebase Auth already keeps a passenger signed in across app restarts
  // on its own — this just remembers WHICH coach/seat they'd entered, so
  // reopening the app can skip straight back to the menu instead of
  // asking again. See screens/auth_gate.dart, which is what actually
  // uses this on startup.
  static const _kLastCoachNo = 'last_coach_no';
  static const _kLastSeatNo = 'last_seat_no';

  String get lastCoachNo => _prefs.getString(_kLastCoachNo) ?? '';
  String get lastSeatNo => _prefs.getString(_kLastSeatNo) ?? '';

  Future<void> setLastCoachSeat(String coach, String seat) async {
    await _prefs.setString(_kLastCoachNo, coach);
    await _prefs.setString(_kLastSeatNo, seat);
  }

  Future<void> clearLastCoachSeat() async {
    await _prefs.remove(_kLastCoachNo);
    await _prefs.remove(_kLastSeatNo);
  }
}
