import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme {
    final ColorScheme baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.dark,
    );
    final TextTheme textTheme = _baseTextTheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: baseScheme.copyWith(
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.surfaceVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final ColorScheme baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.light,
    );
    final TextTheme textTheme = _baseTextTheme(Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: baseScheme,
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static TextTheme _baseTextTheme(Brightness brightness) {
    final TextTheme base = ThemeData(brightness: brightness).textTheme;
    return base.copyWith(
      displayLarge: GoogleFonts.rajdhani(textStyle: base.displayLarge),
      displayMedium: GoogleFonts.rajdhani(textStyle: base.displayMedium),
      displaySmall: GoogleFonts.rajdhani(textStyle: base.displaySmall),
      headlineLarge: GoogleFonts.rajdhani(textStyle: base.headlineLarge),
      headlineMedium: GoogleFonts.rajdhani(textStyle: base.headlineMedium),
      headlineSmall: GoogleFonts.rajdhani(textStyle: base.headlineSmall),
      titleLarge: GoogleFonts.rajdhani(textStyle: base.titleLarge),
      titleMedium: GoogleFonts.inter(textStyle: base.titleMedium),
      titleSmall: GoogleFonts.inter(textStyle: base.titleSmall),
      bodyLarge: GoogleFonts.inter(textStyle: base.bodyLarge),
      bodyMedium: GoogleFonts.inter(textStyle: base.bodyMedium),
      bodySmall: GoogleFonts.inter(textStyle: base.bodySmall),
      labelLarge: GoogleFonts.inter(textStyle: base.labelLarge),
      labelMedium: GoogleFonts.inter(textStyle: base.labelMedium),
      labelSmall: GoogleFonts.inter(textStyle: base.labelSmall),
    );
  }
}
