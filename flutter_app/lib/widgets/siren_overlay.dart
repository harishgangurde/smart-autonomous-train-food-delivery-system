import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';
import '../state/security_state.dart';

/// Full-screen pulsing red banner + looping siren audio, shown on the
/// staff dashboard whenever there's an unacknowledged security alert.
/// Wrap the staff shell with this so it's impossible to miss regardless
/// of which tab is open. Works identically in Simulation and Live mode —
/// both feed SecurityState the same way, see state/security_state.dart.
class SirenOverlay extends StatefulWidget {
  final Widget child;
  const SirenOverlay({super.key, required this.child});

  @override
  State<SirenOverlay> createState() => _SirenOverlayState();
}

class _SirenOverlayState extends State<SirenOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startSiren() async {
    if (_playing) return;
    _playing = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/siren.mp3'));
    } catch (e) {
      // Missing/invalid asset shouldn't crash the app — the visual alert
      // still works even without sound. Drop your real siren.mp3 into
      // flutter_app/assets/audio/ to hear it (see the README there).
      debugPrint('[Siren] Could not play audio/siren.mp3: $e');
    }
  }

  Future<void> _stopSiren() async {
    if (!_playing) return;
    _playing = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityState>();
    final active = security.activeAlerts;

    if (active.isNotEmpty) {
      _startSiren();
    } else {
      _stopSiren();
    }

    return Stack(
      children: [
        widget.child,
        if (active.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return Container(
                  color: AppColors.red.withOpacity(0.08 + 0.10 * t),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Color.lerp(AppColors.red, Colors.white, t)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SECURITY ALERT — ${active.first.alertType.replaceAll('_', ' ')} '
                          'on ${active.first.robotId} (Coach ${active.first.coachNo})',
                          style: TextStyle(
                            color: Color.lerp(AppColors.red, Colors.white, t),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _stopSiren();
                          security.acknowledge(active.first.alertId);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.3),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('ACKNOWLEDGE'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
