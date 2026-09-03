import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../state/robot_state.dart';
import '../../state/order_state.dart';
import '../../state/app_state.dart';
import '../../models/order.dart';

const _coaches = ['Pantry', 'B1', 'B2', 'S1', 'S2'];
const _seatsPerCoach = 16;

class RobotTrackView extends StatefulWidget {
  const RobotTrackView({super.key});

  @override
  State<RobotTrackView> createState() => _RobotTrackViewState();
}

class _RobotTrackViewState extends State<RobotTrackView> {
  // Manual demo target, used only in Simulation Mode — lets staff see the
  // robot actually move without needing a real (or even simulated) order
  // to exist first.
  String _simDestCoach = 'B2';
  String _simDestSeat = '13';
  bool _dispatching = false;

  Future<void> _simDispatch(AppState appState, RobotState robotState) async {
    setState(() => _dispatching = true);
    final currentCoach = robotState.robots['POD-01']?.currentCoach ?? 'Pantry';
    final startIdx =
        _coaches.indexOf(currentCoach).clamp(0, _coaches.length - 1);
    final endIdx =
        _coaches.indexOf(_simDestCoach).clamp(0, _coaches.length - 1);
    final path = [
      for (int i = startIdx; i != endIdx; i += (endIdx > startIdx ? 1 : -1))
        _coaches[i],
      _coaches[endIdx],
    ];
    await appState.simulation.moveRobotAlong(path, finalSeat: _simDestSeat);
    if (mounted) setState(() => _dispatching = false);
  }

  Future<void> _simRecall(AppState appState, RobotState robotState) async {
    setState(() => _dispatching = true);
    final currentCoach = robotState.robots['POD-01']?.currentCoach ?? 'Pantry';
    final startIdx =
        _coaches.indexOf(currentCoach).clamp(0, _coaches.length - 1);
    final path = [
      for (int i = startIdx; i > 0; i--) _coaches[i],
      _coaches[0],
    ];
    await appState.simulation.moveRobotAlong(path);
    if (mounted) setState(() => _dispatching = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final robotState = context.watch<RobotState>();
    final orderState = context.watch<OrderState>();
    final robot = robotState.robots['POD-01'];

    if (appState.simulationMode) {
      return _buildSimulationView(context, appState, robotState, robot);
    }
    return _buildLiveView(context, robotState, orderState, robot);
  }

  // ---------- Simulation Mode: manual, always-interactive demo ----------

  Widget _buildSimulationView(BuildContext context, AppState appState,
      RobotState robotState, dynamic robot) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('OVERHEAD TRACK SYSTEM',
                      style: AppTheme.uppercaseLabel)),
              const StatusBadge(label: 'SIMULATED', color: AppColors.amber),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Live robot fleet position',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          GlassCard(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                _infoBlock('CURRENT LOCATION',
                    robot?.currentCoach ?? 'Pantry Coach', AppColors.primary),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: _simDestCoach,
                    decoration: const InputDecoration(
                        labelText: 'Dest. Coach', isDense: true),
                    items: [
                      for (final c in _coaches.skip(1))
                        DropdownMenuItem(value: c, child: Text(c))
                    ],
                    onChanged: (v) =>
                        setState(() => _simDestCoach = v ?? _simDestCoach),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: _simDestSeat,
                    decoration:
                        const InputDecoration(labelText: 'Seat', isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _simDestSeat = v,
                  ),
                ),
                ElevatedButton(
                  onPressed: _dispatching
                      ? null
                      : () => _simDispatch(appState, robotState),
                  child: Text('DISPATCH TO $_simDestCoach-$_simDestSeat'),
                ),
                OutlinedButton(
                  onPressed: _dispatching
                      ? null
                      : () => _simRecall(appState, robotState),
                  child: const Text('RECALL TO PANTRY'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      '↔  OVERHEAD MONORAIL TRACK SYSTEM (SUSPENDED CEILING MOUNT)',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 16),
                  _TrackVisual(
                      robotCoach: robot?.currentCoach ?? 'Pantry',
                      destCoach: _simDestCoach,
                      destSeat: _simDestSeat),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                          'COACH $_simDestCoach SEAT LAYOUT (AUTOMATED TARGETING)',
                          style: AppTheme.uppercaseLabel),
                      const Spacer(),
                      Text('TARGET: SEAT $_simDestSeat',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SeatGrid(
                      destSeat: _simDestSeat,
                      arrivedSeat: robotState.lastMarkerSeat),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Live Mode: honest, order-driven view ----------

  Widget _buildLiveView(BuildContext context, RobotState robotState,
      OrderState orderState, dynamic robot) {
    final destinationOrder = orderState.active
        .where((o) =>
            o.orderStatus == 'DISPATCHED' ||
            o.orderStatus == 'ARRIVED' ||
            o.orderStatus == 'LOADED')
        .toList();
    final Order? active =
        destinationOrder.isNotEmpty ? destinationOrder.first : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OVERHEAD TRACK SYSTEM', style: AppTheme.uppercaseLabel),
          const SizedBox(height: 6),
          const Text('Live robot fleet position',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          GlassCard(
            child: Row(
              children: [
                _infoBlock('CURRENT LOCATION',
                    robot?.currentCoach ?? 'Pantry Coach', AppColors.primary),
                const SizedBox(width: 28),
                _infoBlock(
                    'DESTINATION',
                    active != null
                        ? '${active.coachNo} – Seat ${active.seatNo}'
                        : 'No active delivery',
                    active != null
                        ? AppColors.primaryBright
                        : AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: active == null
                ? _EmptyTrackState()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            '↔  OVERHEAD MONORAIL TRACK SYSTEM (SUSPENDED CEILING MOUNT)',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                        const SizedBox(height: 16),
                        _TrackVisual(
                            robotCoach: robot?.currentCoach ?? 'Pantry',
                            destCoach: active.coachNo,
                            destSeat: active.seatNo),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Text(
                                'COACH ${active.coachNo} SEAT LAYOUT (AUTOMATED TARGETING)',
                                style: AppTheme.uppercaseLabel),
                            const Spacer(),
                            Text('TARGET: SEAT ${active.seatNo}',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SeatGrid(
                            destSeat: active.seatNo,
                            arrivedSeat: robotState.lastMarkerSeat),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.uppercaseLabel),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }
}

class _EmptyTrackState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder)),
            child: const Icon(Icons.route_rounded,
                size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Text('No robot in transit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
              'The track appears once an order is Ready and dispatched to a robot.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TrackVisual extends StatelessWidget {
  final String robotCoach;
  final String destCoach;
  final String destSeat;
  const _TrackVisual(
      {required this.robotCoach,
      required this.destCoach,
      required this.destSeat});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final segmentWidth = constraints.maxWidth / _coaches.length;
      final robotIndex =
          _coaches.indexOf(robotCoach).clamp(0, _coaches.length - 1);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 70,
            child: Stack(
              children: [
                Positioned(
                  top: 30,
                  left: 0,
                  right: 0,
                  child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 12)
                        ],
                      )),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  left: segmentWidth * robotIndex + segmentWidth / 2 - 28,
                  top: 0,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 1)
                          ],
                        ),
                        child: const Icon(Icons.smart_toy_rounded,
                            color: Colors.black, size: 26),
                      ),
                      const SizedBox(height: 2),
                      const Text('POD-01',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final coach in _coaches)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _CoachTile(
                      name: coach,
                      isDestination: coach == destCoach,
                      destSeat: destSeat,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}

class _CoachTile extends StatelessWidget {
  final String name;
  final bool isDestination;
  final String destSeat;
  const _CoachTile(
      {required this.name,
      required this.isDestination,
      required this.destSeat});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: isDestination ? AppColors.primary : null,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: Column(
        children: [
          if (isDestination)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('DESTINATION\nSEAT $destSeat',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1.3)),
            ),
          Icon(
              name == 'Pantry'
                  ? Icons.storefront_rounded
                  : Icons.event_seat_rounded,
              color:
                  isDestination ? AppColors.primary : AppColors.textSecondary,
              size: 22),
          const SizedBox(height: 6),
          Text(name == 'Pantry' ? 'Pantry Coach' : 'Coach $name',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDestination
                      ? AppColors.textPrimary
                      : AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SeatGrid extends StatelessWidget {
  final String destSeat;
  final String? arrivedSeat;
  const _SeatGrid({required this.destSeat, this.arrivedSeat});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (int seat = 1; seat <= _seatsPerCoach; seat++)
          _SeatBox(
              seat: seat,
              isTarget: '$seat' == destSeat,
              isConfirmedArrival: '$seat' == arrivedSeat),
      ],
    );
  }
}

class _SeatBox extends StatelessWidget {
  final int seat;
  final bool isTarget;
  final bool isConfirmedArrival;
  const _SeatBox(
      {required this.seat,
      required this.isTarget,
      required this.isConfirmedArrival});

  @override
  Widget build(BuildContext context) {
    final color = isConfirmedArrival
        ? AppColors.green
        : (isTarget ? AppColors.primary : AppColors.textSecondary);
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: (isTarget || isConfirmedArrival)
            ? color.withOpacity(0.12)
            : AppColors.card.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: (isTarget || isConfirmedArrival)
                ? color
                : AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.event_seat_rounded, size: 18, color: color),
          const SizedBox(height: 6),
          Text('Seat $seat',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: (isTarget || isConfirmedArrival)
                      ? AppColors.textPrimary
                      : AppColors.textSecondary)),
        ],
      ),
    );
  }
}
