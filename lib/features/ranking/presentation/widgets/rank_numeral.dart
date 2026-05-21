import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/tier_styles.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:flutter/material.dart';

/// The big Fraunces serif numeral on the left strip of every rank card.
/// Top-3 ranks render in `displayL` (72) with a tier gradient fill;
/// ranks 4+ render in `displayM` (48) in `text.primary`.
class RankNumeral extends StatelessWidget {
  const RankNumeral({required this.rank, super.key});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final tier = TierStyles.forRank(rank);
    final isTopThree = tier != Tier.neutral;
    final style = isTopThree
        ? AppTypography.displayL.copyWith(color: ColorTokens.brandOnPrimary)
        : AppTypography.displayM.copyWith(color: ColorTokens.textPrimary);

    final text = Text(
      '$rank',
      style: style,
      textAlign: TextAlign.center,
    );

    if (!isTopThree) return text;

    return ShaderMask(
      shaderCallback: (rect) => TierStyles.gradient(tier).createShader(rect),
      blendMode: BlendMode.srcIn,
      child: text,
    );
  }
}
