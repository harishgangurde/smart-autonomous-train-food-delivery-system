import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/security_alert.dart';
import 'app_state.dart';

class SecurityState extends ChangeNotifier {
  final AppState appState;
  List<SecurityAlert> alerts = [];
  StreamSubscription? _sub;
  StreamSubscription? _firestoreSub;
  bool? _lastSimulationMode;

  SecurityState(this.appState) {
    appState.addListener(_onAppStateChanged);
    _resubscribe();
  }

  void _onAppStateChanged() {
    if (_lastSimulationMode != appState.simulationMode) {
      _resubscribe();
    }
  }

  void _resubscribe() {
    _sub?.cancel();
    _firestoreSub?.cancel();
    _lastSimulationMode = appState.simulationMode;

    if (appState.simulationMode) {
      // "Simulate Alert" in the Alerts tab emits onto this same event
      // stream — this is what makes it actually show up and sound the
      // siren, instead of firing into a stream nobody's listening to.
      _sub = appState.liveEvents.listen(_onEvent);
    } else if (appState.firebaseAvailable) {
      _firestoreSub =
          appState.firestore.securityAlertsStream().listen((liveAlerts) {
        alerts = liveAlerts;
        notifyListeners();
      }, onError: (_) {});
    } else {
      _sub = appState.liveEvents.listen(_onEvent);
    }
  }

  List<SecurityAlert> get activeAlerts =>
      alerts.where((a) => a.status == 'ACTIVE').toList();

  void _onEvent(Map<String, dynamic> event) {
    if (event['type'] == 'SECURITY_ALERT') {
      alerts.insert(0, SecurityAlert.fromJson(event['data']));
      notifyListeners();
    } else if (event['type'] == 'SECURITY_ALERT_ACK') {
      final updated = SecurityAlert.fromJson(event['data']);
      final idx = alerts.indexWhere((a) => a.alertId == updated.alertId);
      if (idx >= 0) alerts[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> acknowledge(String alertId) async {
    if (appState.simulationMode) {
      final idx = alerts.indexWhere((a) => a.alertId == alertId);
      if (idx >= 0) {
        final a = alerts[idx];
        alerts[idx] = SecurityAlert(
          alertId: a.alertId,
          robotId: a.robotId,
          coachNo: a.coachNo,
          alertType: a.alertType,
          timestamp: a.timestamp,
          status: 'ACKNOWLEDGED',
          acknowledgedBy: appState.staffId,
        );
        notifyListeners();
      }
      return;
    }
    // Not simulating — always write through the backend, whether it's
    // persisting to Firestore (which the listener above will reflect
    // automatically) or to its in-memory fallback.
    try {
      await appState.api.acknowledgeAlert(alertId);
    } catch (_) {}
  }

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    _sub?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }
}
