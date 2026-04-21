import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuraColors {
  const AuraColors._();

  static const Color primary = Color(0xFF00694C);
  static const Color primaryContainer = Color(0xFF008560);
  static const Color primaryFixedDim = Color(0xFF68DBAE);

  static const Color secondary = Color(0xFF1960A6);
  static const Color tertiary = Color(0xFF993F3A);

  static const Color surface = Color(0xFFF9F9F7);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF4F4F2);
  static const Color surfaceHigh = Color(0xFFE8E8E6);
  static const Color surfaceVariant = Color(0xFFE2E3E1);

  static const Color onSurface = Color(0xFF1A1C1B);
  static const Color onSurfaceVariant = Color(0xFF3D4943);

  static const Color outline = Color(0xFF6D7A73);
  static const Color outlineVariant = Color(0xFFBCCAC1);

  static const Color warning = Color(0xFFE58A00);
  static const Color error = Color(0xFFBA1A1A);
}

class AuraRadii {
  const AuraRadii._();

  static const double card = 14;
  static const double pill = 24;
  static const double panel = 28;
}

class AuraTheme {
  const AuraTheme._();

  static ThemeData light() {
    final baseText = GoogleFonts.manropeTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AuraColors.primary,
        onPrimary: Colors.white,
        secondary: AuraColors.secondary,
        onSecondary: Colors.white,
        tertiary: AuraColors.tertiary,
        onTertiary: Colors.white,
        error: AuraColors.error,
        onError: Colors.white,
        surface: AuraColors.surface,
        onSurface: AuraColors.onSurface,
      ),
      scaffoldBackgroundColor: AuraColors.surface,
      textTheme: baseText.copyWith(
        displayMedium: baseText.displayMedium?.copyWith(
          fontSize: 45,
          height: 52 / 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: AuraColors.onSurface,
        ),
        headlineLarge: baseText.headlineLarge?.copyWith(
          fontSize: 32,
          height: 40 / 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AuraColors.onSurface,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w700,
          color: AuraColors.onSurface,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w500,
          color: AuraColors.onSurface,
        ),
        bodySmall: baseText.bodySmall?.copyWith(
          fontSize: 12,
          height: 16 / 12,
          color: AuraColors.onSurfaceVariant,
        ),
        labelSmall: baseText.labelSmall?.copyWith(
          fontSize: 11,
          height: 16 / 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: AuraColors.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AuraColors.surface,
        foregroundColor: AuraColors.onSurface,
        titleTextStyle: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AuraColors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AuraColors.surfaceLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraRadii.card),
          side: BorderSide(
            color: AuraColors.outlineVariant.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
      ),
      dividerColor: AuraColors.outlineVariant.withValues(alpha: 0.25),
    );
  }
}
