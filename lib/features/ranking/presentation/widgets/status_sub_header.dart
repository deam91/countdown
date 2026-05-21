import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:countdown/features/ranking/domain/ranking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Live status caption shown just under the app bar.
class StatusSubHeader extends StatelessWidget {
  const StatusSubHeader({required this.state, required this.targetN, super.key});

  final RankingState state;
  final int targetN;

  @override
  Widget build(BuildContext context) {
    final (text, showDots) = switch (state) {
      RankingLoading() => ('Asking GPT…', true),
      RankingStreaming(:final partial) =>
        ('Revealing ${partial.length} of $targetN…', true),
      RankingDone() => ('Tap any rank for details', false),
      RankingError() => ('', false),
      RankingIdle() => ('', false),
    };

    if (text.isEmpty) return const SizedBox(height: Spacing.sp4);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sp4,
        vertical: Spacing.sp3,
      ),
      child: Row(
        children: [
          if (showDots) const _Dots(),
          if (showDots) const SizedBox(width: Spacing.sp2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: const _Dot()
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(
                duration: const Duration(milliseconds: 350),
                delay: Duration(milliseconds: i * 120),
              ),
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: ColorTokens.brandSecondary,
        shape: BoxShape.circle,
      ),
    );
  }
}
