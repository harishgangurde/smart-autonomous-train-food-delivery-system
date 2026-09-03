import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class CartState extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;
  List<CartItem> get itemList => _items.values.toList();
  bool get isEmpty => _items.isEmpty;

  int quantityOf(String foodId) => _items[foodId]?.quantity ?? 0;

  double get subtotal => _items.values.fold(0, (sum, i) => sum + i.lineTotal);
  double get taxes => subtotal * 0.05;
  double get total => subtotal + taxes;

  void add(MenuItem item) {
    if (!item.available) return;
    if (_items.containsKey(item.id)) {
      _items[item.id]!.quantity++;
    } else {
      _items[item.id] = CartItem(
        foodId: item.id,
        name: item.name,
        quantity: 1,
        price: item.price,
      );
    }
    notifyListeners();
  }

  void remove(String foodId) {
    if (!_items.containsKey(foodId)) return;
    if (_items[foodId]!.quantity <= 1) {
      _items.remove(foodId);
    } else {
      _items[foodId]!.quantity--;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
