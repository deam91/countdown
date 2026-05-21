import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/motion.dart';
import 'package:countdown/core/theme/tier_styles.dart';
import 'package:flutter/material.dart';

/// 4px-tall animated score bar. Fills from 0 → score/10 over 280ms,
/// 200ms after the card lands (delay caller-controlled).
class ScoreBar extends StatelessWidget {
  const ScoreBar({required this.score, required this.tier, super.key});

  final double score;
  final Tier tier;

  @override
  Widget build(BuildContext context) {
    final fillFraction = (score / 10).clamp(0.0, 1.0);
    final gradient = tier == Tier.neutral
        ? LinearGradient(
            colors: [
              ColorTokens.brandPrimary.withValues(alpha: 0.9),
              ColorTokens.brandSecondary,
            ],
          )
        : TierStyles.gradient(tier);

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(2)),
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            Container(color: ColorTokens.surfaceOutline50),
            FractionallySizedBox(
              widthFactor: 1,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fillFraction),
                duration: Motion.standard,
                curve: Motion.easeOut,
                builder: (_, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: gradient),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
