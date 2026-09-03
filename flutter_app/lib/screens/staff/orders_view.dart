import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../state/order_state.dart';
import '../../state/robot_state.dart';
import '../../models/order.dart';
import 'widgets/order_card.dart';

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  static const _columns = [
    ('PLACED', 'New Orders', Icons.inbox_rounded, AppColors.textSecondary),
    ('CONFIRMED', 'Confirmed', Icons.check_circle_outline_rounded, AppColors.primary),
    ('PREPARING', 'Preparing', Icons.soup_kitchen_rounded, AppColors.amber),
    ('READY', 'Ready', Icons.done_all_rounded, AppColors.green),
    ('DISPATCHED', 'Out for Delivery', Icons.local_shipping_rounded, AppColors.primaryBright),
  ];

  @override
  Widget build(BuildContext context) {
    final orderState = context.watch<OrderState>();
    final robotState = context.watch<RobotState>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIVE ORDERS', style: AppTheme.uppercaseLabel),
          const SizedBox(height: 4),
          const Text('Kitchen & Delivery Board', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              for (final (status, label, icon, color) in _columns)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: color),
                      const SizedBox(width: 8),
                      Text('${orderState.byStatus(status).length}',
                          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(width: 6),
                      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1000;
                if (!isWide) {
                  return DefaultTabController(
                    length: _columns.length,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          labelColor: AppColors.primaryBright,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          tabs: [for (final c in _columns) Tab(text: c.$2)],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              for (final c in _columns)
                                _OrderColumnList(status: c.$1, orderState: orderState, robotState: robotState),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (status, label, icon, color) in _columns)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: _OrderColumn(status: status, label: label, color: color,
                              orderState: orderState, robotState: robotState),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderColumn extends StatelessWidget {
  final String status, label;
  final Color color;
  final OrderState orderState;
  final RobotState robotState;
  const _OrderColumn({required this.status, required this.label, required this.color,
      required this.orderState, required this.robotState});

  @override
  Widget build(BuildContext context) {
    final orders = orderState.byStatus(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: orders.isEmpty
              ? Center(child: Text('No orders', style: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 12)))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCard(context, orders[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, Order order) {
    switch (status) {
      case 'PLACED':
        return OrderCard(order: order, primaryLabel: 'CONFIRM ORDER',
            onPrimaryAction: () => orderState.updateStatus(order.orderId, 'CONFIRMED'));
      case 'CONFIRMED':
        return OrderCard(order: order, primaryLabel: 'START PREPARING',
            onPrimaryAction: () => orderState.updateStatus(order.orderId, 'PREPARING'));
      case 'PREPARING':
        return OrderCard(order: order, primaryLabel: 'MARK READY',
            onPrimaryAction: () => orderState.updateStatus(order.orderId, 'READY'));
      case 'READY':
        return OrderCard(order: order, primaryLabel: 'LOAD & DISPATCH ROBOT',
            onPrimaryAction: () => orderState.updateStatus(order.orderId, 'DISPATCHED', robotId: 'POD-01'));
      case 'DISPATCHED':
        return OrderCard(order: order);
      default:
        return OrderCard(order: order);
    }
  }
}

class _OrderColumnList extends StatelessWidget {
  final String status;
  final OrderState orderState;
  final RobotState robotState;
  const _OrderColumnList({required this.status, required this.orderState, required this.robotState});

  @override
  Widget build(BuildContext context) {
    final col = _OrderColumn(status: status, label: '', color: AppColors.primary,
        orderState: orderState, robotState: robotState);
    final orders = orderState.byStatus(status);
    return orders.isEmpty
        ? const Center(child: Text('No orders', style: TextStyle(color: AppColors.textMuted)))
        : ListView.builder(
            padding: const EdgeInsets.only(top: 12),
            itemCount: orders.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: col._buildCard(context, orders[i]),
            ),
          );
  }
}
