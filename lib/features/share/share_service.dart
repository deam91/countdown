import 'dart:io';
import 'dart:typed_data';

import 'package:countdown/features/ranking/domain/ranking.dart';
import 'package:countdown/features/share/share_composition.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Wraps the system share sheet for ranking shots.
///
/// Two paths:
///
/// * [shareRanking] (preferred) — renders a dedicated 9:16
///   `ShareComposition` off-screen and shares the captured PNG. This is
///   what end users hit from the "Share" pill on a done ranking.
/// * [shareScreenshot] — fallback that takes already-captured bytes.
///   Kept for tests / future "share the visible screen" entry points.
abstract final class ShareService {
  /// Logical layout size of the composition; the on-disk PNG is this
  /// scaled by [_pixelRatio]. 360×640 × 3 = 1080×1920 (Instagram
  /// Stories / TikTok share size).
  static const _pixelRatio = 3.0;

  /// Captures [ShareComposition] off-screen at 1080×1920 and pipes the
  /// PNG into the system share sheet. [context] is used to inherit
  /// theme/typography into the off-tree render.
  static Future<void> shareRanking({
    required BuildContext context,
    required Ranking ranking,
  }) async {
    final bytes = await ScreenshotController().captureFromWidget(
      ShareComposition(ranking: ranking),
      pixelRatio: _pixelRatio,
      targetSize: const Size(
        ShareComposition.logicalWidth,
        ShareComposition.logicalHeight,
      ),
      context: context,
      // Give Material a frame to lay out before the snapshot.
      delay: const Duration(milliseconds: 80),
    );
    await shareScreenshot(bytes, query: ranking.query);
  }

  static Future<void> shareScreenshot(
    Uint8List pngBytes, {
    required String query,
  }) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = await File('${dir.path}/countdown-$stamp.png')
        .writeAsBytes(pngBytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Countdown — $query',
      ),
    );
  }
}
