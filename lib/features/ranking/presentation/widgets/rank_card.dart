import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/tier_styles.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:countdown/features/ranking/presentation/widgets/rank_numeral.dart';
import 'package:countdown/features/ranking/presentation/widgets/score_bar.dart';
import 'package:countdown/features/ranking/presentation/widgets/tier_badge.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The single rank card. Dispatches per-kind sub-line + image shape.
/// Top-3 ranks get a tier gradient ring and outer glow.
class RankCard extends StatelessWidget {
  const RankCard({required this.item, super.key});

  final RankItem item;

  int get _rank => item.when(
        place: (rank, _, _, _, _, _, _, _) => rank,
        book: (rank, _, _, _, _, _, _) => rank,
        person: (rank, _, _, _, _, _) => rank,
        generic: (rank, _, _, _, _) => rank,
      );

  @override
  Widget build(BuildContext context) {
    final tier = TierStyles.forRank(_rank);
    final isTopThree = tier != Tier.neutral;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: Radii.cardRadius,
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: TierStyles.glow(tier),
                  blurRadius: TierStyles.glowBlur(tier),
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: ColorTokens.surfaceElevated,
          borderRadius: Radii.cardRadius,
          border: isTopThree
              ? null
              : Border.all(color: ColorTokens.surfaceOutline50),
          gradient: isTopThree
              ? const LinearGradient(
                  colors: [
                    ColorTokens.surfaceElevated,
                    ColorTokens.surfaceElevated,
                  ],
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: Radii.cardRadius,
          child: _CardInner(item: item, rank: _rank, tier: tier),
        ),
      ),
    );
  }
}

class _CardInner extends StatelessWidget {
  const _CardInner({required this.item, required this.rank, required this.tier});

  final RankItem item;
  final int rank;
  final Tier tier;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tier gradient ring (top-3 only) — drawn as a 2px outline.
        if (tier != Tier.neutral)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: Radii.cardRadius,
                  border: Border.fromBorderSide(
                    BorderSide(color: _ringColor(tier), width: 2),
                  ),
                ),
              ),
            ),
          ),
        Row(
          children: [
            _LeftStrip(rank: rank, tier: tier),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sp4,
                  vertical: Spacing.sp3,
                ),
                child: _CardBody(item: item, rank: rank, tier: tier),
              ),
            ),
            const SizedBox(width: Spacing.sp4),
            _KindImage(item: item),
            const SizedBox(width: Spacing.sp4),
          ],
        ),
      ],
    );
  }

  Color _ringColor(Tier t) => switch (t) {
        Tier.gold => ColorTokens.gold1,
        Tier.silver => ColorTokens.silver1,
        Tier.bronze => ColorTokens.bronze1,
        Tier.neutral => ColorTokens.surfaceOutline,
      };
}

class _LeftStrip extends StatelessWidget {
  const _LeftStrip({required this.rank, required this.tier});
  final int rank;
  final Tier tier;

  @override
  Widget build(BuildContext context) {
    final gradient = tier == Tier.neutral
        ? LinearGradient(
            colors: [
              ColorTokens.brandPrimary.withValues(alpha: 0.30),
              ColorTokens.brandPrimary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: [
              _ringColor(tier).withValues(alpha: 0.25),
              _ringColor(tier).withValues(alpha: 0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Container(
      width: 80,
      decoration: BoxDecoration(gradient: gradient),
      alignment: Alignment.center,
      child: RankNumeral(rank: rank),
    );
  }

  Color _ringColor(Tier t) => switch (t) {
        Tier.gold => ColorTokens.gold1,
        Tier.silver => ColorTokens.silver1,
        Tier.bronze => ColorTokens.bronze1,
        Tier.neutral => ColorTokens.surfaceOutline,
      };
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.item, required this.rank, required this.tier});

  final RankItem item;
  final int rank;
  final Tier tier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (tier != Tier.neutral) ...[
          TierBadge(rank: rank),
          const SizedBox(height: Spacing.sp1),
        ],
        Text(
          _title(item),
          style: AppTypography.titleL,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        _SubLine(item: item),
        Text(
          _whyItRanks(item),
          style: AppTypography.bodyM,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        ScoreBar(score: _score(item), tier: tier),
      ],
    );
  }

  String _title(RankItem i) => i.when(
        place: (_, title, _, _, _, _, _, _) => title,
        book: (_, title, _, _, _, _, _) => title,
        person: (_, title, _, _, _, _) => title,
        generic: (_, title, _, _, _) => title,
      );

  String _whyItRanks(RankItem i) => i.when(
        place: (_, _, why, _, _, _, _, _) => why,
        book: (_, _, why, _, _, _, _) => why,
        person: (_, _, why, _, _, _) => why,
        generic: (_, _, why, _, _) => why,
      );

  double _score(RankItem i) => i.when(
        place: (_, _, _, score, _, _, _, _) => score,
        book: (_, _, _, score, _, _, _) => score,
        person: (_, _, _, score, _, _) => score,
        generic: (_, _, _, score, _) => score,
      );
}

class _SubLine extends StatelessWidget {
  const _SubLine({required this.item});
  final RankItem item;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      PlaceItem(:final address) => Row(
          children: [
            const Icon(
              LucideIcons.mapPin,
              size: 14,
              color: ColorTokens.textSecondary,
            ),
            const SizedBox(width: Spacing.sp1),
            Expanded(
              child: Text(
                address,
                style: AppTypography.bodyM,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      BookItem(:final author, :final year) => Text(
          year != null ? 'by $author · $year' : 'by $author',
          style: AppTypography.bodyM,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      PersonItem(:final tagline) => Text(
          tagline,
          style: AppTypography.bodyM.copyWith(fontStyle: FontStyle.italic),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      GenericItem() => const SizedBox.shrink(),
    };
  }
}

/// Image with a kind-shaped frame. Until image_enricher lands, shows
/// a tinted gradient placeholder.
class _KindImage extends StatelessWidget {
  const _KindImage({required this.item});
  final RankItem item;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    final shape = switch (item) {
      BookItem() => const _ImageShape(width: 72, height: _size, radius: Radii.image),
      PersonItem() => const _ImageShape(width: _size, height: _size, radius: 999),
      _ => const _ImageShape(width: _size, height: _size, radius: Radii.image),
    };
    return shape;
  }
}

class _ImageShape extends StatelessWidget {
  const _ImageShape({
    required this.width,
    required this.height,
    required this.radius,
  });
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorTokens.brandPrimaryContainer.withValues(alpha: 0.6),
            ColorTokens.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ColorTokens.surfaceOutline50),
      ),
    );
  }
}
