import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import 'bistro_tab.dart';
import 'track_tab.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';

/// Route name used to pop back here from Cart/Payment after checkout.
const String passengerShellRouteName = '/passenger-shell';

class PassengerShellScreen extends StatelessWidget {
  const PassengerShellScreen({super.key});

  static const _tabs = [
    (Icons.restaurant_rounded, 'Bistro'),
    (Icons.local_shipping_rounded, 'Track'),
    (Icons.receipt_long_rounded, 'Orders'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final index = appState.passengerTabIndex;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: index,
        children: const [BistroTab(), TrackTab(), OrdersTab(), ProfileTab()],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.bgElevated,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < _tabs.length; i++)
                _NavItem(
                  icon: _tabs[i].$1,
                  label: _tabs[i].$2,
                  selected: i == index,
                  onTap: () => appState.setPassengerTab(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color:
                    selected ? AppColors.primaryBright : AppColors.textMuted),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.primaryBright,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
            ],
          ],
        ),
      ),
    );
  }
}
