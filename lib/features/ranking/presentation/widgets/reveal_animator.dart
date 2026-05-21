import 'dart:async';
import 'dart:ui';

import 'package:countdown/core/theme/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a card and plays the reveal animation once on mount:
/// opacity 0 → 1, scale 0.95 → 1.0, blur 8px → 0.
///
/// Top-3 cards use [Motion.dramatic] (700ms); others [Motion.standard]
/// (280ms). Triggers a haptic on land — `medium` for rank 1, `light`
/// otherwise.
class RevealAnimator extends StatefulWidget {
  const RevealAnimator({
    required this.child,
    required this.rank,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final int rank;
  final Duration delay;

  @override
  State<RevealAnimator> createState() => _RevealAnimatorState();
}

class _RevealAnimatorState extends State<RevealAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.rank == 1 ? Motion.dramatic : Motion.standard,
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _ctrl,
    curve: widget.rank == 1 ? Motion.dramaticCurve : Motion.easeOut,
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.95, end: 1).animate(_opacity);
  late final Animation<double> _blur = Tween<double>(begin: 8, end: 0).animate(_opacity);

  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.delayed(widget.delay, () async {
        if (!mounted) return;
        await _ctrl.forward();
        if (!mounted) return;
        await (widget.rank == 1
            ? HapticFeedback.mediumImpact()
            : HapticFeedback.lightImpact());
      }),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: _blur.value,
              sigmaY: _blur.value,
            ),
            child: child,
          ),
        ),
      ),
      child: widget.child,
    );
  }
}
