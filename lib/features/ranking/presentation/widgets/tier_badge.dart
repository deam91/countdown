import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/tier_styles.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:flutter/material.dart';

/// Gold/silver/bronze pill shown above the title on top-3 cards.
/// Hidden for ranks 4+.
class TierBadge extends StatelessWidget {
  const TierBadge({required this.rank, super.key});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final tier = TierStyles.forRank(rank);
    if (tier == Tier.neutral) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sp3,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: TierStyles.gradient(tier),
        borderRadius: Radii.pillRadius,
      ),
      child: Text(
        TierStyles.label(tier),
        style: AppTypography.labelL.copyWith(
          color: ColorTokens.surfaceBase,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
