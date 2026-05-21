import 'package:countdown/core/theme/color_tokens.dart';
import 'package:flutter/material.dart';

enum Tier { gold, silver, bronze, neutral }

/// Tier-1/2/3 visual treatment — gradients, glows, badge labels.
abstract final class TierStyles {
  static Tier forRank(int rank) => switch (rank) {
        1 => Tier.gold,
        2 => Tier.silver,
        3 => Tier.bronze,
        _ => Tier.neutral,
      };

  static LinearGradient gradient(Tier t) {
    return switch (t) {
      Tier.gold => const LinearGradient(
          colors: [ColorTokens.gold1, ColorTokens.gold2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      Tier.silver => const LinearGradient(
          colors: [ColorTokens.silver1, ColorTokens.silver2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      Tier.bronze => const LinearGradient(
          colors: [ColorTokens.bronze1, ColorTokens.bronze2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      Tier.neutral => LinearGradient(
          colors: [
            ColorTokens.brandPrimary.withValues(alpha: 0.3),
            ColorTokens.brandPrimary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
    };
  }

  static Color glow(Tier t) {
    return switch (t) {
      Tier.gold => ColorTokens.goldGlow,
      Tier.silver => ColorTokens.silverGlow,
      Tier.bronze => ColorTokens.bronzeGlow,
      Tier.neutral => Colors.transparent,
    };
  }

  static double glowBlur(Tier t) {
    return switch (t) {
      Tier.gold => 24,
      Tier.silver => 20,
      Tier.bronze => 16,
      Tier.neutral => 0,
    };
  }

  static String label(Tier t) {
    return switch (t) {
      Tier.gold => 'GOLD',
      Tier.silver => 'SILVER',
      Tier.bronze => 'BRONZE',
      Tier.neutral => '',
    };
  }
}
