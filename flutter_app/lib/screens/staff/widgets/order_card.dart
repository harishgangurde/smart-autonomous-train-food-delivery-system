import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onPrimaryAction;
  final String? primaryLabel;

  const OrderCard({
    super.key,
    required this.order,
    this.onPrimaryAction,
    this.primaryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(order.orderStatus);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 24, spreadRadius: -6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: color),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('#${order.orderId}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (order.paymentStatus == 'PAID' ? AppColors.green : AppColors.amber).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(order.paymentStatus,
                          style: TextStyle(
                              color: order.paymentStatus == 'PAID' ? AppColors.green : AppColors.amber,
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _pill(Icons.train_rounded, 'Coach ${order.coachNo}'),
                    const SizedBox(width: 8),
                    _pill(Icons.event_seat_rounded, 'Seat ${order.seatNo}'),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in order.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('${item.name} × ${item.quantity}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: color),
                        const SizedBox(width: 4),
                        Text('${order.preparationMinutes} min',
                            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                if (onPrimaryAction != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onPrimaryAction,
                      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                      child: Text(primaryLabel ?? 'CONFIRM ORDER'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
