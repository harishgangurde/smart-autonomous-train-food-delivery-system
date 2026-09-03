import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/simulation_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';

enum UserRole { none, passenger, staff }

/// Root state: who's logged in, and whether the whole app is in
/// Simulation or Live mode.
///
/// Two different kinds of "settings" live here, deliberately stored two
/// different ways:
///
/// - **Device-local** (`esp32Address`): genuinely differs per device, so
///   it stays in [SettingsService] (SharedPreferences).
/// - **Business-wide** (`simulationMode`, `upiVpa`, `upiPayeeName`, and
///   now `backendUrl` too): the same for everyone using the app. Backend
///   URL moved into this group after a real bug — a phone's SharedPreferences
///   never had it set, since it's a different device/browser than
///   whichever one staff configured it on. Passengers on their own phone
///   were stuck on `localhost` (which on a phone means the phone itself,
///   never reaching the actual backend), causing every order/ticket
///   action to silently fail. Since most deployments share one train/venue
///   WiFi + one backend machine, syncing this via Firestore (like UPI
///   details) fixes it for the common case.
class AppState extends ChangeNotifier {
  final ApiService api = ApiService();
  final SimulationService simulation = SimulationService();
  final FirebaseAuthService firebaseAuth = FirebaseAuthService();
  final FirestoreService firestore = FirestoreService();
  final StorageService storage = StorageService();
  final SettingsService settings;

  StreamSubscription? _appConfigSub;

  AppState(this.settings) {
    simulationMode = settings.simulationMode;
    esp32Address = settings.esp32Address;
    upiVpa = settings.upiVpa;
    upiPayeeName = settings.upiPayeeName;
    ApiService.baseUrl = settings.backendUrl;
  }

  bool firebaseAvailable = false;

  UserRole role = UserRole.none;

  // Passenger session
  String? passengerId;
  String? passengerMobile;
  String? coachNo;
  String? seatNo;
  String? activeOrderId;
  int passengerTabIndex = 0; // 0=Bistro 1=Track 2=Orders 3=Profile

  // Staff session
  String? staffId;
  String? staffName;

  late bool
      simulationMode; // business-wide once Firestore-synced — see class doc
  late String esp32Address; // device-local — see class doc
  String esp32ConnectionStatus =
      'UNKNOWN'; // UNKNOWN | CONNECTED | DISCONNECTED

  late String upiVpa; // business-wide once Firestore-synced
  late String upiPayeeName;
  bool get upiConfigured => upiVpa.trim().isNotEmpty;

  void setFirebaseAvailable(bool value) {
    firebaseAvailable = value;
    notifyListeners();
    if (value) _startAppConfigSync();
  }

  /// Subscribes to the shared Firestore config doc. Anyone's write (staff
  /// laptop, staff phone, even a passenger device if ever needed) shows up
  /// here live — this is what makes UPI details, backend URL and
  /// simulation mode consistent across every device instead of stuck on
  /// whichever one set them.
  void _startAppConfigSync() {
    _appConfigSub?.cancel();
    _appConfigSub = firestore.appConfigStream().listen((data) {
      if (data.containsKey('upiVpa')) upiVpa = data['upiVpa'] as String? ?? '';
      if (data.containsKey('upiPayeeName'))
        upiPayeeName = data['upiPayeeName'] as String? ?? '';
      if (data.containsKey('backendUrl')) {
        final remoteUrl = data['backendUrl'] as String?;
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          ApiService.baseUrl = remoteUrl;
        }
      }
      if (data.containsKey('simulationMode')) {
        final remoteValue = data['simulationMode'] as bool? ?? simulationMode;
        if (remoteValue != simulationMode) {
          _applySimulationMode(remoteValue, persistLocally: false);
        }
      }
      notifyListeners();
    }, onError: (_) {});
  }

  void loginPassenger({required String passengerId, required String mobile}) {
    role = UserRole.passenger;
    this.passengerId = passengerId;
    passengerMobile = mobile;
    notifyListeners();
  }

  void setCoachSeat(String coach, String seat) {
    coachNo = coach;
    seatNo = seat;
    settings.setLastCoachSeat(
        coach, seat); // so reopening the app remembers this
    notifyListeners();
  }

  void setActiveOrder(String orderId) {
    activeOrderId = orderId;
    passengerTabIndex = 1; // jump straight to the Track tab
    notifyListeners();
  }

  void setPassengerTab(int index) {
    passengerTabIndex = index;
    notifyListeners();
  }

  void clearActiveOrder() {
    activeOrderId = null;
    notifyListeners();
  }

  /// Used from Orders history — reopen a past/active order in the Track tab.
  void openOrderInTracking(String orderId) {
    activeOrderId = orderId;
    passengerTabIndex = 1;
    notifyListeners();
  }

  void loginStaff({required String staffId, required String name}) {
    role = UserRole.staff;
    this.staffId = staffId;
    staffName = name;
    notifyListeners();
  }

  void logout() {
    if (firebaseAvailable) {
      firebaseAuth.signOut().catchError((_) {});
    }
    settings.clearLastCoachSeat();
    role = UserRole.none;
    passengerId = null;
    passengerMobile = null;
    coachNo = null;
    seatNo = null;
    activeOrderId = null;
    passengerTabIndex = 0;
    staffId = null;
    staffName = null;
    notifyListeners();
  }

  /// Toggle from either Staff Settings or the Passenger Profile tab —
  /// both call this same method, and since it writes through Firestore
  /// when available, either one instantly updates every other device too.
  void toggleSimulation(bool value) {
    _applySimulationMode(value, persistLocally: true);
    if (firebaseAvailable) {
      firestore.updateAppConfig({'simulationMode': value}).catchError((_) {});
    }
  }

  void _applySimulationMode(bool value, {required bool persistLocally}) {
    simulationMode = value;
    if (persistLocally && !firebaseAvailable) {
      settings.setSimulationMode(value);
    }
    if (value) {
      api.disconnectWebSocket();
      simulation.start();
    } else {
      simulation.stop();
      api.connectWebSocket();
    }
    notifyListeners();
  }

  void setEsp32Address(String address) {
    esp32Address = address;
    settings.setEsp32Address(address);
    notifyListeners();
  }

  void setEsp32Status(String status) {
    esp32ConnectionStatus = status;
    notifyListeners();
  }

  /// Writes through Firestore when available so every device (including a
  /// passenger's phone) picks up the correct backend address automatically
  /// — see the class doc for why this had to change from device-local.
  void setBackendUrl(String url) {
    ApiService.baseUrl = url;
    if (firebaseAvailable) {
      firestore.updateAppConfig({'backendUrl': url}).catchError((_) {});
    } else {
      settings.setBackendUrl(url);
    }
    notifyListeners();
  }

  /// Called from Staff Settings. Writes through Firestore when available
  /// so every passenger device picks it up live — this is the fix for
  /// "I saved my UPI ID but payment screen shows nothing," which happened
  /// because the old version only saved to the staff device's own storage.
  void setUpiDetails({required String vpa, required String payeeName}) {
    upiVpa = vpa;
    upiPayeeName = payeeName;
    if (firebaseAvailable) {
      firestore.updateAppConfig(
          {'upiVpa': vpa, 'upiPayeeName': payeeName}).catchError((_) {});
    } else {
      settings.setUpiVpa(vpa);
      settings.setUpiPayeeName(payeeName);
    }
    notifyListeners();
  }

  /// Unified event stream regardless of mode — every *_State class listens
  /// to this single source.
  Stream<Map<String, dynamic>> get liveEvents =>
      simulationMode ? simulation.events : api.events;

  @override
  void dispose() {
    _appConfigSub?.cancel();
    super.dispose();
  }
}
