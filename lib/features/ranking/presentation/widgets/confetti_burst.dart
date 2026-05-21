import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:countdown/core/theme/color_tokens.dart';
import 'package:flutter/material.dart';

/// Two upward gold confetti emitters at the bottom-left and bottom-right
/// corners of the GOLD card. They fan slightly outward (15° off straight
/// up), spray dense particles, and fade naturally as gravity pulls them
/// back down. Plays once on mount.
///
/// Designed to live inside a `Positioned.fill` so it spans the card area;
/// the controllers are anchored to the card's bottom corners.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> {
  static const Duration _duration = Duration(milliseconds: 1500);
  final ConfettiController _left = ConfettiController(duration: _duration);
  final ConfettiController _right = ConfettiController(duration: _duration);

  // Straight up = -π/2. ±π/12 (≈ 15°) gives a gentle fan outward.
  static const double _up = -math.pi / 2;
  static const double _fan = math.pi / 12;

  static const List<Color> _colors = [
    ColorTokens.gold1,
    ColorTokens.gold2,
    ColorTokens.brandTertiary,
  ];

  @override
  void initState() {
    super.initState();
    _left.play();
    _right.play();
  }

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom-left corner — fires up + slightly right.
          Positioned(
            bottom: 0,
            left: 0,
            child: _emitter(_left, blastDirection: _up + _fan),
          ),
          // Bottom-right corner — fires up + slightly left.
          Positioned(
            bottom: 0,
            right: 0,
            child: _emitter(_right, blastDirection: _up - _fan),
          ),
        ],
      ),
    );
  }

  Widget _emitter(
    ConfettiController controller, {
    required double blastDirection,
  }) {
    return ConfettiWidget(
      confettiController: controller,
      blastDirection: blastDirection,
      numberOfParticles: 40,
      gravity: 0.25,
      maxBlastForce: 30,
      minBlastForce: 14,
      minimumSize: const Size(6, 6),
      maximumSize: const Size(14, 14),
      colors: _colors,
    );
  }
}
