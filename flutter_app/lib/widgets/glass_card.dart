import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The recurring card look from the reference screenshots: dark translucent
/// panel, subtle border, soft glow on hover-ready surfaces.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
        boxShadow: borderColor != null
            ? [BoxShadow(color: borderColor!.withOpacity(0.15), blurRadius: 24, spreadRadius: -4)]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}

/// Faint grid background used behind the staff Chrome dashboard, matching
/// the "Central Command" reference image.
class GridBackground extends StatelessWidget {
  final Widget child;
  const GridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientDarkBg),
      child: CustomPaint(
        painter: _GridPainter(),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color, blurRadius: 6)]),
          ),
          const SizedBox(width: 6),
          Text(label.replaceAll('_', ' '),
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}

/// Small stat card used on the admin analytics dashboard.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subLabel;
  final Color accent;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subLabel,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTheme.uppercaseLabel),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w700)),
          if (subLabel != null) ...[
            const SizedBox(height: 6),
            Text(subLabel!, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
