import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A 140pt-tall shimmer skeleton matching the rank-card silhouette.
/// Shown for slots that haven't been streamed yet.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final block = ColorTokens.surfaceOutline.withValues(alpha: 0.35);

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: ColorTokens.surfaceElevated,
        borderRadius: Radii.cardRadius,
        border: Border.all(color: ColorTokens.surfaceOutline50),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [block, block.withValues(alpha: 0.05)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Radii.card),
                bottomLeft: Radius.circular(Radii.card),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sp4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bar(width: 180, height: 14, color: block),
                  _bar(width: 240, height: 10, color: block),
                  _bar(width: double.infinity, height: 4, color: block),
                ],
              ),
            ),
          ),
          const SizedBox(width: Spacing.sp4),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: block,
              borderRadius: Radii.imageRadius,
            ),
          ),
          const SizedBox(width: Spacing.sp4),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: const Duration(milliseconds: 1400),
          color: ColorTokens.surfaceOutline.withValues(alpha: 0.4),
        );
  }

  Widget _bar({required double width, required double height, required Color color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
