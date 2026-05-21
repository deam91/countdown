import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Wraps the system share sheet for ranking screenshots.
///
/// MVP: receives raw PNG bytes from a `ScreenshotController.capture()`
/// call, writes them to a temp file, and hands the file to `share_plus`
/// so the user can AirDrop / save to Photos / message / etc.
///
/// The dedicated 9:16 composition (per `IDEA.md §3.5`) is a future
/// upgrade; this gets the button functional first.
abstract final class ShareService {
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
