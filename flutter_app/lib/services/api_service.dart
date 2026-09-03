import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Talks to the FastAPI backend. This is the ONLY class in the app that
/// knows an HTTP/WebSocket URL exists — everything else goes through
/// AppState/OrderState/etc so screens never call this directly.
class ApiService {
  /// Change for real deployment — e.g. the FastAPI machine's LAN IP on the
  /// train, or a Wi-Fi-configurable value read from local storage.
  static String baseUrl = 'http://localhost:8000';

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _controller.stream;

  void connectWebSocket() {
    final wsUrl = baseUrl.replaceFirst('http', 'ws') + '/ws';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        (raw) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          _controller.add(decoded);
        },
        onError: (_) {},
        onDone: () {},
      );
    } catch (_) {
      // Backend not reachable — Simulation mode should be used instead.
    }
  }

  void disconnectWebSocket() {
    _channel?.sink.close();
    _channel = null;
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> _get(String path) async {
    final res = await http.get(_u(path));
    return jsonDecode(res.body);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(_u(path),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (res.statusCode >= 400) {
      final err = jsonDecode(res.body);
      throw ApiException(err['detail']?.toString() ?? 'Request failed');
    }
    return jsonDecode(res.body);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(_u(path),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (res.statusCode >= 400) {
      final err = jsonDecode(res.body);
      throw ApiException(err['detail']?.toString() ?? 'Request failed');
    }
    return jsonDecode(res.body);
  }

  // ---- Auth ----
  Future<Map<String, dynamic>> requestPassengerOtp(String mobile) =>
      _post('/auth/passenger/request-otp', {'mobile': mobile}).then((r) => r);

  Future<Map<String, dynamic>> verifyPassengerOtp(String mobile, String otp) =>
      _post('/auth/passenger/verify-otp', {'mobile': mobile, 'otp': otp}).then((r) => r);

  Future<Map<String, dynamic>> staffLogin(String mobile, String password) =>
      _post('/auth/staff/login', {'mobile': mobile, 'password': password}).then((r) => r);

  // ---- Menu ----
  Future<List<dynamic>> fetchMenu() => _get('/menu').then((r) => r as List);

  Future<void> addMenuItem(Map<String, dynamic> item) => _post('/menu', item);

  Future<void> updateMenuItem(String id, Map<String, dynamic> patch) =>
      _patch('/menu/$id', patch);

  Future<void> deleteMenuItem(String id) async {
    await http.delete(_u('/menu/$id'));
  }

  // ---- Orders ----
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) =>
      _post('/orders', payload).then((r) => r);

  Future<List<dynamic>> fetchOrders({String? status}) =>
      _get('/orders${status != null ? '?status=$status' : ''}').then((r) => r as List);

  Future<List<dynamic>> fetchPassengerOrders(String passengerId) =>
      _get('/orders/passenger/$passengerId').then((r) => r as List);

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status,
          {String? robotId}) =>
      _patch('/orders/$orderId/status',
          {'orderStatus': status, if (robotId != null) 'robotId': robotId}).then((r) => r);

  // ---- Payments ----
  // UPI payments are built and shown entirely client-side (see
  // services/upi_service.dart) — nothing to call on the backend for that.
  Future<Map<String, dynamic>> verifyTicket(String ticketNumber, String coach, String seat) =>
      _post('/payments/ticket/verify',
          {'ticketNumber': ticketNumber, 'coachNo': coach, 'seatNo': seat}).then((r) => r);

  // ---- ESP32 / Robots ----
  Future<List<dynamic>> fetchRobots() => _get('/esp32/robots').then((r) => r as List);

  Future<Map<String, dynamic>> fetchRobot(String robotId) =>
      _get('/esp32/robots/$robotId').then((r) => r as Map<String, dynamic>);

  // ---- OTP ----
  Future<Map<String, dynamic>> verifyDeliveryOtp({
    required String orderId,
    required String authId,
    required String coachNo,
    required String seatNo,
    required String otp,
  }) =>
      _post('/otp/verify', {
        'orderId': orderId,
        'authId': authId,
        'coachNo': coachNo,
        'seatNo': seatNo,
        'otp': otp,
      }).then((r) => r);

  // ---- Security ----
  Future<List<dynamic>> fetchSecurityAlerts() => _get('/security').then((r) => r as List);

  Future<void> acknowledgeAlert(String alertId) =>
      _post('/security/$alertId/acknowledge', {});

  // ---- Analytics ----
  Future<Map<String, dynamic>> fetchAnalyticsSummary() =>
      _get('/analytics/summary').then((r) => r as Map<String, dynamic>);
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
