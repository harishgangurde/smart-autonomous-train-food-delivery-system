import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/menu_item.dart';

/// Landscape catalog card used on the Staff Menu tab: image with a corner
/// tag and a small info badge, title/price row, description, and a bottom
/// action row (passed in by the caller — Edit + Availability toggle).
class StaffFoodCard extends StatelessWidget {
  final MenuItem item;
  final String? cornerTag;
  final Widget actionsRow;

  const StaffFoodCard({
    super.key,
    required this.item,
    required this.actionsRow,
    this.cornerTag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        key: ValueKey(item.imageUrl),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : _loading(),
                        errorBuilder: (_, __, ___) => _fallback(),
                      )
                    : _fallback(),
              ),
              if (cornerTag != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: _chip(cornerTag!, AppColors.card.withOpacity(0.85),
                      AppColors.textPrimary),
                ),
              Positioned(
                bottom: 10,
                right: 10,
                child: _chip('${item.prepMinutes} min prep',
                    Colors.black.withOpacity(0.6), Colors.white),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.primaryBright,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4)),
                const SizedBox(height: 12),
                actionsRow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
        child: Text(text,
            style: TextStyle(
                color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
      );

  Widget _fallback() => Container(
        color: AppColors.bgElevated,
        child: const Center(
            child: Icon(Icons.restaurant_rounded,
                color: AppColors.textMuted, size: 28)),
      );

  Widget _loading() => Container(
        color: AppColors.bgElevated,
        child: const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
}

/// Tall portrait card used on the Passenger Bistro tab: full-width image,
/// floating price pill, title, prep-time row, and a circular add/qty
/// control anchored to the bottom-right corner. Dims + labels itself
/// OUT OF STOCK when unavailable.
class PassengerFoodCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const PassengerFoodCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = item.available;
    return Opacity(
      opacity: available ? 1 : 0.55,
      child: InkWell(
        onTap: available ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 11,
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            key: ValueKey(item.imageUrl),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) =>
                                progress == null ? child : _loading(),
                            errorBuilder: (_, __, ___) => _fallback(),
                          )
                        : _fallback(),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ),
                  if (!available)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text('OUT OF STOCK',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                                letterSpacing: 0.4)),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text('${item.prepMinutes} min prep',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (available) _addControl(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addControl() {
    if (quantity == 0) {
      return InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
              gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
              onTap: onRemove,
              child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.remove_rounded,
                      size: 15, color: Colors.white))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('$quantity',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ),
          InkWell(
              onTap: onAdd,
              child: const Padding(
                  padding: EdgeInsets.all(4),
                  child:
                      Icon(Icons.add_rounded, size: 15, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.bgElevated,
        child: const Center(
            child: Icon(Icons.restaurant_rounded,
                color: AppColors.textMuted, size: 28)),
      );

  Widget _loading() => Container(
        color: AppColors.bgElevated,
        child: const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
}
