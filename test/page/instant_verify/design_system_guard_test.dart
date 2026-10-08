import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Instant-Test must look like the rest of the router UI, so its views take
/// colors, type, icons and spacing from the shared theme and widget kit
/// instead of hardcoding them. Upstream Instant-Verify files are out of scope.
const _outOfScope = {
  'instant_verify_view.dart',
};

const _banned = <String, String>{
  r'\bColors\.(?!transparent\b)': 'use Theme colorScheme / colorSchemeExt',
  r'Color\(0x': 'use Theme colorScheme / colorSchemeExt',
  r'\bTextStyle\(': 'use AppText.<level>',
  r'\bfontSize:': 'use AppText.<level>',
  r'\bfontWeight:': 'use AppText.<level>',
  r'\btextTheme\.': 'use AppText.<level>',
  r'\.withOpacity\(|\.withValues\(': 'use a container or surface token',
  r'(?<![A-Za-z])Icons\.': 'use LinksysIcons',
  r'BorderRadius\.circular\(|Radius\.circular\(':
      'use CustomTheme.of(context).radius',
  r'(?<![A-Za-z])Text\(': 'use AppText.<level>',
};

void main() {
  final files = Directory('lib/page/instant_verify/views')
      // Recursive: the help flows live in views/help/.
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !_outOfScope.contains(f.uri.pathSegments.last))
      // Upstream Instant-Verify widgets.
      .where((f) => !f.uri.pathSegments.contains('components'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('Instant-Test views are in scope', () {
    expect(files, isNotEmpty);
  });

  for (final entry in _banned.entries) {
    test('Instant-Test views avoid ${entry.key} (${entry.value})', () {
      final pattern = RegExp(entry.key);
      final hits = <String>[];
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (pattern.hasMatch(line)) {
            hits.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    });
  }
}
