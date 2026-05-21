import 'package:countdown/core/theme/app_theme.dart';
import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:countdown/features/ranking/presentation/ranking_screen.dart';
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
      home: const _DevHome(),
    );
  }
}

/// Temporary landing screen until the real Search screen lands.
/// Tap the demo button to push the Ranking screen with a sample query.
class _DevHome extends StatelessWidget {
  const _DevHome();

  static const _sampleQuery = 'Top 10 ramen in Tokyo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Countdown', style: AppTypography.displayM),
              const SizedBox(height: Spacing.sp8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.sp8),
                child: Material(
                  color: ColorTokens.brandPrimary,
                  borderRadius: Radii.pillRadius,
                  child: InkWell(
                    borderRadius: Radii.pillRadius,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RankingScreen(query: _sampleQuery),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sp6,
                        vertical: Spacing.sp3,
                      ),
                      child: Text(
                        _sampleQuery,
                        style: AppTypography.labelL,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
