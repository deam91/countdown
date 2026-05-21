import 'package:cached_network_image/cached_network_image.dart';
import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/tier_styles.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:countdown/features/detail/detail_screen.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:countdown/features/ranking/presentation/widgets/place_map_strip.dart';
import 'package:countdown/features/ranking/presentation/widgets/rank_numeral.dart';
import 'package:countdown/features/ranking/presentation/widgets/score_bar.dart';
import 'package:countdown/features/ranking/presentation/widgets/tier_badge.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The single rank card. Dispatches per-kind sub-line + image shape.
/// Top-3 ranks get a tier gradient ring and outer glow.
class RankCard extends StatelessWidget {
  const RankCard({required this.item, super.key});

  /// Base card height used by `CardSkeleton` and non-place items.
  static const double height = 160;

  /// Place cards need extra room for the 40pt map strip below the
  /// address row. Skeleton stays at the base height — a small ~20pt
  /// jump on arrival is acceptable for a place-only minority of cards.
  static const double placeHeight = 180;

  static double heightFor(RankItem item) =>
      item is PlaceItem ? placeHeight : height;

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
      child: Material(
        color: ColorTokens.surfaceElevated,
        borderRadius: Radii.cardRadius,
        child: InkWell(
          borderRadius: Radii.cardRadius,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DetailScreen(item: item),
            ),
          ),
          child: Container(
            height: RankCard.heightFor(item),
            decoration: BoxDecoration(
              borderRadius: Radii.cardRadius,
              border: isTopThree
                  ? null
                  : Border.all(color: ColorTokens.surfaceOutline50),
            ),
            child: ClipRRect(
              borderRadius: Radii.cardRadius,
              child: _CardInner(item: item, rank: _rank, tier: tier),
            ),
          ),
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
        if (item case PlaceItem(:final lat, :final lng))
          PlaceMapStrip(lat: lat, lng: lng),
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

/// Image with a kind-shaped frame. Loads the OpenAI-provided `imageUrl`
/// via `CachedNetworkImage`. Falls back to a tinted gradient + kind icon
/// when the URL is null, still loading, or fails to load.
class _KindImage extends StatelessWidget {
  const _KindImage({required this.item});
  final RankItem item;

  static const double _size = 96;

  int get _rank => item.when(
        place: (rank, _, _, _, _, _, _, _) => rank,
        book: (rank, _, _, _, _, _, _) => rank,
        person: (rank, _, _, _, _, _) => rank,
        generic: (rank, _, _, _, _) => rank,
      );

  @override
  Widget build(BuildContext context) {
    final (width, height, radius) = switch (item) {
      BookItem() => (72.0, _size, Radii.image),
      PersonItem() => (_size, _size, 999.0),
      _ => (_size, _size, Radii.image),
    };

    final url = switch (item) {
      PlaceItem(:final imageUrl) => imageUrl,
      BookItem(:final imageUrl) => imageUrl,
      PersonItem(:final imageUrl) => imageUrl,
      GenericItem(:final imageUrl) => imageUrl,
    };

    final fallback = _PlaceholderFill(kind: item);
    final hasImage = url != null && url.isNotEmpty;

    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ColorTokens.surfaceOutline50),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, _) => fallback,
                errorWidget: (_, failedUrl, error) {
                  debugPrint('[img] failed: $failedUrl ($error)');
                  return fallback;
                },
              )
            : fallback,
      ),
    );

    // Only wrap in Hero when we actually have an image to animate. The
    // placeholder fallback doesn't transition nicely into the detail
    // screen's tier-numeral poster.
    return hasImage ? Hero(tag: 'rank-image-$_rank', child: box) : box;
  }
}

class _PlaceholderFill extends StatelessWidget {
  const _PlaceholderFill({required this.kind});
  final RankItem kind;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      PlaceItem() => LucideIcons.mapPin,
      BookItem() => LucideIcons.bookOpen,
      PersonItem() => LucideIcons.user,
      GenericItem() => LucideIcons.image,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorTokens.brandPrimaryContainer.withValues(alpha: 0.6),
            ColorTokens.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 28, color: ColorTokens.textTertiary),
      ),
    );
  }
}
