import 'dart:async';
import 'dart:ui';

import 'package:countdown/core/theme/motion.dart';
import 'package:countdown/features/ranking/presentation/widgets/confetti_burst.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Defers the dramatic reveal + confetti + medium haptic for rank 1
/// until the card is actually scrolled into the viewport. Items stream
/// in countdown order (10 → 1), so #1 lands at the bottom of the list
/// — and we want the moment to fire when the user *reaches* it, not
/// before.
class RankOneReveal extends StatefulWidget {
  const RankOneReveal({required this.child, super.key});

  final Widget child;

  /// Once this fraction of the card is visible, fire the reveal.
  static const double _visibilityThreshold = 0.4;

  @override
  State<RankOneReveal> createState() => _RankOneRevealState();
}

class _RankOneRevealState extends State<RankOneReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Motion.dramatic,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _ctrl,
    curve: Motion.dramaticCurve,
  );

  bool _played = false;
  bool _showConfetti = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_played) return;
    if (info.visibleFraction < RankOneReveal._visibilityThreshold) return;
    _played = true;
    unawaited(_play());
  }

  Future<void> _play() async {
    await _ctrl.forward();
    if (!mounted) return;
    setState(() => _showConfetti = true);
    await HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const ValueKey('rank-1-visibility-detector'),
      onVisibilityChanged: _onVisibilityChanged,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (_, child) {
          final t = _progress.value;
          return Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.95 + 0.05 * t,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 8 * (1 - t),
                  sigmaY: 8 * (1 - t),
                ),
                child: child,
              ),
            ),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            // Span the card so ConfettiBurst can anchor its two emitters
            // at the card's bottom-left and bottom-right corners.
            if (_showConfetti) const Positioned.fill(child: ConfettiBurst()),
          ],
        ),
      ),
    );
  }
}
