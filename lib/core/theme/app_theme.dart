import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'text_styles.dart';

/// Application-wide theme definitions.
class AppTheme {
  /// Light theme (default)
  static ThemeData light = ThemeData(
    colorScheme: lightColorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: lightColorScheme.background,
    textTheme: TextTheme(
      headlineSmall: AppTextStyles.headline,
      titleMedium: AppTextStyles.title,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
    ),
  );

  /// Dark theme
  static ThemeData dark = ThemeData(
    colorScheme: darkColorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: darkColorScheme.background,
    textTheme: TextTheme(
      headlineSmall: AppTextStyles.headline.copyWith(color: Colors.white),
      titleMedium: AppTextStyles.title.copyWith(color: Colors.white70),
      bodyMedium: AppTextStyles.body.copyWith(color: Colors.white),
      bodySmall: AppTextStyles.caption.copyWith(color: Colors.white54),
    ),
  );
}
