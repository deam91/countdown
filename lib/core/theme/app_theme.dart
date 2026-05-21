import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:flutter/material.dart';

/// Material 3 theme seeded from brand.primary (#6750A4), then overridden
/// with our custom neutrals so it doesn't feel stock-Material.
abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorTokens.brandPrimary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: ColorTokens.brandPrimary,
        primaryContainer: ColorTokens.brandPrimaryContainer,
        secondary: ColorTokens.brandSecondary,
        tertiary: ColorTokens.brandTertiary,
        surface: ColorTokens.surfaceBase,
        onPrimary: ColorTokens.brandOnPrimary,
        onSurface: ColorTokens.textPrimary,
        outline: ColorTokens.surfaceOutline,
        error: ColorTokens.stateError,
      ),
      scaffoldBackgroundColor: ColorTokens.surfaceBase,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: AppTypography.displayL,
        displayMedium: AppTypography.displayM,
        headlineLarge: AppTypography.headlineL,
        titleLarge: AppTypography.titleL,
        titleMedium: AppTypography.titleM,
        bodyLarge: AppTypography.bodyL,
        bodyMedium: AppTypography.bodyM,
        labelLarge: AppTypography.labelL,
        bodySmall: AppTypography.caption,
      ),
    );
  }
}
