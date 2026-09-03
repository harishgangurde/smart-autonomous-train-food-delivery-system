import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryPillBar extends StatelessWidget {
  final List<String> categories; // "All" is prepended automatically
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryPillBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final all = ['All', ...categories];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = all[i];
          final isSelected = cat == selected;
          return InkWell(
            onTap: () => onSelected(cat),
            borderRadius: BorderRadius.circular(100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pill-style search field matching the reference screens.
class PillSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  const PillSearchBar({super.key, this.hintText = 'Search menu items...', required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
        isDense: true,
      ),
    );
  }
}
