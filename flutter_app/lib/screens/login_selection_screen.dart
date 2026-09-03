import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'passenger/passenger_login_screen.dart';
import 'staff/staff_login_screen.dart';

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ShaderMask(
                          shaderCallback: (rect) =>
                              AppColors.gradientPrimary.createShader(rect),
                          child: const Icon(Icons.train_rounded,
                              size: 56, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.35)),
                      ),
                      child: ShaderMask(
                        shaderCallback: (rect) =>
                            AppColors.gradientPrimary.createShader(rect),
                        child: const Text('RAILDINE',
                            style: TextStyle(
                                fontSize: 15,
                                letterSpacing: 3,
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ShaderMask(
                      shaderCallback: (rect) =>
                          AppColors.gradientPrimary.createShader(rect),
                      child: const Text(
                          'Gourmet Dining,\nDelivered to Your Seat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.25)),
                    ),
                    const SizedBox(height: 48),
                    _RoleButton(
                      icon: Icons.person_rounded,
                      title: 'Passenger Login',
                      subtitle: 'Order food to your seat',
                      color: AppColors.primary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PassengerLoginScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _RoleButton(
                      icon: Icons.badge_rounded,
                      title: 'Staff Login',
                      subtitle: 'Kitchen & fleet dashboard',
                      color: AppColors.primaryBright,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const StaffLoginScreen()),
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

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: color.withOpacity(0.5),
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
        ],
      ),
    );
  }
}
