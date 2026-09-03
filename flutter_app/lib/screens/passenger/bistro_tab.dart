import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/category_pills.dart';
import '../../widgets/food_card.dart';
import '../../state/app_state.dart';
import '../../state/menu_state.dart';
import '../../state/cart_state.dart';
import 'food_detail_screen.dart';
import 'cart_screen.dart';

class BistroTab extends StatefulWidget {
  const BistroTab({super.key});

  @override
  State<BistroTab> createState() => _BistroTabState();
}

class _BistroTabState extends State<BistroTab> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final menuState = context.watch<MenuState>();
    final cart = context.watch<CartState>();

    final items = menuState.items.where((i) =>
        _selectedCategory == 'All' || i.category == _selectedCategory).toList();

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: BrandHeader(
                  trailing: InfoPill(label: 'Coach ${appState.coachNo} · Seat ${appState.seatNo}'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Gourmet Dining,\nDelivered to Your Seat.',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CategoryPillBar(
                  categories: menuState.categories,
                  selected: _selectedCategory,
                  onSelected: (c) => setState(() => _selectedCategory = c),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: menuState.loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, cart.isEmpty ? 20 : 90),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PassengerFoodCard(
                              item: item,
                              quantity: cart.quantityOf(item.id),
                              onAdd: () => cart.add(item),
                              onRemove: () => cart.remove(item.id),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => FoodDetailScreen(item: item)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        if (!cart.isEmpty)
          Positioned(
            left: 20, right: 20, bottom: 14,
            child: SafeArea(
              top: false,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: [
                      Text('${cart.itemList.fold<int>(0, (s, i) => s + i.quantity)} items',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('View Basket · ₹${cart.total.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
