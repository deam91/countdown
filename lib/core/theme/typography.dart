import 'package:countdown/core/theme/color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type ramp — Fraunces (display) + Inter (UI).
abstract final class AppTypography {
  static TextStyle get displayL => GoogleFonts.fraunces(
        fontSize: 72,
        height: 0.95,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.4,
        color: ColorTokens.textPrimary,
      );

  static TextStyle get displayM => GoogleFonts.fraunces(
        fontSize: 48,
        height: 1,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.96,
        color: ColorTokens.textPrimary,
      );

  static TextStyle get headlineL => GoogleFonts.inter(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.28,
        color: ColorTokens.textPrimary,
      );

  static TextStyle get titleL => GoogleFonts.inter(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: ColorTokens.textPrimary,
      );

  static TextStyle get titleM => GoogleFonts.inter(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
      );

  static TextStyle get bodyL => GoogleFonts.inter(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: ColorTokens.textPrimary,
      );

  static TextStyle get bodyM => GoogleFonts.inter(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: ColorTokens.textSecondary,
      );

  static TextStyle get labelL => GoogleFonts.inter(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.13,
        color: ColorTokens.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w400,
        color: ColorTokens.textSecondary,
      );
}
