import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../state/security_state.dart';
import '../../state/app_state.dart';

class SecurityAlertsView extends StatelessWidget {
  const SecurityAlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityState>();
    final appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('SECURITY ALERTS', style: AppTheme.uppercaseLabel)),
              if (appState.simulationMode)
                OutlinedButton.icon(
                  onPressed: () => appState.simulation.triggerFakeSecurityAlert(),
                  icon: const Icon(Icons.bug_report_rounded, size: 16),
                  label: const Text('Simulate Alert'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.amber, side: const BorderSide(color: AppColors.amber)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: security.alerts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, color: AppColors.green, size: 48),
                        SizedBox(height: 10),
                        Text('No security incidents', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: security.alerts.length,
                    itemBuilder: (context, i) {
                      final alert = security.alerts[i];
                      final active = alert.status == 'ACTIVE';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          borderColor: active ? AppColors.red : AppColors.cardBorder,
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: active ? AppColors.red : AppColors.textMuted, size: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(alert.alertType.replaceAll('_', ' '),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text('Robot ${alert.robotId} · Coach ${alert.coachNo}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                        DateFormat('dd MMM yyyy, HH:mm:ss').format(
                                            DateTime.fromMillisecondsSinceEpoch((alert.timestamp * 1000).toInt())),
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              active
                                  ? ElevatedButton(
                                      onPressed: () => security.acknowledge(alert.alertId),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                                      child: const Text('ACKNOWLEDGE'),
                                    )
                                  : StatusBadge(label: 'Ack by ${alert.acknowledgedBy ?? "-"}', color: AppColors.green),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
