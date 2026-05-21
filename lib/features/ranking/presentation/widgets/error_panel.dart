import 'package:countdown/core/errors.dart';
import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:countdown/core/theme/spacing.dart';
import 'package:countdown/core/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Illustrated empty/error state — one per `AppError` variant. Each
/// surface has a distinct icon, a punchy title, a body explaining what
/// happened, and (where it makes sense) a Retry pill that re-asks the
/// same query.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({required this.error, required this.onRetry, super.key});

  final AppError error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final shape = _shapeFor(error);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sp4,
        vertical: Spacing.sp8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconHalo(icon: shape.icon),
          const SizedBox(height: Spacing.sp5),
          Text(
            shape.title,
            style: AppTypography.headlineL,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sp3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              shape.body,
              style: AppTypography.bodyL.copyWith(
                color: ColorTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (shape.canRetry && onRetry != null) ...[
            const SizedBox(height: Spacing.sp5),
            _RetryPill(onTap: onRetry!),
          ],
        ],
      ),
    );
  }

  _ErrorShape _shapeFor(AppError e) => switch (e) {
        NetworkError() => const _ErrorShape(
            icon: LucideIcons.satelliteDish,
            title: 'Lost signal',
            body: "Couldn't reach the server. Check your connection and try again.",
            canRetry: true,
          ),
        AuthError() => const _ErrorShape(
            icon: LucideIcons.keyRound,
            title: 'Missing key',
            body: 'Set the OPENAI_API_KEY via --dart-define when launching. See README.md.',
            canRetry: false,
          ),
        RateLimitError() => const _ErrorShape(
            icon: LucideIcons.flame,
            title: 'Easy, tiger',
            body: 'GPT is asking us to slow down. Wait a few seconds and try again.',
            canRetry: true,
          ),
        MalformedResponseError() => const _ErrorShape(
            icon: LucideIcons.fileQuestion,
            title: 'Gibberish',
            body: 'The model returned something we could not parse. Worth another try.',
            canRetry: true,
          ),
        RefusedError() => const _ErrorShape(
            icon: LucideIcons.shieldX,
            title: 'Declined',
            body: 'GPT declined to answer. Try rewording your query.',
            canRetry: false,
          ),
        TimeoutError() => const _ErrorShape(
            icon: LucideIcons.timerOff,
            title: 'Took too long',
            body: 'The request timed out. Try again on a stronger connection.',
            canRetry: true,
          ),
        UnknownError() => _ErrorShape(
            icon: LucideIcons.triangleAlert,
            title: 'Something went wrong',
            body: e.message,
            canRetry: true,
          ),
      };
}

class _ErrorShape {
  const _ErrorShape({
    required this.icon,
    required this.title,
    required this.body,
    required this.canRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool canRetry;
}

/// Soft circular halo behind the icon so it reads as a deliberate
/// illustration, not a stray glyph.
class _IconHalo extends StatelessWidget {
  const _IconHalo({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            ColorTokens.brandSecondary.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: ColorTokens.brandSecondary.withValues(alpha: 0.35),
        ),
      ),
      child: Icon(icon, size: 40, color: ColorTokens.brandSecondary),
    );
  }
}

class _RetryPill extends StatelessWidget {
  const _RetryPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: Radii.pillRadius,
        side: BorderSide(color: ColorTokens.surfaceOutline),
      ),
      child: InkWell(
        borderRadius: Radii.pillRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sp5,
            vertical: Spacing.sp3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.rotateCw,
                size: 16,
                color: ColorTokens.textPrimary,
              ),
              const SizedBox(width: Spacing.sp2),
              Text('Try again', style: AppTypography.labelL),
            ],
          ),
        ),
      ),
    );
  }
}
