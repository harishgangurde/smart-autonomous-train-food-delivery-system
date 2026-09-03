import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_header.dart';
import '../../state/app_state.dart';
import '../../state/order_state.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final orderState = context.watch<OrderState>();
    final orders = orderState.ordersFor(appState.passengerId ?? '');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandHeader(),
            const SizedBox(height: 20),
            const Text('Order History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Expanded(
              child: orders.isEmpty
                  ? const Center(
                      child: Text('No orders yet', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, i) {
                        final order = orders[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => context.read<AppState>().openOrderInTracking(order.orderId),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('#${order.orderId}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Text(order.items.map((e) => '${e.name} x${e.quantity}').join(', '),
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        Text('₹${order.totalAmount.toStringAsFixed(0)}',
                                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryBright)),
                                      ],
                                    ),
                                  ),
                                  InfoPill(label: order.orderStatus, color: statusColor(order.orderStatus)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
