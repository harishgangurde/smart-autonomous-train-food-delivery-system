import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import 'app_state.dart';

class MenuState extends ChangeNotifier {
  final AppState appState;
  List<MenuItem> items = [];
  StreamSubscription? _sub;
  StreamSubscription? _firestoreSub;
  bool loading = false;

  MenuState(this.appState) {
    if (appState.firebaseAvailable) {
      _listenFirestore();
    } else {
      _sub = appState.liveEvents.listen(_onEvent);
      load();
    }
  }

  void _listenFirestore() {
    loading = true;
    notifyListeners();
    _firestoreSub = appState.firestore.menuStream().listen((liveItems) {
      items = liveItems;
      loading = false;
      notifyListeners();
    }, onError: (_) {
      loading = false;
      items = _demoMenu();
      notifyListeners();
    });
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      if (appState.simulationMode) {
        items = _demoMenu();
      } else {
        final raw = await appState.api.fetchMenu();
        items = raw.map((e) => MenuItem.fromJson(e)).toList();
      }
    } catch (_) {
      items = _demoMenu(); // graceful fallback if backend unreachable
    }
    loading = false;
    notifyListeners();
  }

  void _onEvent(Map<String, dynamic> event) {
    if (event['type'] == 'MENU_UPDATED') {
      final updated = MenuItem.fromJson(event['data']['item']);
      final idx = items.indexWhere((i) => i.id == updated.id);
      if (idx >= 0) {
        items[idx] = updated;
      } else {
        items.add(updated);
      }
      notifyListeners();
    } else if (event['type'] == 'MENU_ITEM_DELETED') {
      items.removeWhere((i) => i.id == event['data']['itemId']);
      notifyListeners();
    }
  }

  Future<void> toggleAvailability(MenuItem item) async {
    final updated = item.copyWith(available: !item.available);
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) items[idx] = updated;
    notifyListeners();
    // Writes always go through the backend (which persists to the same
    // store Firestore reads from) whenever a real backend is reachable —
    // independent of the ESP32/robot simulation toggle.
    if (appState.firebaseAvailable || !appState.simulationMode) {
      try {
        await appState.api.updateMenuItem(item.id, {'available': updated.available});
      } catch (_) {}
    }
  }

  List<String> get categories => items.map((e) => e.category).toSet().toList();

  @override
  void dispose() {
    _sub?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }

  static List<MenuItem> _demoMenu() => [
        MenuItem(
            id: 'food_001',
            name: 'Margherita Pizza',
            price: 180,
            category: 'Main',
            description: 'Classic cheese & tomato',
            prepMinutes: 15,
            imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002'),
        MenuItem(
            id: 'food_002',
            name: 'Veg Burger',
            price: 120,
            category: 'Main',
            description: 'Crispy patty, fresh veg',
            available: false,
            prepMinutes: 10,
            imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd'),
        MenuItem(
            id: 'food_003',
            name: 'Cold Drink',
            price: 50,
            category: 'Beverage',
            description: 'Chilled 300ml',
            prepMinutes: 1,
            imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97'),
        MenuItem(
            id: 'food_004',
            name: 'Veg Sandwich',
            price: 100,
            category: 'Snack',
            description: 'Grilled, triple layer',
            prepMinutes: 8,
            imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af'),
        MenuItem(
            id: 'food_005',
            name: 'Masala Chai',
            price: 30,
            category: 'Beverage',
            description: 'Hot ginger tea',
            prepMinutes: 4,
            imageUrl: 'https://images.unsplash.com/photo-1597318181409-cf64d0b5d8ee'),
      ];
}
