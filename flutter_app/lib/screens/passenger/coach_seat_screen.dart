import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../state/app_state.dart';
import 'passenger_shell_screen.dart';

class CoachSeatScreen extends StatefulWidget {
  const CoachSeatScreen({super.key});

  @override
  State<CoachSeatScreen> createState() => _CoachSeatScreenState();
}

class _CoachSeatScreenState extends State<CoachSeatScreen> {
  final _coachController = TextEditingController(text: 'B2');
  final _seatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                    const Icon(Icons.chair_alt_rounded, color: AppColors.primary, size: 40),
                    const SizedBox(height: 16),
                    const Text('Where are you seated?',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('This tells our robot exactly where to deliver',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 28),
                    GlassCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _coachController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Coach Number',
                              prefixIcon: Icon(Icons.train_rounded),
                              hintText: 'e.g. B2',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _seatController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Seat Number',
                              prefixIcon: Icon(Icons.event_seat_rounded),
                              hintText: 'e.g. 14',
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_coachController.text.trim().isEmpty ||
                                    _seatController.text.trim().isEmpty) {
                                  return;
                                }
                                context.read<AppState>().setCoachSeat(
                                    _coachController.text.trim().toUpperCase(),
                                    _seatController.text.trim());
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    settings: const RouteSettings(name: passengerShellRouteName),
                                    builder: (_) => const PassengerShellScreen(),
                                  ),
                                );
                              },
                              child: const Text('VIEW MENU'),
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
