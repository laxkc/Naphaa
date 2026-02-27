import 'package:flutter/material.dart';

// ─── design tokens ────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  static const primary      = Color(0xFF0B3954);
  static const primaryLight = Color(0xFF1F4D67);
  static const primaryDark  = Color(0xFF082C42);
  static const accent       = Color(0xFFFF5A5F);
  static const focus        = Color(0xFFFF5A5F);

  static const bg           = Color(0xFFF4F8FB);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceAlt   = Color(0xFFEEF2F7);

  static const label        = Color(0xFF0B3954);
  static const labelSub     = Color(0xFF5F7384);
  static const muted        = Color(0xFF5F7384);
  static const hint         = Color(0xFF8EA0AD);
  static const border       = Color(0xFFE3EAF0);
  static const borderStrong = Color(0xFF5F7384);

  static const success      = Color(0xFF087E8B);
  static const successBg    = Color(0xFFE6F6F7);
  static const warning      = Color(0xFFFF5A5F);
  static const warningBg    = Color(0xFFFFF0F1);
  static const error        = Color(0xFFC81D25);
  static const errorBg      = Color(0xFFFDE8E8);
  static const errorBorder  = Color(0xFFF3CACA);
}

class AppSpacing {
  AppSpacing._();

  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double mdPlus = 12;
  static const double lg  = 24;
  static const double lgPlus = 24;
  static const double xl  = 32;
  static const double xxl = 48;
  static const double h   = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm  = 6;
  static const double md  = 12;
  static const double lg  = 12;
  static const double xl  = 16;
  static const double pill = 999;
}

// ─── theme ────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final cs = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.label,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.bg,

      // typography
      textTheme: const TextTheme(
        displaySmall:  TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 34 / 28, color: AppColors.label, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.label, letterSpacing: -0.5),
        headlineMedium:TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 28 / 22, color: AppColors.label, letterSpacing: -0.4),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 24 / 18, color: AppColors.label),
        titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.label),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 22 / 16, color: AppColors.label),
        titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 20 / 14, color: AppColors.label),
        bodyLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: AppColors.label),
        bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: AppColors.label),
        bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 16 / 12, color: AppColors.muted),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 20 / 14, color: AppColors.label),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
        labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted, letterSpacing: 0.2),
      ),

      // app bar
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.label,
        ),
        iconTheme: IconThemeData(color: AppColors.label),
      ),

      // cards
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          side: BorderSide(color: AppColors.border),
        ),
      ),

      // inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.hint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        errorStyle: const TextStyle(fontSize: 12),
        isDense: false,
      ),

      // buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
          side: const BorderSide(color: AppColors.primary),
          textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // list tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs,
        ),
        minLeadingWidth: 24,
      ),

      // chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.accent.withAlpha(24),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),

      // navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withAlpha(18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.muted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary,
            );
          }
          return const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.muted,
          );
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
        backgroundColor: AppColors.label,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
