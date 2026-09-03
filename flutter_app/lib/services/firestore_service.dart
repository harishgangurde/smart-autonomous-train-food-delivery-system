import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/robot.dart';
import '../models/security_alert.dart';

/// Direct Firestore access for real-time reads. Collection names and field
/// shapes match backend/app/models/schemas.py exactly (the backend writes
/// via firebase-admin using the same `.model_dump()` field names), so the
/// same documents are readable from both Flutter and FastAPI/ESP32.
///
/// Writes for menu/orders still go through the FastAPI REST API (see
/// api_service.dart) so business logic like prep-time calculation and OTP
/// generation stays centralized in one place — this class is read-focused,
/// giving screens a live stream on top of whatever wrote the data.
class FirestoreService {
  // Same reasoning as FirebaseAuthService._auth — a getter, not an eager
  // field, so constructing this class never touches Firebase until a
  // stream is actually subscribed to.
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<List<MenuItem>> menuStream() {
    return _db.collection('menu').snapshots().map(
          (snap) => snap.docs.map((d) => MenuItem.fromJson(d.data())).toList(),
        );
  }

  Stream<List<Order>> ordersStream() {
    return _db.collection('orders').snapshots().map(
          (snap) => snap.docs.map((d) => Order.fromJson(d.data())).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Stream<List<Order>> passengerOrdersStream(String passengerId) {
    return _db
        .collection('orders')
        .where('passengerId', isEqualTo: passengerId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Order.fromJson(d.data())).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<List<Robot>> robotsStream() {
    return _db.collection('robots').snapshots().map(
          (snap) => snap.docs.map((d) => Robot.fromJson(d.data())).toList(),
        );
  }

  Stream<List<SecurityAlert>> securityAlertsStream() {
    return _db.collection('security_alerts').snapshots().map(
          (snap) =>
              snap.docs.map((d) => SecurityAlert.fromJson(d.data())).toList()
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        );
  }

  // ---- App-wide config (UPI details, simulation mode) ----
  //
  // These are business-wide settings, not per-device ones — if staff sets
  // the UPI ID once, every passenger's phone needs to see it too. That's
  // why these live in Firestore instead of SharedPreferences (which is
  // local to one browser/device and never syncs). ESP32 IP and backend
  // URL stay device-local on purpose (see settings_service.dart) since
  // those genuinely differ per device/network.
  static const _appConfigDocPath = ('app_config', 'main');

  Stream<Map<String, dynamic>> appConfigStream() {
    return _db
        .collection(_appConfigDocPath.$1)
        .doc(_appConfigDocPath.$2)
        .snapshots()
        .map(
          (doc) => doc.data() ?? {},
        );
  }

  Future<void> updateAppConfig(Map<String, dynamic> patch) {
    return _db.collection(_appConfigDocPath.$1).doc(_appConfigDocPath.$2).set(
          patch,
          SetOptions(merge: true),
        );
  }
}
