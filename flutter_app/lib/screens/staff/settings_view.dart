import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../state/app_state.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final _ipController =
      TextEditingController(text: context.read<AppState>().esp32Address);
  late final _backendController =
      TextEditingController(text: context.read<AppState>().settings.backendUrl);
  late final _upiVpaController =
      TextEditingController(text: context.read<AppState>().upiVpa);
  late final _upiNameController =
      TextEditingController(text: context.read<AppState>().upiPayeeName);
  bool _testing = false;
  bool _upiSaved = false;

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    final appState = context.read<AppState>();
    appState.setEsp32Address(_ipController.text.trim());

    if (appState.simulationMode) {
      // Nothing physical to test — say so plainly rather than claiming a
      // real connection that doesn't exist.
      await Future.delayed(const Duration(milliseconds: 500));
      appState.setEsp32Status('SIMULATED');
      setState(() => _testing = false);
      return;
    }

    // Live mode: ask the backend what it actually knows. The ESP32 only
    // shows ONLINE here if it has sent a heartbeat within the last 15s
    // (see backend/app/services/store.py robot_is_online) — this is a
    // real check, not a guess based on whether the IP field has text.
    try {
      final robot = await appState.api.fetchRobot('POD-01');
      final online = robot['status'] == 'ONLINE';
      appState.setEsp32Status(online ? 'CONNECTED' : 'DISCONNECTED');
    } catch (_) {
      // Backend itself unreachable, or robot never registered.
      appState.setEsp32Status('DISCONNECTED');
    }
    setState(() => _testing = false);
  }

  void _saveBackendUrl() {
    context.read<AppState>().setBackendUrl(_backendController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backend URL saved')),
    );
  }

  void _saveUpi() {
    context.read<AppState>().setUpiDetails(
          vpa: _upiVpaController.text.trim(),
          payeeName: _upiNameController.text.trim(),
        );
    setState(() => _upiSaved = true);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SETTINGS', style: AppTheme.uppercaseLabel),
          const SizedBox(height: 16),
          GlassCard(
            borderColor: appState.firebaseAvailable
                ? AppColors.green
                : AppColors.textMuted,
            child: Row(
              children: [
                Icon(
                    appState.firebaseAvailable
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: appState.firebaseAvailable
                        ? AppColors.green
                        : AppColors.textMuted,
                    size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          appState.firebaseAvailable
                              ? 'Firebase Connected'
                              : 'Firebase Not Configured',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        appState.firebaseAvailable
                            ? 'Passenger login and live data (menu, orders, robots, alerts) are backed by Cloud Firestore — this is real, not demo data.'
                            : 'Run "flutterfire configure" in flutter_app/ and add backend/serviceAccountKey.json — see FIREBASE_SETUP.md. Until then, data shown is local/demo only.',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            borderColor:
                appState.simulationMode ? AppColors.amber : AppColors.green,
            child: Row(
              children: [
                Icon(
                    appState.simulationMode
                        ? Icons.science_rounded
                        : Icons.podcasts_rounded,
                    color: appState.simulationMode
                        ? AppColors.amber
                        : AppColors.green,
                    size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          appState.simulationMode
                              ? 'Robot Hardware Simulation'
                              : 'Live Robot Hardware',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        appState.simulationMode
                            ? 'Only robot/ESP32 movement is faked, for demoing before the physical robot exists. Orders, payments and menu are unaffected by this toggle.'
                            : 'Robot position and marker detection come from the real ESP32 over the backend.',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
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
          ),
          const SizedBox(height: 20),
          const Text('PAYMENT — UPI', style: AppTheme.uppercaseLabel),
          const SizedBox(height: 10),
          GlassCard(
            borderColor:
                appState.upiConfigured ? AppColors.green : AppColors.red,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                        appState.upiConfigured
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        size: 16,
                        color: appState.upiConfigured
                            ? AppColors.green
                            : AppColors.red),
                    const SizedBox(width: 8),
                    Text(
                        appState.upiConfigured
                            ? 'UPI payments configured'
                            : 'UPI not configured yet',
                        style: TextStyle(
                            color: appState.upiConfigured
                                ? AppColors.green
                                : AppColors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _upiVpaController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID (VPA)',
                    hintText: 'yourname@oksbi',
                    prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                  ),
                  onChanged: (_) => setState(() => _upiSaved = false),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _upiNameController,
                  decoration: const InputDecoration(
                    labelText: 'Payee Display Name',
                    hintText: 'Train Kitchen Services',
                  ),
                  onChanged: (_) => setState(() => _upiSaved = false),
                ),
                const SizedBox(height: 6),
                Text(
                  appState.firebaseAvailable
                      ? 'This is your UPI ID, not a bank account number — any UPI app '
                          '(GPay/PhonePe/Paytm) can show you yours, or create one instantly '
                          'from a linked bank account. Saved here, this syncs to every '
                          'passenger\'s app automatically via Firestore.'
                      : 'This is your UPI ID, not a bank account number. Note: Firebase '
                          'isn\'t configured yet, so this only saves on this device — '
                          'passengers on other devices won\'t see it until Firebase is set up.',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: _saveUpi,
                        child: const Text('SAVE UPI DETAILS')),
                    if (_upiSaved) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.check_rounded,
                          color: AppColors.green, size: 18),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('BACKEND CONNECTION', style: AppTheme.uppercaseLabel),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _backendController,
                  decoration:
                      const InputDecoration(labelText: 'FastAPI Backend URL'),
                ),
                const SizedBox(height: 4),
                const Text(
                    'e.g. http://192.168.1.50:8000 — the machine running uvicorn on the train LAN',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: _saveBackendUrl, child: const Text('SAVE')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('ROBOT / ESP32 CONFIGURATION',
              style: AppTheme.uppercaseLabel),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Robot ID',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                const Text('POD-01',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 16),
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'ESP32 IP Address',
                    hintText: '192.168.1.105',
                    prefixIcon: Icon(Icons.wifi_rounded),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The ESP32 reads its own IP from DHCP on connect and registers it with the '
                  'backend automatically. Enter it here to test a direct connection from this '
                  'dashboard, or leave the backend to relay commands via the last registered IP.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        context
                            .read<AppState>()
                            .setEsp32Address(_ipController.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ESP32 IP saved')),
                        );
                      },
                      child: const Text('SAVE'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _testing ? null : _testConnection,
                      child: _testing
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('TEST CONNECTION'),
                    ),
                    const SizedBox(width: 14),
                    StatusBadge(
                      label: appState.esp32ConnectionStatus == 'UNKNOWN'
                          ? 'Not tested'
                          : appState.esp32ConnectionStatus,
                      color: switch (appState.esp32ConnectionStatus) {
                        'CONNECTED' => AppColors.green,
                        'DISCONNECTED' => AppColors.red,
                        'SIMULATED' => AppColors.amber,
                        _ => AppColors.textSecondary,
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('ACCOUNT', style: AppTheme.uppercaseLabel),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                        backgroundColor: AppColors.primaryBright,
                        child: Icon(Icons.person, color: Colors.white)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appState.staffName ?? '-',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(appState.staffId ?? '-',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  appState.firebaseAvailable
                      ? 'Single staff account, managed in Firebase console '
                          '(Authentication → Users). Works from any device with '
                          'internet — the backend can be offline and login still works.'
                      : 'This system uses a single staff account, set on the backend '
                          '(not in this app, for security). To change the mobile number or '
                          'password,— see backend/.env.example. Once '
                          'Firebase is configured, staff login switches to a Firebase '
                          'account instead, which works even when the backend is offline.',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
