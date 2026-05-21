import 'dart:async';

import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:countdown/features/search/search_screen.dart';
import 'package:flutter/material.dart';

/// In-Flutter brand splash. Shown briefly after the native iOS launch
/// image, then fades into the Search screen. The Fraunces wordmark
/// gets a single brand-primary dot after the "n" that pulses subtly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  // 5s ≈ two full pulse loops of the dot before we navigate away.
  static const Duration _hold = Duration(seconds: 5);
  static const Duration _outFade = Duration(milliseconds: 420);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen._hold, _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    unawaited(
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: SplashScreen._outFade,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => const SearchScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Countdown', style: AppTypography.displayM),
            const SizedBox(width: 4),
            const _PulsingDot(),
          ],
        ),
      ),
    );
  }
}

/// Brand-primary dot that scales 1.0 ↔ 1.15 on a 1.2s loop.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 1.5,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, _) => Transform.scale(
          scale: _scale.value,
          child: const _Dot(),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: ColorTokens.brandPrimary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ColorTokens.brandPrimary.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
