import 'package:confetti/confetti.dart';
import 'package:countdown/core/theme/color_tokens.dart';
import 'package:flutter/material.dart';

/// Gold confetti burst overlaid on #1 reveal. Plays once and fades out.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> {
  final _controller = ConfettiController(duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 12,
          gravity: 0.45,
          maxBlastForce: 14,
          minBlastForce: 6,
          emissionFrequency: 0.04,
          colors: const [
            ColorTokens.gold1,
            ColorTokens.gold2,
            ColorTokens.brandTertiary,
          ],
        ),
      ),
    );
  }
}
