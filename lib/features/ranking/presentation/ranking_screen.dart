import 'dart:async';
import 'dart:ui';

import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/motion.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:countdown/features/ranking/domain/ranking_state.dart';
import 'package:countdown/features/ranking/presentation/ranking_controller.dart';
import 'package:countdown/features/ranking/presentation/widgets/card_skeleton.dart';
import 'package:countdown/features/ranking/presentation/widgets/rank_card.dart';
import 'package:countdown/features/ranking/presentation/widgets/rank_one_reveal.dart';
import 'package:countdown/features/ranking/presentation/widgets/reveal_animator.dart';
import 'package:countdown/features/ranking/presentation/widgets/status_sub_header.dart';
import 'package:countdown/features/share/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:screenshot/screenshot.dart';

/// The countdown reveal screen. Watches [rankingControllerProvider] and
/// kicks off the request on first mount.
class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({required this.query, this.n = 10, super.key});

  final String query;
  final int n;

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(rankingControllerProvider.notifier).ask(widget.query, n: widget.n),
      );
    });
  }

  Future<void> _handleShare() async {
    final bytes = await _screenshotController.capture(pixelRatio: 3);
    if (!mounted || bytes == null) return;
    try {
      await ShareService.shareScreenshot(bytes, query: widget.query);
    } on Object {
      // User canceled the share sheet, or a platform error fired.
      // Either way, no UI feedback needed — Share is a passive action.
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rankingControllerProvider);
    final items = switch (state) {
      RankingStreaming(:final partial) => partial,
      RankingDone(:final ranking) => ranking.items,
      _ => <RankItem>[],
    };
    final isDone = state is RankingDone;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ColorTokens.surfaceBase,
      appBar: _GlassAppBar(
        query: widget.query,
        shareEnabled: isDone,
        onShare: isDone ? _handleShare : null,
      ),
      body: Stack(
        children: [
          // Screenshot wraps just the background + cards so the bottom
          // bar isn't baked into the shared image.
          Screenshot(
            controller: _screenshotController,
            child: Stack(
              children: [
                _RevealBackgroundGlow(active: isDone || _hasRankOne(items)),
                ListView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight,
                    left: Spacing.sp4,
                    right: Spacing.sp4,
                    // Reserve room for the sticky _DoneBottomBar (~96pt incl. safe-area).
                    bottom: MediaQuery.of(context).padding.bottom + 96 + Spacing.sp4,
                  ),
                  children: [
                    StatusSubHeader(state: state, targetN: widget.n),
                    ..._buildSlots(items, state),
                  ],
                ),
              ],
            ),
          ),
          if (isDone) _DoneBottomBar(onShare: _handleShare),
        ],
      ),
    );
  }

  List<Widget> _buildSlots(List<RankItem> items, RankingState state) {
    final children = <Widget>[];

    // Error replaces the list entirely.
    if (state is RankingError) {
      children.add(_ErrorPanel(error: state.error.message));
      return children;
    }

    // Reveal in countdown order — items arrive rank N → rank 1 from the
    // data layer; we keep that vertical order so the user scrolls down to
    // discover #1. #1 gets its own widget that defers reveal + confetti
    // until it actually enters the viewport.
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final rank = _rankOf(item);
      final card = RankCard(item: item);
      children
        ..add(
          rank == 1
              ? RankOneReveal(key: const ValueKey('rank-1'), child: card)
              : RevealAnimator(
                  key: ValueKey('rank-$rank'),
                  rank: rank,
                  child: card,
                ),
        )
        ..add(const SizedBox(height: Spacing.sp3));
    }

    // Skeletons for un-arrived slots (only when loading / streaming).
    final remaining = switch (state) {
      RankingLoading() ||
      RankingStreaming() =>
        (widget.n - items.length).clamp(0, widget.n),
      _ => 0,
    };
    for (var i = 0; i < remaining; i++) {
      children
        ..add(const CardSkeleton())
        ..add(const SizedBox(height: Spacing.sp3));
    }

    return children;
  }

  int _rankOf(RankItem i) => i.when(
        place: (rank, _, _, _, _, _, _, _) => rank,
        book: (rank, _, _, _, _, _, _) => rank,
        person: (rank, _, _, _, _, _) => rank,
        generic: (rank, _, _, _, _) => rank,
      );

  bool _hasRankOne(List<RankItem> items) => items.any((i) => _rankOf(i) == 1);
}

class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _GlassAppBar({
    required this.query,
    required this.shareEnabled,
    this.onShare,
  });

  final String query;
  final bool shareEnabled;
  final VoidCallback? onShare;

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
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            color: ColorTokens.textSecondary,
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            query,
            style: AppTypography.labelL.copyWith(
              fontStyle: FontStyle.italic,
              color: ColorTokens.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.share2),
              color: shareEnabled
                  ? ColorTokens.textPrimary
                  : ColorTokens.textTertiary,
              onPressed: shareEnabled ? onShare : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealBackgroundGlow extends StatelessWidget {
  const _RevealBackgroundGlow({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 800),
      curve: Motion.easeOut,
      opacity: active ? 1 : 0,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 1.1,
              colors: [
                ColorTokens.gold1.withValues(alpha: 0.06),
                ColorTokens.gold1.withValues(alpha: 0),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _DoneBottomBar extends ConsumerWidget {
  const _DoneBottomBar({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.only(
              left: Spacing.sp4,
              right: Spacing.sp4,
              top: Spacing.sp3,
              bottom: MediaQuery.of(context).padding.bottom + Spacing.sp3,
            ),
            color: ColorTokens.surfaceGlass,
            child: Row(
              children: [
                Expanded(
                  child: _PillButton(
                    label: 'Share',
                    icon: LucideIcons.share2,
                    filled: true,
                    onTap: onShare,
                  ),
                ),
                const SizedBox(width: Spacing.sp3),
                Expanded(
                  child: _PillButton(
                    label: 'Ask another',
                    icon: LucideIcons.rotateCw,
                    filled: false,
                    onTap: () {
                      // Only reset + pop when there's somewhere to go back to.
                      // Avoids destroying state on a screen that's the root.
                      if (!Navigator.canPop(context)) return;
                      ref.read(rankingControllerProvider.notifier).reset();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? ColorTokens.brandOnPrimary : ColorTokens.textPrimary;
    return Material(
      color: filled ? ColorTokens.brandPrimary : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.pillRadius,
        side: filled
            ? BorderSide.none
            : const BorderSide(color: ColorTokens.surfaceOutline),
      ),
      child: InkWell(
        borderRadius: Radii.pillRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sp3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: Spacing.sp2),
              Text(
                label,
                style: AppTypography.labelL.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.sp4),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceElevated,
        borderRadius: Radii.cardRadius,
        border: Border.all(color: ColorTokens.surfaceOutline50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Something went wrong',
            style: AppTypography.titleL.copyWith(color: ColorTokens.stateError),
          ),
          const SizedBox(height: Spacing.sp2),
          Text(error, style: AppTypography.bodyM),
        ],
      ),
    );
  }
}
