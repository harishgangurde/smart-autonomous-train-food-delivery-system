import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/order.dart';

/// The "Technical Timeline" vertical stepper from the reference tracking
/// screen: filled/glowing dot for the current step, hollow grey dots for
/// pending ones, connecting line, right-aligned timestamps.
class TimelineStepper extends StatelessWidget {
  final String currentStatus;
  final Order order;
  const TimelineStepper({super.key, required this.currentStatus, required this.order});

  static const _steps = [
    ('PLACED', 'Placed'),
    ('CONFIRMED', 'Confirmed'),
    ('PREPARING', 'Preparing'),
    ('READY', 'Ready'),
    ('DISPATCHED', 'Robot Assigned'),
    ('ARRIVED', 'Dispatched'),
    ('OTP_VERIFIED', 'OTP Required'),
  ];

  double? _timestampFor(String key) {
    switch (key) {
      case 'PLACED': return order.createdAt;
      default: return null; // timestamps beyond PLACED aren't tracked client-side yet
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = kOrderStatusFlow.indexOf(currentStatus).clamp(0, _steps.length - 1);
    return Column(
      children: [
        for (int i = 0; i < _steps.length; i++)
          _StepRow(
            label: _steps[i].$2,
            isDone: i < currentIndex,
            isCurrent: i == currentIndex,
            isLast: i == _steps.length - 1,
            timestamp: _timestampFor(_steps[i].$1),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool isDone, isCurrent, isLast;
  final double? timestamp;
  const _StepRow({
    required this.label, required this.isDone, required this.isCurrent,
    required this.isLast, this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final active = isDone || isCurrent;
    final color = isCurrent ? AppColors.amber : (isDone ? AppColors.primary : AppColors.textMuted);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                  boxShadow: isCurrent ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 1)] : null,
                ),
                child: active
                    ? const Icon(Icons.circle, size: 5, color: Colors.white)
                    : null,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: color.withOpacity(active ? 0.4 : 0.15))),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                          color: active ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 14.5,
                        )),
                  ),
                  if (isCurrent)
                    Text('IN PROGRESS', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.4))
                  else if (timestamp != null)
                    Text(
                      DateTime.fromMillisecondsSinceEpoch((timestamp! * 1000).toInt())
                          .toString().substring(11, 16),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Transit Vector" mini live-track widget: Pantry — Coach — Your Seat,
/// with a moving dot matching the robot's coarse progress toward the seat.
class TransitVector extends StatelessWidget {
  final double progress; // 0.0 = pantry, 1.0 = at seat
  final String seatLabel;
  final bool live;

  const TransitVector({super.key, required this.progress, required this.seatLabel, this.live = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Transit Vector', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            if (live)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
                child: const Text('LIVE', style: TextStyle(color: AppColors.primaryBright, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 46,
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              children: [
                Positioned(
                  top: 18, left: 8, right: 8,
                  child: Container(height: 3, decoration: BoxDecoration(
                      color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2))),
                ),
                Positioned(
                  top: 18, left: 8,
                  child: Container(
                    height: 3, width: (w - 16) * progress.clamp(0.0, 1.0),
                    decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Positioned(left: 0, top: 10, child: _dot(false, 'Pantry')),
                Positioned(left: (w / 2) - 20, top: 10, child: _dot(progress > 0.4, 'Coach')),
                Positioned(right: 0, top: 4, child: _dot(progress >= 1.0, seatLabel, big: true)),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _dot(bool active, String label, {bool big = false}) {
    return Column(
      children: [
        Container(
          width: big ? 16 : 10, height: big ? 16 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : AppColors.textMuted,
            boxShadow: active ? [BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 8)] : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}
