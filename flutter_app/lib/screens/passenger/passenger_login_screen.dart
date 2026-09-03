import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../state/app_state.dart';
import 'coach_seat_screen.dart';

class PassengerLoginScreen extends StatefulWidget {
  const PassengerLoginScreen({super.key});

  @override
  State<PassengerLoginScreen> createState() => _PassengerLoginScreenState();
}

class _PassengerLoginScreenState extends State<PassengerLoginScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _demoOtp; // shown only in the mock (non-Firebase) fallback path
  String? _error;
  String? _verificationId; // Firebase phone-auth session id

  Future<void> _sendOtp() async {
    if (_mobileController.text.trim().length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final appState = context.read<AppState>();

    if (appState.firebaseAvailable) {
      final phone =
          '+91${_mobileController.text.trim()}'; // adjust country code as needed
      await appState.firebaseAuth.sendOtp(
        phoneNumber: phone,
        onCodeSent: (verificationId) {
          _verificationId = verificationId;
          if (mounted)
            setState(() {
              _otpSent = true;
              _loading = false;
            });
        },
        onAutoVerified: (user) async {
          // Android sometimes verifies without the user typing anything.
          await _completeLogin(appState, user.uid);
        },
        onError: (message) {
          if (mounted)
            setState(() {
              _error = message;
              _loading = false;
            });
        },
      );
      return;
    }

    // Mock fallback — no Firebase project configured yet.
    try {
      Map<String, dynamic> res;
      if (appState.simulationMode) {
        res = {'demoOtp': '1234'};
      } else {
        res = await appState.api
            .requestPassengerOtp(_mobileController.text.trim());
      }
      _demoOtp = res['demoOtp']?.toString();
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _error = 'Could not send OTP. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final appState = context.read<AppState>();
    try {
      if (appState.firebaseAvailable) {
        final user = await appState.firebaseAuth.verifyOtp(
          verificationId: _verificationId!,
          smsCode: _otpController.text.trim(),
        );
        await _completeLogin(appState, user.uid);
        return;
      }

      String passengerId;
      if (appState.simulationMode) {
        if (_otpController.text.trim() != (_demoOtp ?? '1234')) {
          throw Exception('Invalid OTP');
        }
        passengerId = 'USER-${_mobileController.text.trim().substring(6)}';
      } else {
        final res = await appState.api.verifyPassengerOtp(
            _mobileController.text.trim(), _otpController.text.trim());
        passengerId = res['passengerId'];
      }
      appState.loginPassenger(
          passengerId: passengerId, mobile: _mobileController.text.trim());
      _goToCoachSeat();
    } catch (e) {
      setState(() => _error = 'Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeLogin(AppState appState, String uid) async {
    final mobile = _mobileController.text.trim();
    // Upsert a lightweight passenger profile doc — this is the `users`
    // collection referenced throughout the design (order history, etc.
    // read/write against passengerId = this uid).
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'passengerId': uid,
        'mobile': mobile,
        'role': 'passenger',
        'lastLoginAt': DateTime.now().millisecondsSinceEpoch / 1000,
      }, SetOptions(merge: true));
    } catch (_) {} // non-fatal — login still proceeds even if this write fails

    appState.loginPassenger(passengerId: uid, mobile: mobile);
    _goToCoachSeat();
    if (mounted) setState(() => _loading = false);
  }

  void _goToCoachSeat() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CoachSeatScreen()),
    );
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(height: 8),
                    const Text('Passenger Login',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Enter your mobile number to continue',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    StatusBadge(
                      label: firebaseOn ? 'Firebase Phone Auth' : 'Demo Login',
                      color: firebaseOn ? AppColors.green : AppColors.amber,
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _mobileController,
                            enabled: !_otpSent,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              prefixIcon: Icon(Icons.phone_android_rounded),
                              prefixText: '+91 ',
                              counterText: '',
                            ),
                          ),
                          if (_otpSent) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'Enter OTP',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                counterText: '',
                                helperText: _demoOtp != null
                                    ? 'Demo OTP: $_demoOtp'
                                    : null,
                                helperStyle:
                                    const TextStyle(color: AppColors.green),
                              ),
                            ),
                          ],
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
                              onPressed: _loading
                                  ? null
                                  : (_otpSent ? _verifyOtp : _sendOtp),
                              child: _loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.black))
                                  : Text(_otpSent
                                      ? 'VERIFY & CONTINUE'
                                      : 'SEND OTP'),
                            ),
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
