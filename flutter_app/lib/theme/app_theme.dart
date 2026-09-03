import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "RailDine" theme: near-black backdrop, one vivid electric-blue
/// accent (matching the app icon's neon glow), fully-rounded pill
/// buttons/chips, minimal chrome.
class AppColors {
  static const bg = Color(0xFF08080C);
  static const bgElevated = Color(0xFF0F0E15);
  static const card = Color(0xFF15141C);
  static const cardBorder = Color(0xFF262533);

  static const primary = Color(0xFF3B82F6);
  static const primaryBright = Color(0xFF60A5FA);
  static const primaryDeep = Color(0xFF1D4ED8);

  static const green = Color(0xFF34D399);
  static const amber = Color(0xFFFBBF24);
  static const red = Color(0xFFF87171);
  static const pink = Color(0xFFF472B6);

  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF55545F);

  static const gridLine = Color(0xFF141319);

  static const gradientPrimary = LinearGradient(
    colors: [primary, primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientDarkBg = LinearGradient(
    colors: [Color(0xFF08080C), Color(0xFF0D0C13), Color(0xFF08080C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final displayFont = GoogleFonts.spaceGroteskTextTheme(base.textTheme);
    final monoFont = GoogleFonts.jetBrainsMonoTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.primaryBright,
        surface: AppColors.card,
        error: AppColors.red,
      ),
      textTheme: displayFont.copyWith(
        bodySmall: monoFont.bodySmall?.copyWith(color: AppColors.textSecondary),
        labelSmall: monoFont.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.4,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
          elevation: 0,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.08)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBright,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary.withOpacity(0.35)
              : AppColors.cardBorder,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      dividerColor: AppColors.cardBorder,
    );
  }

  static const uppercaseLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
  );
}

/// Status -> color mapping used across order cards, badges, robot state.
Color statusColor(String status) {
  switch (status) {
    case 'PLACED':
      return AppColors.textSecondary;
    case 'CONFIRMED':
      return AppColors.primary;
    case 'PREPARING':
      return AppColors.amber;
    case 'READY':
      return AppColors.green;
    case 'LOADED':
      return AppColors.primaryBright;
    case 'DISPATCHED':
    case 'MOVING':
      return AppColors.primary;
    case 'ARRIVED':
      return AppColors.primaryBright;
    case 'OTP_VERIFIED':
      return AppColors.green;
    case 'DELIVERED':
    case 'ONLINE':
      return AppColors.green;
    case 'CANCELLED':
    case 'FAILED':
    case 'OFFLINE':
      return AppColors.red;
    default:
      return AppColors.textSecondary;
  }
}
