import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/glass_card.dart';
import '../../state/app_state.dart';
import '../login_selection_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandHeader(),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 14),
                  Text(appState.passengerMobile ?? 'Passenger',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(appState.passengerId ?? '',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _row(Icons.train_rounded, 'Coach', appState.coachNo ?? '-'),
            _row(Icons.event_seat_rounded, 'Seat', appState.seatNo ?? '-'),
            _row(Icons.cloud_rounded, 'Account',
                appState.firebaseAvailable ? 'Firebase' : 'Demo'),
            const SizedBox(height: 16),
            _SimulationToggleCard(),
            const SizedBox(height: 16),
            _BackendUrlCard(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  appState.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const LoginSelectionScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('LOG OUT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const Spacer(),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Manual override for the backend address. Normally this syncs
/// automatically via Firestore from whatever staff set (see AppState),
/// which covers the common case of everyone sharing one WiFi + one
/// backend machine. This is the escape hatch for when that's not enough
/// — e.g. this phone is on mobile data instead of the venue WiFi.
class _BackendUrlCard extends StatefulWidget {
  @override
  State<_BackendUrlCard> createState() => _BackendUrlCardState();
}

class _BackendUrlCardState extends State<_BackendUrlCard> {
  late final _controller =
      TextEditingController(text: context.read<AppState>().settings.backendUrl);
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BACKEND CONNECTION', style: AppTheme.uppercaseLabel),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'FastAPI Backend URL'),
            onChanged: (_) => setState(() => _saved = false),
          ),
          const SizedBox(height: 6),
          const Text(
            'Usually syncs automatically from Staff Settings. Only change this if '
            'orders/tickets aren\'t working on this specific device (e.g. different '
            'network than the venue WiFi).',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  context
                      .read<AppState>()
                      .setBackendUrl(_controller.text.trim());
                  setState(() => _saved = true);
                },
                child: const Text('SAVE'),
              ),
              if (_saved) ...[
                const SizedBox(width: 10),
                const Icon(Icons.check_rounded,
                    color: AppColors.green, size: 18),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Robot/ESP32 hardware simulation toggle. Since it's Firestore-synced
/// (once Firebase is configured), flipping it here or in Staff Settings
/// updates every device instantly — it's the same switch either way.
class _SimulationToggleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return GlassCard(
      borderColor: appState.simulationMode ? AppColors.amber : AppColors.green,
      child: Row(
        children: [
          Icon(
              appState.simulationMode
                  ? Icons.science_rounded
                  : Icons.podcasts_rounded,
              color:
                  appState.simulationMode ? AppColors.amber : AppColors.green,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    appState.simulationMode
                        ? 'Robot Simulation Mode'
                        : 'Live Robot Hardware',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text(
                  appState.simulationMode
                      ? 'Orders, robot movement and alerts are all simulated for demo purposes'
                      : 'Using real orders, ESP32 telemetry and Firestore data',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: !appState.simulationMode,
            activeColor: AppColors.green,
            onChanged: (liveOn) => appState.toggleSimulation(!liveOn),
          ),
        ],
      ),
    );
  }
}
