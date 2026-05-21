import 'dart:async';

import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:countdown/features/ranking/presentation/ranking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The app's landing screen. User types (or taps a chip) → pushes
/// [RankingScreen] with the query.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const List<String> _exampleQueries = [
    'Top 10 ramen in Tokyo',
    'Best entrepreneurship books',
    'Most underrated horror films',
    'Greatest tennis players of all time',
    'Top sci-fi novels of the 2020s',
    'Best beaches in Portugal',
  ];

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    unawaited(HapticFeedback.lightImpact());
    _focusNode.unfocus();
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RankingScreen(query: trimmed),
        ),
      ),
    );
  }

  void _onChipTapped(String query) {
    _controller.text = query;
    _submit(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Spacing.sp8),
              Text(
                'What do you want ranked?',
                style: AppTypography.headlineL,
              ),
              const SizedBox(height: Spacing.sp6),
              _QueryInput(
                controller: _controller,
                focusNode: _focusNode,
                onSubmitted: _submit,
              ),
              const SizedBox(height: Spacing.sp6),
              _ExampleChips(
                queries: SearchScreen._exampleQueries,
                onTap: _onChipTapped,
              ),
              const Spacer(),
              const _Footer(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + Spacing.sp3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass-frosted text input with rotating placeholder.
class _QueryInput extends StatelessWidget {
  const _QueryInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: ColorTokens.surfaceGlass,
        borderRadius: Radii.inputRadius,
        border: Border.all(color: ColorTokens.surfaceOutline50),
      ),
      child: Row(
        children: [
          const SizedBox(width: Spacing.sp4),
          const Icon(
            LucideIcons.search,
            size: 20,
            color: ColorTokens.textSecondary,
          ),
          const SizedBox(width: Spacing.sp3),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Animated placeholder shown when the input is empty.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, value, _) {
                    if (value.text.isNotEmpty) return const SizedBox.shrink();
                    return const IgnorePointer(
                      child: _RotatingHint(hints: SearchScreen._exampleQueries),
                    );
                  },
                ),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: AppTypography.bodyL,
                  cursorColor: ColorTokens.brandSecondary,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ],
            ),
          ),
          // Mic affordance — wired up when speech_to_text lands (stretch).
          const IconButton(
            onPressed: null,
            icon: Icon(
              LucideIcons.mic,
              size: 24,
              color: ColorTokens.textTertiary,
            ),
            tooltip: 'Voice input (coming soon)',
          ),
          const SizedBox(width: Spacing.sp1),
        ],
      ),
    );
  }
}

/// Cycles through example hints every 3s with a soft fade + slide.
class _RotatingHint extends StatefulWidget {
  const _RotatingHint({required this.hints});

  final List<String> hints;

  @override
  State<_RotatingHint> createState() => _RotatingHintState();
}

class _RotatingHintState extends State<_RotatingHint> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.hints.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return ClipRect(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.6),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Text(
        widget.hints[_index],
        key: ValueKey(_index),
        style: AppTypography.bodyL.copyWith(color: ColorTokens.textTertiary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Two-row grid of tappable example queries.
class _ExampleChips extends StatelessWidget {
  const _ExampleChips({required this.queries, required this.onTap});

  final List<String> queries;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sp2,
      runSpacing: Spacing.sp2,
      children: [
        for (final q in queries) _Chip(label: q, onTap: () => onTap(q)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorTokens.surfaceElevated,
      borderRadius: Radii.pillRadius,
      child: InkWell(
        borderRadius: Radii.pillRadius,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sp3),
          decoration: BoxDecoration(
            borderRadius: Radii.pillRadius,
            border: Border.all(color: ColorTokens.surfaceOutline50),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.labelL.copyWith(color: ColorTokens.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sp2),
      child: Text(
        'Powered by GPT-4o-mini · Images by Wikipedia',
        style: AppTypography.caption.copyWith(color: ColorTokens.textTertiary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
