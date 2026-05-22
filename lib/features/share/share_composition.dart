import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/tier_styles.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:countdown/features/ranking/domain/ranking.dart';
import 'package:flutter/material.dart';

/// 9:16 portrait composition rendered off-screen for Share output.
///
/// Lays out the whole ranking on a single 1080×1920 PNG: header with
/// the user's query + brand wordmark, all N cards stacked at small
/// scale (top-3 retain tier color treatment), and a footer wordmark.
///
/// Designed for Instagram-Stories-style aspect ratio. The widget is
/// laid out at a logical 360×640 then `ScreenshotController` captures
/// it at `pixelRatio: 3` → 1080×1920.
class ShareComposition extends StatelessWidget {
  const ShareComposition({required this.ranking, super.key});

  final Ranking ranking;

  static const double logicalWidth = 360;
  static const double logicalHeight = 640;

  @override
  Widget build(BuildContext context) {
    // Items arrive 10 → 1 from the data layer; reverse so #1 sits at
    // the top of the share image, which is the more readable order at
    // a glance.
    final ordered = [...ranking.items]..sort((a, b) => _rank(a) - _rank(b));

    return Material(
      color: ColorTokens.surfaceBase,
      child: SizedBox(
        width: logicalWidth,
        height: logicalHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _Background(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.sp4,
                Spacing.sp5,
                Spacing.sp4,
                Spacing.sp3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(query: ranking.query),
                  const SizedBox(height: Spacing.sp3),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final item in ordered) _MiniRow(item: item),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.sp2),
                  const _Footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _rank(RankItem i) => switch (i) {
        PlaceItem(:final rank) => rank,
        BookItem(:final rank) => rank,
        PersonItem(:final rank) => rank,
        GenericItem(:final rank) => rank,
      };
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.1,
            colors: [
              ColorTokens.brandPrimary.withValues(alpha: 0.22),
              ColorTokens.brandPrimary.withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Countdown',
              style: AppTypography.titleL.copyWith(
                fontFamily: AppTypography.displayM.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                color: ColorTokens.brandPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          query,
          style: AppTypography.bodyM.copyWith(
            fontStyle: FontStyle.italic,
            color: ColorTokens.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.item});

  final RankItem item;

  @override
  Widget build(BuildContext context) {
    final rank = ShareComposition._rank(item);
    final tier = TierStyles.forRank(rank);
    final isTopThree = tier != Tier.neutral;

    return Container(
      decoration: BoxDecoration(
        borderRadius: Radii.cardRadius,
        color: ColorTokens.surfaceElevated,
        border: Border.all(
          color: isTopThree
              ? _tierColor(tier).withValues(alpha: 0.7)
              : ColorTokens.surfaceOutline50,
          width: isTopThree ? 1.5 : 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Tier accent strip on the left edge of top-3 rows.
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: isTopThree
                    ? TierStyles.gradient(tier)
                    : null,
                color: isTopThree ? null : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: Spacing.sp3),
            SizedBox(
              width: 32,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: AppTypography.titleL.copyWith(
                  fontFamily: AppTypography.displayM.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  color: isTopThree
                      ? _tierColor(tier)
                      : ColorTokens.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: Spacing.sp3),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _title(item),
                      style: AppTypography.titleM.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _whyItRanks(item),
                      style: AppTypography.caption.copyWith(
                        color: ColorTokens.textTertiary,
                        fontSize: 10,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Spacing.sp2),
          ],
        ),
      ),
    );
  }

  static String _title(RankItem i) => switch (i) {
        PlaceItem(:final title) => title,
        BookItem(:final title) => title,
        PersonItem(:final title) => title,
        GenericItem(:final title) => title,
      };

  static String _whyItRanks(RankItem i) => switch (i) {
        PlaceItem(:final whyItRanks) => whyItRanks,
        BookItem(:final whyItRanks) => whyItRanks,
        PersonItem(:final whyItRanks) => whyItRanks,
        GenericItem(:final whyItRanks) => whyItRanks,
      };

  static Color _tierColor(Tier t) => switch (t) {
        Tier.gold => ColorTokens.gold1,
        Tier.silver => ColorTokens.silver1,
        Tier.bronze => ColorTokens.bronze1,
        Tier.neutral => ColorTokens.brandPrimary,
      };
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'made with Countdown',
          style: AppTypography.caption.copyWith(
            color: ColorTokens.textTertiary,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(bottom: 3),
          decoration: const BoxDecoration(
            color: ColorTokens.brandPrimary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
