import 'package:countdown/core/theme/app_theme.dart';
import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CountdownApp extends ConsumerWidget {
  const CountdownApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Countdown',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary landing screen so the app boots while the real screens
/// (Splash → Search → Ranking → …) are being built.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: Center(
        child: Text('Countdown', style: AppTypography.displayM),
      ),
    );
  }
}
