import 'package:flutter/widgets.dart';

/// Radius tokens.
abstract final class Radii {
  static const double card = 20;
  static const double pill = 999;
  static const double button = 16;
  static const double input = 28;
  static const double image = 12;

  static const cardRadius = BorderRadius.all(Radius.circular(card));
  static const pillRadius = BorderRadius.all(Radius.circular(pill));
  static const buttonRadius = BorderRadius.all(Radius.circular(button));
  static const inputRadius = BorderRadius.all(Radius.circular(input));
  static const imageRadius = BorderRadius.all(Radius.circular(image));
}
