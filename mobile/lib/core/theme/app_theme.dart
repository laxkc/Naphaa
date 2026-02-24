import 'package:flutter/material.dart';

// ─── design tokens ────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  static const primary      = Color(0xFF00695C);
  static const primaryLight = Color(0xFF4DB6AC);
  static const primaryDark  = Color(0xFF004D40);

  static const bg           = Color(0xFFF4F6F5);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceAlt   = Color(0xFFF0F4F3);

  static const label        = Color(0xFF0D1F1C);
  static const labelSub     = Color(0xFF3D5450);
  static const muted        = Color(0xFF6B7774);
  static const hint         = Color(0xFFB0BAB7);
  static const border       = Color(0xFFDDE3E1);

  static const success      = Color(0xFF2E7D32);
  static const successBg    = Color(0xFFE8F5E9);
  static const warning      = Color(0xFFEF6C00);
  static const warningBg    = Color(0xFFFFF3E0);
  static const error        = Color(0xFFB71C1C);
  static const errorBg      = Color(0xFFFDEDED);
  static const errorBorder  = Color(0xFFF5C6C6);
}

class AppSpacing {
  AppSpacing._();

  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double h   = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double pill = 999;
}

// ─── theme ────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.label,
      onSurfaceVariant: AppColors.muted,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.bg,

      // typography
      textTheme: const TextTheme(
        displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.label, letterSpacing: -1),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.label, letterSpacing: -0.5),
        headlineMedium:TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.label, letterSpacing: -0.5),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.label),
        titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.label),
        titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.label),
        titleSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.label),
        bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.label),
        bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.label),
        bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.muted),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.label),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
        labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted, letterSpacing: 0.2),
      ),

      // app bar
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
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
          minimumSize: const Size(double.infinity, 50),
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
          minimumSize: const Size(double.infinity, 50),
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
        selectedColor: AppColors.primary.withAlpha(30),
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
        indicatorColor: AppColors.primary.withAlpha(25),
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
