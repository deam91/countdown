import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/tier_styles.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:countdown/features/ranking/presentation/widgets/rank_card.dart' show RankCard;
import 'package:countdown/features/ranking/presentation/widgets/tier_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hero-transition destination from a [RankCard] tap. Shows the full
/// "why it ranks" copy, the score, a full map embed for place items,
/// and external link chips (Maps / Google / Wikipedia).
class DetailScreen extends StatelessWidget {
  const DetailScreen({required this.item, super.key});

  final RankItem item;

  int get _rank => item.when(
        place: (rank, _, _, _, _, _, _, _) => rank,
        book: (rank, _, _, _, _, _, _) => rank,
        person: (rank, _, _, _, _, _) => rank,
        generic: (rank, _, _, _, _) => rank,
      );

  String get _title => item.when(
        place: (_, title, _, _, _, _, _, _) => title,
        book: (_, title, _, _, _, _, _) => title,
        person: (_, title, _, _, _, _) => title,
        generic: (_, title, _, _, _) => title,
      );

  String get _whyItRanks => item.when(
        place: (_, _, why, _, _, _, _, _) => why,
        book: (_, _, why, _, _, _, _) => why,
        person: (_, _, why, _, _, _) => why,
        generic: (_, _, why, _, _) => why,
      );

  double get _score => item.when(
        place: (_, _, _, score, _, _, _, _) => score,
        book: (_, _, _, score, _, _, _) => score,
        person: (_, _, _, score, _, _) => score,
        generic: (_, _, _, score, _) => score,
      );

  String? get _imageUrl => switch (item) {
        PlaceItem(:final imageUrl) => imageUrl,
        BookItem(:final imageUrl) => imageUrl,
        PersonItem(:final imageUrl) => imageUrl,
        GenericItem(:final imageUrl) => imageUrl,
      };

  @override
  Widget build(BuildContext context) {
    final tier = TierStyles.forRank(_rank);
    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      appBar: const _GlassBar(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Hero(rank: _rank, tier: tier, imageUrl: _imageUrl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sp4,
              vertical: Spacing.sp4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tier != Tier.neutral) ...[
                  TierBadge(rank: _rank),
                  const SizedBox(height: Spacing.sp3),
                ],
                Text(_title, style: AppTypography.headlineL),
                const SizedBox(height: Spacing.sp2),
                _ScoreRow(score: _score, tier: tier),
                const SizedBox(height: Spacing.sp5),
                Text(_whyItRanks, style: AppTypography.bodyL),
                const SizedBox(height: Spacing.sp6),
                if (item case PlaceItem(:final address, :final lat, :final lng)) ...[
                  Text('Location', style: AppTypography.titleM),
                  const SizedBox(height: Spacing.sp2),
                  Text(address, style: AppTypography.bodyM),
                  const SizedBox(height: Spacing.sp3),
                  _FullMap(lat: lat, lng: lng),
                  const SizedBox(height: Spacing.sp6),
                ],
                _ExternalLinkChips(item: item, title: _title),
                SizedBox(height: MediaQuery.of(context).padding.bottom + Spacing.sp6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Top hero image. Tagged so it transitions from the [RankCard]'s image.
class _Hero extends StatelessWidget {
  const _Hero({required this.rank, required this.tier, required this.imageUrl});

  final int rank;
  final Tier tier;
  final String? imageUrl;

  static const double _height = 320;

  @override
  Widget build(BuildContext context) {
    // When the item has no Wikipedia thumbnail, render an intentional
    // "poster" — a huge tier-colored Fraunces numeral over the surface
    // gradient. Reads as deliberate art, not a broken image.
    final fallback = _NoImagePoster(rank: rank, tier: tier);

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final content = SizedBox(
      height: _height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => fallback,
              errorWidget: (_, _, _) => fallback,
            )
          else
            fallback,
          // Bottom gradient fade into surface.base so the title row
          // below reads cleanly.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.55, 1.0],
                    colors: [
                      Colors.transparent,
                      ColorTokens.surfaceBase,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Only animate when an image is present — the no-image poster
    // doesn't transition nicely from the card's small placeholder.
    return hasImage ? Hero(tag: 'rank-image-$rank', child: content) : content;
  }
}

class _GlassBar extends StatelessWidget implements PreferredSizeWidget {
  const _GlassBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AppBar(
          backgroundColor: ColorTokens.surfaceGlass,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            color: ColorTokens.textPrimary,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.score, required this.tier});

  final double score;
  final Tier tier;

  @override
  Widget build(BuildContext context) {
    final scoreText = score.toStringAsFixed(1);
    final scoreStyle = AppTypography.displayM;
    final styled = tier == Tier.neutral
        ? Text(scoreText, style: scoreStyle)
        : ShaderMask(
            shaderCallback: (r) => TierStyles.gradient(tier).createShader(r),
            blendMode: BlendMode.srcIn,
            child: Text(scoreText, style: scoreStyle),
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        styled,
        Padding(
          padding: const EdgeInsets.only(left: Spacing.sp1, bottom: Spacing.sp3),
          child: Text(
            '/ 10',
            style: AppTypography.bodyL.copyWith(color: ColorTokens.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _FullMap extends StatelessWidget {
  const _FullMap({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return ClipRRect(
      borderRadius: Radii.cardRadius,
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app.countdown.dev',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    LucideIcons.mapPin,
                    size: 36,
                    color: ColorTokens.brandPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExternalLinkChips extends StatelessWidget {
  const _ExternalLinkChips({required this.item, required this.title});

  final RankItem item;
  final String title;

  @override
  Widget build(BuildContext context) {
    final chips = <_LinkChip>[];

    if (item case PlaceItem(:final lat, :final lng)) {
      chips.add(_LinkChip(
        label: 'Open in Maps',
        icon: LucideIcons.map,
        uri: Uri.parse('https://maps.apple.com/?q=$lat,$lng'),
      ));
    }

    chips
      ..add(_LinkChip(
        label: 'Search on Google',
        icon: LucideIcons.search,
        uri: Uri.parse(
          'https://www.google.com/search?q=${Uri.encodeQueryComponent(title)}',
        ),
      ))
      ..add(_LinkChip(
        label: 'Wikipedia',
        icon: LucideIcons.bookOpen,
        uri: Uri.parse(
          'https://en.wikipedia.org/wiki/Special:Search?search='
          '${Uri.encodeQueryComponent(title)}',
        ),
      ));

    return Wrap(
      spacing: Spacing.sp2,
      runSpacing: Spacing.sp2,
      children: chips,
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.label,
    required this.icon,
    required this.uri,
  });

  final String label;
  final IconData icon;
  final Uri uri;

  Future<void> _open() async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Silently fail — the user can long-press to copy if needed.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: Radii.pillRadius,
        side: BorderSide(color: ColorTokens.surfaceOutline),
      ),
      child: InkWell(
        borderRadius: Radii.pillRadius,
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sp3,
            vertical: Spacing.sp2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: ColorTokens.textPrimary),
              const SizedBox(width: Spacing.sp2),
              Text(label, style: AppTypography.labelL),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback for the Detail hero when an item has no Wikipedia thumbnail.
/// A subtle purple-tinted gradient with a massive Fraunces rank numeral
/// centered — tier-gradient-filled on top-3. Reads as deliberate poster
/// art rather than a broken-image placeholder.
class _NoImagePoster extends StatelessWidget {
  const _NoImagePoster({required this.rank, required this.tier});

  final int rank;
  final Tier tier;

  @override
  Widget build(BuildContext context) {
    final numeralStyle = GoogleFonts.fraunces(
      fontSize: 220,
      fontWeight: FontWeight.w600,
      letterSpacing: -8,
      height: 0.9,
      color: ColorTokens.textPrimary,
    );

    Widget numeral = Text(
      '$rank',
      style: numeralStyle,
      textAlign: TextAlign.center,
    );
    if (tier != Tier.neutral) {
      numeral = ShaderMask(
        shaderCallback: (r) => TierStyles.gradient(tier).createShader(r),
        blendMode: BlendMode.srcIn,
        child: numeral,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorTokens.brandPrimaryContainer.withValues(alpha: 0.5),
            ColorTokens.surfaceElevated,
          ],
        ),
      ),
      child: Center(child: numeral),
    );
  }
}
