import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/siren_overlay.dart';
import '../../state/app_state.dart';
import '../login_selection_screen.dart';
import 'orders_view.dart';
import 'menu_management_view.dart';
import 'robot_track_view.dart';
import 'admin_analytics_view.dart';
import 'security_alerts_view.dart';
import 'settings_view.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  const _NavItem(this.icon, this.label, this.screen);
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _index = 0;

  static const _items = [
    _NavItem(Icons.list_alt_rounded, 'Orders', OrdersView()),
    _NavItem(Icons.restaurant_menu_rounded, 'Menu', MenuManagementView()),
    _NavItem(Icons.route_rounded, 'Robot Track', RobotTrackView()),
    _NavItem(Icons.insights_rounded, 'Analytics', AdminAnalyticsView()),
    _NavItem(Icons.shield_rounded, 'Alerts', SecurityAlertsView()),
    _NavItem(Icons.settings_rounded, 'Settings', SettingsView()),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: SirenOverlay(
        child: GridBackground(
          child: SafeArea(
            child: isWide
                ? Row(
                    children: [
                      _SideNav(
                        index: _index,
                        items: _items,
                        onSelect: (i) => setState(() => _index = i),
                        staffName: appState.staffName ?? 'Staff',
                        simulationMode: appState.simulationMode,
                      ),
                      Expanded(child: _items[_index].screen),
                    ],
                  )
                : Column(
                    children: [
                      _TopBar(
                        staffName: appState.staffName ?? 'Staff',
                        simulationMode: appState.simulationMode,
                      ),
                      Expanded(child: _items[_index].screen),
                    ],
                  ),
          ),
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: AppColors.bgElevated,
              indicatorColor: AppColors.primary.withOpacity(0.15),
              destinations: [
                for (final item in _items)
                  NavigationDestination(
                      icon: Icon(item.icon), label: item.label),
              ],
            ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final int index;
  final List<_NavItem> items;
  final ValueChanged<int> onSelect;
  final String staffName;
  final bool simulationMode;

  const _SideNav({
    required this.index,
    required this.items,
    required this.onSelect,
    required this.staffName,
    required this.simulationMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 22,
                    height: 22,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.train_rounded,
                        color: AppColors.primaryBright,
                        size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('RailDine',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.primaryBright)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _NavTile(
                icon: items[i].icon,
                label: items[i].label,
                selected: i == index,
                onTap: () => onSelect(i),
              ),
            ),
          const Spacer(),
          if (simulationMode)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child:
                  StatusBadge(label: 'SIMULATION MODE', color: AppColors.amber),
            ),
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                    backgroundColor: AppColors.primaryBright,
                    radius: 16,
                    child: Icon(Icons.person, size: 16, color: Colors.white)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(staffName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  onPressed: () {
                    context.read<AppState>().logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginSelectionScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: AppColors.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String staffName;
  final bool simulationMode;
  const _TopBar({required this.staffName, required this.simulationMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Text('RailDine',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.primaryBright)),
          const Spacer(),
          if (simulationMode)
            const StatusBadge(label: 'SIMULATION', color: AppColors.amber),
        ],
      ),
    );
  }
}
