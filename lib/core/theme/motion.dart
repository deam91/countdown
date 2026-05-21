import 'package:flutter/animation.dart';

/// Motion tokens — durations and curves.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 280);
  static const Duration emphasized = Duration(milliseconds: 450);
  static const Duration dramatic = Duration(milliseconds: 700);
  static const Duration stagger = Duration(milliseconds: 60);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve dramaticCurve = Curves.easeOutQuart;
}
