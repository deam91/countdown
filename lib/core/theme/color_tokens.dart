import 'package:flutter/material.dart';

/// Color tokens — ported 1:1 from design/tokens.css.
/// Never hardcode colors in widgets; always reference through these.
abstract final class ColorTokens {
  // Brand
  static const brandPrimary = Color(0xFF6750A4);
  static const brandPrimaryContainer = Color(0xFF4F378B);
  static const brandSecondary = Color(0xFF9A82DB);
  static const brandTertiary = Color(0xFFEFB8C8);
  static const brandOnPrimary = Color(0xFFFFFFFF);

  // Surfaces
  static const surfaceBase = Color(0xFF141218);
  static const surfaceElevated = Color(0xFF1D1B20);
  static const surfaceGlass = Color(0xB326232A); // 70% alpha
  static const surfaceOutline = Color(0xFF49454F);
  static const surfaceOutline50 = Color(0x8049454F);

  // Text
  static const textPrimary = Color(0xFFE6E0E9);
  static const textSecondary = Color(0xFFCAC4D0);
  static const textTertiary = Color(0xFF938F99);

  // State
  static const stateError = Color(0xFFF2B8B5);
  static const stateSuccess = Color(0xFFA5E8B6);

  // Tier 1 — Gold
  static const gold1 = Color(0xFFF5C46A);
  static const gold2 = Color(0xFFC9892A);
  static const goldGlow = Color(0x8CF5C46A);

  // Tier 2 — Silver
  static const silver1 = Color(0xFFE5E4EA);
  static const silver2 = Color(0xFFA6A4B0);
  static const silverGlow = Color(0x73E5E4EA);

  // Tier 3 — Bronze
  static const bronze1 = Color(0xFFD89B7B);
  static const bronze2 = Color(0xFF9B5A3B);
  static const bronzeGlow = Color(0x80D89B7B);
}
