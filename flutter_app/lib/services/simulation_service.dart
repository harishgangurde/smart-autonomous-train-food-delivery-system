import 'dart:async';
import 'dart:math';

/// Generates fake events with EXACTLY the same shape the real backend sends
/// over its WebSocket ({"type": ..., "data": {...}}), so every screen can
/// stay identical whether Simulation or Live mode is active.
///
/// This does not replace the backend contract — it's a scripted stand-in for
/// demos without hardware in the room.
class SimulationService {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _controller.stream;

  Timer? _timer;
  final _rand = Random();
  int _tick = 0;

  static const coaches = ['Pantry', 'B1', 'B2', 'S1', 'S2'];
  static const seatFlow = [
    3,
    7,
    11,
    14
  ]; // fake marker path within destination coach

  String _demoOrderId = 'ORD-DEMO1';
  String _demoAuthId = 'AUTH-DEMO01';
  String _demoCoach = 'B2';
  String _demoSeat = '14';
  int _seatCursor = 0;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _tick_());
  }

  void stop() {
    _timer?.cancel();
  }

  void dispose() {
    stop();
    _controller.close();
  }

  void _emit(String type, Map<String, dynamic> data) {
    _controller.add({'type': type, 'data': data});
  }

  /// Kick off a full simulated order lifecycle: robot leaves pantry, moves
  /// seat by seat, "detects" the marker at the destination, then delivers.
  void simulateOrderLifecycle({
    required String orderId,
    required String authId,
    required String coachNo,
    required String seatNo,
  }) {
    _demoOrderId = orderId;
    _demoAuthId = authId;
    _demoCoach = coachNo;
    _demoSeat = seatNo;
    _seatCursor = 0;

    _emit('ROBOT_UPDATED', {
      'robotId': 'POD-01',
      'ipAddress': '192.168.1.105',
      'status': 'ONLINE',
      'currentCoach': 'Pantry',
      'currentSeat': null,
      'activity': 'MOVING',
    });

    var delay = const Duration(seconds: 1);
    for (final coach in ['B1', 'B2']) {
      Timer(delay, () {
        _emit('ROBOT_UPDATED', {
          'robotId': 'POD-01',
          'ipAddress': '192.168.1.105',
          'status': 'ONLINE',
          'currentCoach': coach,
          'currentSeat': null,
          'activity': 'MOVING',
        });
      });
      delay += const Duration(seconds: 2);
    }

    Timer(delay, () {
      _emit('MARKER_DETECTED', {
        'robotId': 'POD-01',
        'coachNo': coachNo,
        'seatNo': seatNo,
        'markerId': '$coachNo-S$seatNo',
        'orderId': orderId,
      });
    });
  }

  void _tick_() {
    _tick++;
    // Occasional heartbeat-style robot ping so "last seen" stays fresh.
    if (_tick % 2 == 0) {
      _emit('ROBOT_UPDATED', {
        'robotId': 'POD-01',
        'ipAddress': '192.168.1.105',
        'status': 'ONLINE',
        'currentCoach': _demoCoach,
        'activity': 'IDLE',
      });
    }
  }

  /// Simulated security alert for demo purposes — real one comes from ESP32.
  void triggerFakeSecurityAlert() {
    _emit('SECURITY_ALERT', {
      'alertId': 'ALERT-${_rand.nextInt(9999)}',
      'robotId': 'POD-01',
      'coachNo': _demoCoach,
      'alertType': 'UNAUTHORIZED_MOVEMENT',
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
      'status': 'ACTIVE',
    });
  }

  /// Standalone robot movement for the Robot Track demo controls — walks
  /// the robot coach-by-coach along [path] with a short delay between
  /// each stop, independent of any order. Used for the manual "Dispatch
  /// to X" / "Recall to Pantry" buttons in Simulation Mode, which should
  /// work even with zero orders placed.
  Future<void> moveRobotAlong(List<String> path, {String? finalSeat}) async {
    for (int i = 0; i < path.length; i++) {
      final isLast = i == path.length - 1;
      _emit('ROBOT_UPDATED', {
        'robotId': 'POD-01',
        'ipAddress': '192.168.1.105',
        'status': 'ONLINE',
        'currentCoach': path[i],
        'currentSeat': (isLast ? finalSeat : null),
        'activity': isLast ? 'IDLE' : 'MOVING',
      });
      if (!isLast) await Future.delayed(const Duration(milliseconds: 900));
    }
    if (finalSeat != null) {
      _emit('MARKER_DETECTED', {
        'robotId': 'POD-01',
        'coachNo': path.last,
        'seatNo': finalSeat,
        'markerId': '${path.last}-S$finalSeat',
        'orderId': null,
      });
    }
  }
}
