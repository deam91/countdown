import 'dart:async';

import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:countdown/features/ranking/presentation/ranking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// The app's landing screen. User types (or taps a chip) → pushes
/// [RankingScreen] with the query.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  /// (`label`, `query`) pairs. Chip face shows the short label; tapping
  /// it submits the full query. The rotating hint cycles through queries.
  static const List<({String label, String query})> _examples = [
    (label: 'Tokyo ramen', query: 'Top 10 ramen in Tokyo'),
    (label: 'Startup books', query: 'Best entrepreneurship books'),
    (label: 'Horror films', query: 'Most underrated horror films'),
    (label: 'Tennis GOATs', query: 'Greatest tennis players of all time'),
    (label: 'Sci-fi novels', query: 'Top sci-fi novels of the 2020s'),
    (label: 'Portugal beaches', query: 'Best beaches in Portugal'),
  ];

  static List<String> get _hintQueries =>
      _examples.map((e) => e.query).toList();

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spacing.sp1,
            children: [
              const SizedBox(height: Spacing.sp8),
              Text(
                'What do you want ranked?',
                style: AppTypography.headlineL,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sp6),
              _QueryInput(
                controller: _controller,
                focusNode: _focusNode,
                onSubmitted: _submit,
              ),
              const SizedBox(height: Spacing.sp6),
              _Chips(
                examples: SearchScreen._examples,
                onTap: _onChipTapped,
              ),
              const Spacer(),
              const _Footer(),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + Spacing.sp3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass-frosted text input with rotating placeholder + voice input.
///
/// Stateful because the mic owns a [SpeechToText] instance that needs
/// `initialize()` on first interaction and `stop()` on dispose. The
/// text controller + focus node remain owned by the parent so the
/// example chips and rotating hint can read/write them.
class _QueryInput extends StatefulWidget {
  const _QueryInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  State<_QueryInput> createState() => _QueryInputState();
}

class _QueryInputState extends State<_QueryInput> {
  final SpeechToText _speech = SpeechToText();

  /// True once `_speech.initialize()` has been awaited successfully.
  /// Lazy-initialized on first mic press so we don't request mic +
  /// speech permissions on app launch.
  bool _speechReady = false;
  bool _listening = false;
  bool _speechUnavailable = false;

  /// True while the user's finger is on the mic button. Used to bail
  /// out of starting a listen session if the press was released
  /// before `initialize()` returned.
  bool _pressActive = false;

  /// Set when the user releases the mic. The next `onResult` with
  /// `finalResult == true` will auto-submit the query — so the user
  /// holds, talks, releases, and the search fires on its own.
  bool _submitOnFinal = false;

  @override
  void dispose() {
    // Best-effort: cancel any in-flight listen session. Don't await on
    // dispose to keep the close path synchronous.
    unawaited(_speech.cancel());
    super.dispose();
  }

  /// Called when the user puts a finger down on the mic. Initializes
  /// the engine on first use, then opens a listen session that lasts
  /// as long as the press. Partial results stream into the text field
  /// while the user is talking.
  Future<void> _onMicHoldStart() async {
    if (_speechUnavailable) return;
    _pressActive = true;

    if (!_speechReady) {
      final available = await _speech.initialize(
        onError: (e) {
          if (e.permanent && mounted) {
            setState(() {
              _speechUnavailable = true;
              _listening = false;
            });
          }
        },
        onStatus: (status) {
          // 'done' / 'notListening' both mean the system has stopped
          // capturing — flip our local state back so the UI matches.
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _listening = false);
          }
        },
      );
      if (!mounted) return;
      if (!available) {
        setState(() => _speechUnavailable = true);
        return;
      }
      _speechReady = true;
    }

    // The user may have released the button while initialize() was
    // pending. Don't open a listen session in that case.
    if (!_pressActive || !mounted) return;

    unawaited(HapticFeedback.lightImpact());
    widget.focusNode.unfocus();
    // Clear any prior query so the user sees a fresh field as they
    // start talking — recognition results otherwise visually replace
    // the old text on first onResult, which reads as a brief flicker.
    widget.controller.clear();
    setState(() => _listening = true);

    unawaited(
      _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          widget.controller.text = result.recognizedWords;
          widget.controller.selection = TextSelection.collapsed(
            offset: widget.controller.text.length,
          );
          // Auto-submit once the engine finalizes recognition *and*
          // the user has released the mic. Partial results stream in
          // first; the final one (typically punctuation-corrected)
          // arrives after `stop()`.
          if (result.finalResult && _submitOnFinal) {
            _submitOnFinal = false;
            final text = widget.controller.text.trim();
            if (text.isNotEmpty) {
              widget.onSubmitted(text);
            }
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          // 44.1 kHz matches what the Mac mic (and most hardware) hands
          // the iOS Simulator. Without this, AVAudioEngine retries 5x
          // with "Format mismatch: input hw 44100 Hz, client format
          // 48000 Hz" then bails with kAFAssistantErrorDomain 1101.
          // 0 (default) lets Speech pick — which is 48 kHz on iOS, the
          // mismatch path. Real devices auto-resample so this matters
          // most for the demo running in a simulator.
          sampleRate: 44100,
          // Long ceiling — the user controls actual duration with the
          // press. pauseFor matches so we don't auto-stop on small
          // breath pauses while the user is still holding.
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 60),
        ),
      ),
    );
  }

  /// Called on finger lift or pointer cancel. Stops the session if one
  /// is open and clears the press latch. Flags the next final result
  /// for auto-submit so the user doesn't have to tap Enter after
  /// dictating their query.
  Future<void> _onMicHoldEnd() async {
    _pressActive = false;
    if (!_listening) return;
    _submitOnFinal = true;
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: ColorTokens.surfaceGlass,
        borderRadius: Radii.inputRadius,
        border: Border.all(
          color: _listening
              ? ColorTokens.brandPrimary
              : ColorTokens.surfaceOutline50,
        ),
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
                  valueListenable: widget.controller,
                  builder: (_, value, _) {
                    if (value.text.isNotEmpty) return const SizedBox.shrink();
                    return IgnorePointer(
                      child: _RotatingHint(hints: SearchScreen._hintQueries),
                    );
                  },
                ),
                TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  style: AppTypography.bodyL,
                  cursorColor: ColorTokens.brandSecondary,
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.onSubmitted,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ],
            ),
          ),
          // Clear (×) only appears when there's text. Refocuses the
          // field after clearing so the user can keep typing.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (_, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: ColorTokens.textSecondary,
                ),
                tooltip: 'Clear',
                onPressed: () {
                  widget.controller.clear();
                  widget.focusNode.requestFocus();
                },
              );
            },
          ),
          _MicButton(
            listening: _listening,
            disabled: _speechUnavailable,
            onHoldStart: _onMicHoldStart,
            onHoldEnd: _onMicHoldEnd,
          ),
          const SizedBox(width: Spacing.sp1),
        ],
      ),
    );
  }
}

/// Press-and-hold mic affordance.
///
/// Listening starts on pointer-down and stops on pointer-up / cancel,
/// so the user holds to talk and releases to send recognition to the
/// text field. Becomes brand-primary + scales up while listening, and
/// renders dimmed/disabled when speech is unavailable (denied
/// permission or unsupported platform).
class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.listening,
    required this.disabled,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final bool listening;
  final bool disabled;
  final Future<void> Function() onHoldStart;
  final Future<void> Function() onHoldEnd;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? ColorTokens.surfaceOutline
        : (listening ? ColorTokens.brandPrimary : ColorTokens.textTertiary);

    return Semantics(
      button: true,
      label: disabled
          ? 'Voice input unavailable'
          : (listening ? 'Listening — release to stop' : 'Hold to speak'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: disabled ? null : (_) => unawaited(onHoldStart()),
        onTapUp: disabled ? null : (_) => unawaited(onHoldEnd()),
        onTapCancel: disabled ? null : () => unawaited(onHoldEnd()),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AnimatedScale(
            scale: listening ? 1.18 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Icon(
              listening ? LucideIcons.micVocal : LucideIcons.mic,
              size: 24,
              color: color,
            ),
          ),
        ),
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
      // Default layoutBuilder uses Alignment.center, which makes the
      // hint visually jump to the middle of the input while two hints
      // overlap during the cross-fade. Anchor to centerLeft so the
      // text stays flush with the search icon.
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.centerLeft,
        children: [
          ...previousChildren,
          ?currentChild,
        ],
      ),
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
        widget.hints[_index].trim(),
        key: ValueKey(_index),
        textAlign: TextAlign.left,
        style: AppTypography.bodyL.copyWith(color: ColorTokens.textTertiary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Two-row grid of tappable example queries (3 per row).
///
/// Computes per-chip width from the available column width so the
/// chips lay out as an even 3×2 grid regardless of label length.
class _Chips extends StatelessWidget {
  const _Chips({required this.examples, required this.onTap});

  final List<({String label, String query})> examples;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = Spacing.sp2;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final e in examples)
              _Chip(
                label: e.label,
                onTap: () => onTap(e.query),
              ),
          ],
        );
      },
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: Radii.pillRadius,
            border: Border.all(color: ColorTokens.surfaceOutline50),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sp3,
              vertical: Spacing.sp2,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelL.copyWith(
                color: ColorTokens.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
      child: SizedBox(
        width: double.infinity,
        child: Text(
          'Powered by GPT-4o-mini · Images by Wikipedia',
          style: AppTypography.caption.copyWith(
            color: ColorTokens.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
