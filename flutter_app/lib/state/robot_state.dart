import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/robot.dart';
import 'app_state.dart';

class RobotState extends ChangeNotifier {
  final AppState appState;
  Map<String, Robot> robots = {
    'POD-01': Robot(robotId: 'POD-01', status: 'OFFLINE', activity: 'IDLE'),
  };
  String? lastMarkerCoach;
  String? lastMarkerSeat;
  StreamSubscription? _sub;
  StreamSubscription? _firestoreSub;
  bool? _lastSimulationMode;

  RobotState(this.appState) {
    appState.addListener(_onAppStateChanged);
    _resubscribe();
  }

  /// Simulation Mode can be toggled at any time (Staff Settings or
  /// Passenger Profile) — this makes sure flipping it actually switches
  /// where robot data comes from immediately, instead of staying stuck on
  /// whatever was chosen when the app first opened.
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
      // Simulation Mode is a complete, self-contained demo loop —
      // independent of Firebase — so the robot track / dispatch button
      // actually animates even with zero cloud connectivity.
      _sub = appState.liveEvents.listen(_onEvent);
      robots['POD-01'] = Robot(
        robotId: 'POD-01',
        ipAddress: '192.168.1.105',
        status: 'ONLINE',
        currentCoach: 'Pantry',
        activity: 'IDLE',
      );
      lastMarkerCoach = null;
      lastMarkerSeat = null;
      notifyListeners();
    } else if (appState.firebaseAvailable) {
      _firestoreSub = appState.firestore.robotsStream().listen((liveRobots) {
        for (final r in liveRobots) {
          robots[r.robotId] = _withFreshStatus(r);
          if (r.currentSeat != null) {
            lastMarkerCoach = r.currentCoach;
            lastMarkerSeat = r.currentSeat;
          }
        }
        notifyListeners();
      }, onError: (_) {});
    } else {
      _sub = appState.liveEvents.listen(_onEvent);
    }
  }

  /// Firestore only stores whatever `status` was last written — if a
  /// robot's heartbeat stopped hours ago, its doc can still say ONLINE
  /// forever unless something re-checks freshness. The backend already
  /// does this for REST reads (see store.py robot_is_online); this
  /// applies the same 15s-heartbeat-timeout rule client-side for the
  /// direct Firestore read path, so a never-started ESP32 doesn't show
  /// as falsely online.
  Robot _withFreshStatus(Robot r) {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000;
    final isStale = r.lastSeen == null || (nowSeconds - r.lastSeen!) > 15;
    return isStale ? r.copyWith(status: 'OFFLINE') : r;
  }

  Future<void> refresh() async {
    if (appState.simulationMode || appState.firebaseAvailable) return;
    try {
      final raw = await appState.api.fetchRobots();
      for (final r in raw) {
        final robot = Robot.fromJson(r);
        robots[robot.robotId] = robot;
      }
      notifyListeners();
    } catch (_) {}
  }

  void _onEvent(Map<String, dynamic> event) {
    if (event['type'] == 'ROBOT_UPDATED') {
      final data = event['data'];
      final id = data['robotId'];
      final existing = robots[id] ?? Robot(robotId: id);
      robots[id] = existing.copyWith(
        ipAddress: data['ipAddress'],
        status: data['status'],
        currentCoach: data['currentCoach'],
        currentSeat: data['currentSeat'],
        activity: data['activity'],
      );
      notifyListeners();
    } else if (event['type'] == 'MARKER_DETECTED') {
      lastMarkerCoach = event['data']['coachNo'];
      lastMarkerSeat = event['data']['seatNo'];
      notifyListeners();
    }
  }

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    _sub?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }
}
