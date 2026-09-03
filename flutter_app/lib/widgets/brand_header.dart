import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The small branded top bar used across passenger and staff screens:
/// icon + "RailDine" wordmark, with an optional pill on the right
/// (coach•seat for passengers, a status badge for staff).
class BrandHeader extends StatelessWidget {
  final Widget? trailing;
  final bool compact;
  const BrandHeader({super.key, this.trailing, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 22.0 : 26.0;
    return Row(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(logoSize * 0.28),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.train_rounded,
                    color: AppColors.primary, size: compact ? 16 : 18),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'RailDine',
              style: TextStyle(
                color: AppColors.primaryBright,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 13 : 15,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Small rounded pill, e.g. "COACH B4 · SEAT 22A".
class InfoPill extends StatelessWidget {
  final String label;
  final Color? color;
  const InfoPill({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
            color: c,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6),
      ),
    );
  }
}
