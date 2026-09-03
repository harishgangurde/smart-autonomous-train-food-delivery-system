import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../state/cart_state.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: GridBackground(
        child: SafeArea(
          child: cart.isEmpty
              ? const Center(
                  child: Text('Your cart is empty', style: TextStyle(color: AppColors.textSecondary)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          GlassCard(
                            child: Column(
                              children: [
                                for (final item in cart.itemList) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text('${item.name} × ${item.quantity}',
                                            style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ),
                                      Text('₹${item.lineTotal.toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                const Divider(),
                                _row('Subtotal', cart.subtotal),
                                _row('Taxes (5%)', cart.taxes),
                                const Divider(),
                                _row('Total', cart.total, bold: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaymentScreen()),
                          ),
                          child: const Text('PROCEED TO PAYMENT'),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                fontSize: bold ? 16 : 14)),
            Text('₹${value.toStringAsFixed(0)}', style: TextStyle(
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 16 : 14)),
          ],
        ),
      );
}
