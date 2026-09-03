import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_header.dart';
import '../../state/cart_state.dart';
import '../../models/menu_item.dart';

class FoodDetailScreen extends StatefulWidget {
  final MenuItem item;
  const FoodDetailScreen({super.key, required this.item});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final qty = cart.quantityOf(widget.item.id);
    final item = widget.item;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cardBorder)),
                        child: const Icon(Icons.arrow_back_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const BrandHeader(compact: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: item.imageUrl != null
                            ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallback())
                            : _fallback(),
                      ),
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.card.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sell_rounded, size: 13, color: AppColors.primaryBright),
                            const SizedBox(width: 6),
                            Text('₹${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        InfoPill(label: '${item.prepMinutes} MINS PREP', color: AppColors.amber),
                        const SizedBox(width: 8),
                        InfoPill(label: item.category, color: AppColors.primaryBright),
                        if (!item.available) ...[
                          const SizedBox(width: 8),
                          const InfoPill(label: 'OUT OF STOCK', color: AppColors.red),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 18),
                    Text(item.description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14.5, height: 1.6)),
                    const SizedBox(height: 22),
                    const Text('DIETARY DETAILS', style: AppTheme.uppercaseLabel),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 8,
                      children: [
                        InfoPill(label: 'Vegetarian'),
                        InfoPill(label: 'Contains Dairy'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (item.available)
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: AppColors.cardBorder)),
                            child: Row(
                              children: [
                                _stepperBtn(Icons.remove_rounded, qty > 0 ? () => cart.remove(item.id) : null),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                ),
                                _stepperBtn(Icons.add_rounded, () => cart.add(item)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (qty == 0) cart.add(item);
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                              label: const Text('ADD TO CART'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 16, color: onTap == null ? AppColors.textMuted : AppColors.textPrimary),
        ),
      );

  Widget _fallback() => Container(
        color: AppColors.bgElevated,
        child: const Center(child: Icon(Icons.restaurant_rounded, color: AppColors.textMuted, size: 40)),
      );
}
