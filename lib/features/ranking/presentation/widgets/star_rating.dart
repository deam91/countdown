import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/motion.dart';
import 'package:countdown/core/theme/tier_styles.dart';
import 'package:flutter/material.dart';

/// Five-star rating row used in place of `ScoreBar` on `BookItem`.
///
/// Maps a 0-10 score to a 0-5 visual fill. Renders 5 outlined stars
/// with a colored overlay that animates in over `Motion.standard`,
/// matching the score bar's reveal timing. The overlay is clipped to
/// `score/2 / 5` of the row width, so a 8.6 → 4.3 stars (4 full + a
/// partial fifth) without needing a separate "half-star" glyph.
class StarRating extends StatelessWidget {
  const StarRating({required this.score, required this.tier, super.key});

  /// Score on the 0-10 scale (same scale as `ScoreBar`).
  final double score;
  final Tier tier;

  static const int _count = 5;
  static const double _starSize = 16;
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final fillFraction = (score / 10).clamp(0.0, 1.0);
    final activeColor = tier == Tier.neutral
        ? ColorTokens.brandSecondary
        : _tierColor(tier);

    const rowWidth = _starSize * _count + _gap * (_count - 1);

    return SizedBox(
      width: rowWidth,
      height: _starSize,
      child: Stack(
        children: [
          // Base outlined row.
          const _StarsRow(
            color: ColorTokens.surfaceOutline,
            filled: false,
          ),
          // Animated colored overlay clipped to the fill fraction.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fillFraction),
            duration: Motion.standard,
            curve: Motion.easeOut,
            builder: (_, value, _) => ClipRect(
              clipper: _RectClipper(fraction: value),
              child: _StarsRow(color: activeColor, filled: true),
            ),
          ),
        ],
      ),
    );
  }

  static Color _tierColor(Tier t) => switch (t) {
        Tier.gold => ColorTokens.gold1,
        Tier.silver => ColorTokens.silver1,
        Tier.bronze => ColorTokens.bronze1,
        Tier.neutral => ColorTokens.brandSecondary,
      };
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(StarRating._count, (i) {
        return Padding(
          padding: EdgeInsets.only(
            left: i == 0 ? 0 : StarRating._gap,
          ),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: StarRating._starSize,
            color: color,
          ),
        );
      }),
    );
  }
}

/// Clips children to the left `fraction` of the row, allowing partial
/// star fills (e.g. 8.6/10 → 4.3 stars rendered as 4 full + 30% of #5).
class _RectClipper extends CustomClipper<Rect> {
  const _RectClipper({required this.fraction});

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(covariant _RectClipper old) => old.fraction != fraction;
}
