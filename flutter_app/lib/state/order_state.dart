import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import 'app_state.dart';

class OrderState extends ChangeNotifier {
  final AppState appState;
  List<Order> orders = [];
  StreamSubscription? _sub;
  StreamSubscription? _firestoreSub;
  bool? _lastSimulationMode;

  OrderState(this.appState) {
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
      // Simulation Mode is a complete, self-contained demo loop: orders
      // placed here, dispatch/marker/OTP events, and everything staff and
      // analytics see all flow through the same in-memory event stream —
      // independent of Firebase, so it works even with zero cloud setup,
      // AND (this is the fix) even once Firebase IS configured, since
      // simulated orders would otherwise never reach Firestore for staff
      // to see.
      orders = [];
      _sub = appState.liveEvents.listen(_onEvent);
    } else if (appState.firebaseAvailable) {
      _firestoreSub = appState.firestore.ordersStream().listen((liveOrders) {
        orders = liveOrders;
        notifyListeners();
      }, onError: (_) {});
    } else {
      _sub = appState.liveEvents.listen(_onEvent);
    }
    notifyListeners();
  }

  List<Order> get active => orders
      .where(
          (o) => o.orderStatus != 'DELIVERED' && o.orderStatus != 'CANCELLED')
      .toList();

  List<Order> ordersFor(String passengerId) =>
      orders.where((o) => o.passengerId == passengerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Order> byStatus(String status) =>
      orders.where((o) => o.orderStatus == status).toList();

  Future<void> refresh() async {
    if (appState.simulationMode || appState.firebaseAvailable) return;
    try {
      final raw = await appState.api.fetchOrders();
      orders = raw.map((e) => Order.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<Order> createOrder({
    required String passengerId,
    required String passengerName,
    required String coachNo,
    required String seatNo,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? ticketNumber,
  }) async {
    if (appState.simulationMode) {
      final order = _buildDemoOrder(
        passengerId: passengerId,
        passengerName: passengerName,
        coachNo: coachNo,
        seatNo: seatNo,
        items: items,
        paymentMethod: paymentMethod,
      );
      orders.insert(0, order);
      notifyListeners();
      return order;
    }
    final json = await appState.api.createOrder({
      'passengerId': passengerId,
      'passengerName': passengerName,
      'coachNo': coachNo,
      'seatNo': seatNo,
      'items': items,
      'paymentMethod': paymentMethod,
      if (ticketNumber != null) 'ticketNumber': ticketNumber,
    });
    final order = Order.fromJson(json);
    // When Firestore is live, the backend's write will arrive via the
    // ordersStream() listener within a moment — inserting here too would
    // just get overwritten by that snapshot, so skip it to avoid a flash
    // of duplicate state.
    if (!appState.firebaseAvailable) {
      orders.insert(0, order);
      notifyListeners();
    }
    return order;
  }

  Future<void> updateStatus(String orderId, String status,
      {String? robotId}) async {
    if (appState.simulationMode) {
      _applyStatus(orderId, status, robotId: robotId);
      return;
    }
    final json =
        await appState.api.updateOrderStatus(orderId, status, robotId: robotId);
    _applyOrder(Order.fromJson(json));
  }

  void _onEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'ORDER_CREATED':
      case 'ORDER_STATUS_UPDATED':
        _applyOrder(Order.fromJson(event['data']));
        break;
      case 'MARKER_DETECTED':
        // Only relevant in Simulation mode — the real backend already turns
        // a marker-detected event into an ORDER_STATUS_UPDATED broadcast
        // itself (see backend/app/routers/esp32.py), so this is a no-op
        // there. In Simulation mode there's no backend doing that, so we
        // apply the same rule here to keep behaviour identical.
        if (appState.simulationMode) {
          final data = event['data'];
          final orderId = data['orderId'] as String?;
          if (orderId != null) {
            _applyStatus(orderId, 'ARRIVED');
          }
        }
        break;
    }
  }

  void _applyOrder(Order order) {
    final idx = orders.indexWhere((o) => o.orderId == order.orderId);
    if (idx >= 0) {
      orders[idx] = order;
    } else {
      orders.insert(0, order);
    }
    notifyListeners();
  }

  void _applyStatus(String orderId, String status, {String? robotId}) {
    final idx = orders.indexWhere((o) => o.orderId == orderId);
    if (idx < 0) return;
    final old = orders[idx];
    String? otp = old.otp;
    // Generate the delivery OTP on DISPATCHED normally, but also as a
    // fallback on ARRIVED in case a demo skips straight to marker-detected
    // (e.g. the track-view "Dispatch" shortcut) without going through the
    // full staff-driven status flow first.
    if ((status == 'DISPATCHED' || status == 'ARRIVED') && otp == null) {
      otp = List.generate(6, (_) => Random().nextInt(10)).join();
    }
    orders[idx] = Order(
      orderId: old.orderId,
      authId: old.authId,
      passengerId: old.passengerId,
      passengerName: old.passengerName,
      coachNo: old.coachNo,
      seatNo: old.seatNo,
      items: old.items,
      totalAmount: old.totalAmount,
      paymentMethod: old.paymentMethod,
      paymentStatus: old.paymentStatus,
      orderStatus: status,
      preparationMinutes: old.preparationMinutes,
      estimatedDeliveryMinutes: old.estimatedDeliveryMinutes,
      robotId: robotId ?? old.robotId,
      otp: otp,
      otpVerified: status == 'OTP_VERIFIED' ? true : old.otpVerified,
      createdAt: old.createdAt,
    );
    notifyListeners();
  }

  Order _buildDemoOrder({
    required String passengerId,
    required String passengerName,
    required String coachNo,
    required String seatNo,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
  }) {
    final cartItems = items
        .map((e) => CartItem(
            foodId: e['foodId'],
            name: e['name'],
            quantity: e['quantity'],
            price: e['price']))
        .toList();
    final total = cartItems.fold<double>(0, (s, i) => s + i.lineTotal);
    final id = 'ORD-DEMO${Random().nextInt(9000) + 1000}';
    return Order(
      orderId: id,
      authId: 'AUTH-${Random().nextInt(900000) + 100000}',
      passengerId: passengerId,
      passengerName: passengerName,
      coachNo: coachNo,
      seatNo: seatNo,
      items: cartItems,
      totalAmount: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'UPI' ? 'PAID' : 'PENDING',
      orderStatus: 'PLACED',
      preparationMinutes: 12,
      estimatedDeliveryMinutes: 17,
      createdAt: DateTime.now().millisecondsSinceEpoch / 1000,
    );
  }

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    _sub?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }
}
