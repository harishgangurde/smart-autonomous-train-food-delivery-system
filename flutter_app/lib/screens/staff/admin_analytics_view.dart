import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../state/app_state.dart';
import '../../state/order_state.dart';
import '../../state/robot_state.dart';
import '../../models/order.dart';

class AdminAnalyticsView extends StatelessWidget {
  const AdminAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.simulationMode) {
      return const _SimulatedAnalytics();
    }
    return const _LiveAnalytics();
  }
}

/// A clean, illustrative demo view — deliberately NOT tied to real
/// simulated-order data, since the point is to always look good for a
/// demo the instant Simulation Mode is on, without needing anyone to
/// place test orders first. Bars rise once when the tab is first opened.
class _SimulatedAnalytics extends StatefulWidget {
  const _SimulatedAnalytics();

  @override
  State<_SimulatedAnalytics> createState() => _SimulatedAnalyticsState();
}

class _SimulatedAnalyticsState extends State<_SimulatedAnalytics>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward(); // runs once, doesn't repeat

  static const _hourlyValues = [22, 35, 48, 40, 55, 70, 62, 80, 74, 58, 46, 30];
  static const _labels = [
    '00h',
    '02h',
    '04h',
    '06h',
    '08h',
    '10h',
    '12h',
    '14h',
    '16h',
    '18h',
    '20h',
    '22h'
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final robotState = context.watch<RobotState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child:
                      Text('CENTRAL COMMAND', style: AppTheme.uppercaseLabel)),
              const StatusBadge(label: 'SIMULATED', color: AppColors.amber),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Railway Fleet Analytics',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Robot Simulation Mode is on — these are illustrative demo numbers, not real orders. '
            'Switch to Live Mode in Settings for real data.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > 800;
            final cards = [
              const StatCard(
                  label: 'Deliveries Today',
                  value: '142',
                  subLabel: '↑ 18% vs Yesterday',
                  accent: AppColors.green),
              const StatCard(
                  label: 'Avg Delivery Duration',
                  value: '3.4 Min',
                  subLabel: 'Placed → Delivered',
                  accent: AppColors.primaryBright),
              const StatCard(
                  label: 'Fleet Efficiency',
                  value: '99.4%',
                  subLabel: '2 robots online',
                  accent: AppColors.green),
              const StatCard(
                  label: 'Revenue Today',
                  value: '₹34,820',
                  subLabel: '38 orders today',
                  accent: AppColors.amber),
            ];
            return wide
                ? Row(children: [
                    for (final c in cards)
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: c))
                  ])
                : Wrap(spacing: 14, runSpacing: 14, children: [
                    for (final c in cards)
                      SizedBox(width: (constraints.maxWidth - 14) / 2, child: c)
                  ]);
          }),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > 800;
            final chart = _buildChart();
            final fleet = _FleetStatusCard(robotState: robotState);
            return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 2, child: chart),
                    const SizedBox(width: 14),
                    Expanded(child: fleet),
                  ])
                : Column(children: [chart, const SizedBox(height: 14), fleet]);
          }),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final maxV = _hourlyValues.reduce((a, b) => a > b ? a : b);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('ORDERS / HOUR — LAST 12H',
                      style: AppTheme.uppercaseLabel)),
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.amber, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('SIMULATED',
                  style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < _hourlyValues.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Builder(builder: (context) {
                            // Staggers each bar's rise slightly so they
                            // don't all pop up in lockstep — a small
                            // per-bar delay/curve slice of the single
                            // one-shot controller.
                            final start = (i / _hourlyValues.length) * 0.6;
                            final end = start + 0.4;
                            final t = Curves.easeOutCubic.transform(
                              ((_controller.value - start) / (end - start))
                                  .clamp(0.0, 1.0),
                            );
                            return Container(
                              height: 140 * (_hourlyValues[i] / maxV) * t,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.9),
                                    AppColors.primaryBright.withOpacity(0.5)
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final l in _labels)
                Expanded(
                    child: Text(l,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 9))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Real data view for Live Mode — every number computed from actual
/// orders in OrderState, updating live as new ones arrive.
class _LiveAnalytics extends StatelessWidget {
  const _LiveAnalytics();

  @override
  Widget build(BuildContext context) {
    final orderState = context.watch<OrderState>();
    final robotState = context.watch<RobotState>();
    final orders = orderState.orders;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final ordersToday = orders.where((o) =>
        DateTime.fromMillisecondsSinceEpoch((o.createdAt * 1000).toInt())
            .isAfter(todayStart));

    final deliveredToday =
        ordersToday.where((o) => o.orderStatus == 'DELIVERED').toList();
    final revenueToday = ordersToday
        .where((o) => o.paymentStatus == 'PAID')
        .fold<double>(0, (s, o) => s + o.totalAmount);

    final avgDurationLabel = deliveredToday.isEmpty
        ? '—'
        : '${_estimateAvgMinutes(deliveredToday)} Min';

    final activeOrders = orders
        .where(
            (o) => o.orderStatus != 'DELIVERED' && o.orderStatus != 'CANCELLED')
        .length;
    final totalOrdersAllTime = orders.isEmpty ? 1 : orders.length;
    final deliveredAllTime =
        orders.where((o) => o.orderStatus == 'DELIVERED').length;
    final efficiency =
        orders.isEmpty ? 0.0 : (deliveredAllTime / totalOrdersAllTime) * 100;

    final podsActive =
        robotState.robots.values.where((r) => r.status == 'ONLINE').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child:
                      Text('CENTRAL COMMAND', style: AppTheme.uppercaseLabel)),
              const StatusBadge(label: 'LIVE', color: AppColors.green),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Railway Fleet Analytics',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > 800;
            final cards = [
              StatCard(
                  label: 'Deliveries Today',
                  value: '${deliveredToday.length}',
                  subLabel: '$activeOrders active now',
                  accent: AppColors.green),
              StatCard(
                  label: 'Avg Delivery Duration',
                  value: avgDurationLabel,
                  subLabel: 'Placed → Delivered',
                  accent: AppColors.primaryBright),
              StatCard(
                  label: 'Fleet Efficiency',
                  value: '${efficiency.toStringAsFixed(1)}%',
                  subLabel:
                      '$podsActive robot${podsActive == 1 ? '' : 's'} online',
                  accent: AppColors.green),
              StatCard(
                  label: 'Revenue Today',
                  value: '₹${revenueToday.toStringAsFixed(0)}',
                  subLabel: '${ordersToday.length} orders today',
                  accent: AppColors.amber),
            ];
            return wide
                ? Row(children: [
                    for (final c in cards)
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: c))
                  ])
                : Wrap(spacing: 14, runSpacing: 14, children: [
                    for (final c in cards)
                      SizedBox(width: (constraints.maxWidth - 14) / 2, child: c)
                  ]);
          }),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > 800;
            final chart = _DeliveryTrendChart(orders: orders);
            final fleet = _FleetStatusCard(robotState: robotState);
            return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 2, child: chart),
                    const SizedBox(width: 14),
                    Expanded(child: fleet),
                  ])
                : Column(children: [chart, const SizedBox(height: 14), fleet]);
          }),
        ],
      ),
    );
  }

  static String _estimateAvgMinutes(List<Order> delivered) {
    if (delivered.isEmpty) return '0';
    final avg = delivered
            .map((o) => o.estimatedDeliveryMinutes)
            .reduce((a, b) => a + b) /
        delivered.length;
    return avg.toStringAsFixed(1);
  }
}

class _DeliveryTrendChart extends StatelessWidget {
  final List<Order> orders;
  const _DeliveryTrendChart({required this.orders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buckets = List<int>.filled(12, 0);
    final labels = List<String>.filled(12, '');

    for (int i = 0; i < 12; i++) {
      final hour = now.subtract(Duration(hours: 11 - i));
      labels[i] = '${hour.hour.toString().padLeft(2, '0')}h';
    }

    for (final order in orders) {
      final created =
          DateTime.fromMillisecondsSinceEpoch((order.createdAt * 1000).toInt());
      final hoursAgo = now.difference(created).inHours;
      if (hoursAgo >= 0 && hoursAgo < 12) {
        buckets[11 - hoursAgo]++;
      }
    }

    final maxV = buckets.fold(0, (a, b) => a > b ? a : b);
    final hasData = maxV > 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('ORDERS / HOUR — LAST 12H',
                      style: AppTheme.uppercaseLabel)),
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('LIVE',
                  style: TextStyle(
                      color: AppColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: hasData
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < 12; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (buckets[i] > 0)
                                  Text('${buckets[i]}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted)),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: buckets[i] == 0
                                      ? 2
                                      : 130 * (buckets[i] / maxV),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.9),
                                        AppColors.primaryBright.withOpacity(0.5)
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: Text(
                        'No orders yet — this chart fills in as real orders arrive.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ),
          ),
          if (hasData) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (final l in labels)
                  Expanded(
                      child: Text(l,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 9))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FleetStatusCard extends StatelessWidget {
  final dynamic robotState;
  const _FleetStatusCard({required this.robotState});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FLEET STATUS', style: AppTheme.uppercaseLabel),
          const SizedBox(height: 16),
          for (final robot in robotState.robots.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.smart_toy_rounded,
                      size: 18,
                      color: robot.status == 'ONLINE'
                          ? AppColors.green
                          : AppColors.red),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(robot.robotId,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13))),
                  StatusBadge(
                      label: robot.status,
                      color: robot.status == 'ONLINE'
                          ? AppColors.green
                          : AppColors.red),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
