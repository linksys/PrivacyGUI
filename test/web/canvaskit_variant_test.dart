import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the CanvasKit shipping decision made in #1281.
///
/// `web/assets/canvaskit.*` are hand-vendored copies of the engine's
/// `build/web/canvaskit/` output — byte-identical, but committed rather than
/// generated. That makes both halves of #1281 reversible by an unrelated
/// Flutter upgrade: whoever re-copies the engine directory brings
/// `chromium/` straight back, and nothing in the build fails.
///
/// The two assertions below are one change, not two. `flutter_bootstrap.js`
/// commits to a variant from browser capability detection and then `import()`s
/// its loader with no 404 fallback path, so shipping either half alone
/// white-screens: the directory without the config pins Chromium browsers at a
/// deleted file, and the config without the directory leaves 1.71 MB of
/// unreachable payload in the rootfs.
///
/// A widget test cannot cover this. `canvasKitVariant` is read by the JS
/// bootstrap in a real browser, and the golden suite runs under the Flutter
/// test VM with no CanvasKit involved, so a variant swap is invisible to it.
void main() {
  group('CanvasKit variant shipping decision (#1281)', () {
    test('only the full variant is present under web/assets', () {
      expect(
        Directory('web/assets/chromium').existsSync(),
        isFalse,
        reason: 'web/assets/chromium/ was removed in #1281 to save 1.71 MB of '
            'rootfs. If a Flutter upgrade re-copied build/web/canvaskit/, '
            'delete the chromium/ subdirectory again.',
      );

      expect(File('web/assets/canvaskit.js').existsSync(), isTrue);
      expect(File('web/assets/canvaskit.wasm').existsSync(), isTrue);
    });

    test('flutter_bootstrap.js pins the full variant and serves it locally',
        () {
      final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

      expect(
        bootstrap,
        contains('canvasKitVariant: "full"'),
        reason: 'Required by the removal of web/assets/chromium/. Without it, '
            'capability detection routes Chromium-based browsers to the '
            'deleted assets/chromium/canvaskit.js and the app never boots.',
      );

      expect(
        bootstrap,
        contains('canvasKitBaseUrl: "./assets/"'),
        reason: 'Offline-critical. buildConfig sets no useLocalCanvasKit, so '
            'dropping this line makes the loader fetch CanvasKit from '
            'gstatic.com — which passes every online test and white-screens '
            'only on a router with no WAN.',
      );
    });
  });
}
