import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The default font the web engine downloads when the font manifest has no
/// `Roboto` family. Text whose style names no font family is drawn in it.
///
/// `web/flutter_bootstrap.js` points the engine's fallback fonts at the app's
/// own `assets/`, so the build has to ship this file. It shipped none from
/// 2025-07-18 to 2026-11-27, and such text drew blank: the PWA banner's INSTALL
/// label was one (#1975).
const _robotoPath = 'roboto/v20/KFOmCnqEu92Fr1Me5WZLCzYlKw.ttf';

/// The web engine's sources that name the default font, in the Flutter SDK
/// that runs this test. They are there only once the SDK has fetched its web
/// artifacts, which a run that never builds for the web may not have done.
List<File> _engineFontSources() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return const [];
  final lib = '$root/bin/cache/flutter_web_sdk/lib';
  return [
    File('$lib/_engine/engine/canvaskit/fonts.dart'),
    File('$lib/_skwasm_impl/skwasm_impl/font_collection.dart'),
  ].where((f) => f.existsSync()).toList();
}

String _fallbackBaseUrl() {
  final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
  final match = RegExp(r'''fontFallbackBaseUrl:\s*["']([^"']+)["']''')
      .firstMatch(bootstrap);
  expect(match, isNotNull,
      reason: 'web/flutter_bootstrap.js no longer sets fontFallbackBaseUrl');
  return match!.group(1)!;
}

void main() {
  test('the web build ships the default font the engine asks for', () {
    final base = _fallbackBaseUrl();
    expect(base, startsWith('./'),
        reason: 'this test reads a fallback base inside the build only');
    final file = File('web/${base.substring(2)}$_robotoPath');
    expect(file.existsSync(), isTrue,
        reason: '${file.path} is missing, so text with no font family draws '
            'blank on the web');
    expect(file.lengthSync(), greaterThan(0));
  });

  final sources = _engineFontSources();
  test(
    'the shipped default font is the one this Flutter\'s web engine asks for',
    () {
      for (final source in sources) {
        final url = RegExp(r"fontFallbackBaseUrl\}([^']+)'")
            .firstMatch(source.readAsStringSync())
            ?.group(1);
        expect(url, _robotoPath,
            reason: '${source.path} asks for $url. Ship that file under '
                'web/assets/ and update _robotoPath');
      }
    },
    skip: sources.isEmpty
        ? 'the Flutter SDK has no web engine sources to read'
        : false,
  );
}
