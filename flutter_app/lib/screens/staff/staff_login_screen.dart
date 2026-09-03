import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../state/app_state.dart';
import 'staff_dashboard_screen.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _identifierController =
      TextEditingController(); // email once Firebase is on, else mobile
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final appState = context.read<AppState>();
    try {
      if (appState.firebaseAvailable) {
        // Works from any device with internet — no dependency on the
        // FastAPI backend being up, or on being on the same network as it.
        final user = await appState.firebaseAuth.signInStaff(
          email: _identifierController.text.trim(),
          password: _passwordController.text,
        );
        appState.loginStaff(staffId: user.uid, name: user.email ?? 'Staff');
      } else {
        // Pre-Firebase fallback — this path DOES require the backend
        // reachable, which is exactly the limitation Firebase login fixes.
        final res = await appState.api.staffLogin(
            _identifierController.text.trim(), _passwordController.text);
        appState.loginStaff(staffId: res['staffId'], name: res['name']);
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = appState.firebaseAvailable
          ? 'Invalid email or password.'
          : 'Invalid mobile number or password, or backend unreachable.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseOn = context.watch<AppState>().firebaseAvailable;

    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(height: 8),
                    const Text('Staff Login',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Kitchen & fleet control access',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    StatusBadge(
                      label: firebaseOn
                          ? 'Firebase Account'
                          : 'Backend Account (offline-limited)',
                      color: firebaseOn ? AppColors.green : AppColors.amber,
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      borderColor: AppColors.primaryBright.withOpacity(0.4),
                      child: Column(
                        children: [
                          TextField(
                            controller: _identifierController,
                            keyboardType: firebaseOn
                                ? TextInputType.emailAddress
                                : TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: firebaseOn ? 'Email' : 'Mobile Number',
                              prefixIcon: Icon(firebaseOn
                                  ? Icons.email_outlined
                                  : Icons.phone_android_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.red, fontSize: 13)),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBright),
                              child: _loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.black))
                                  : const Text('LOGIN'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            firebaseOn
                                ? 'This account is created once in Firebase console (Authentication → Users).'
                                : 'This account is set in backend/.env — see Settings once logged in.',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
