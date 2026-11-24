// constitution.md §5.4.3: generated codegen types (`lib/generated/*.g.dart`) live
// in the service layer only. A view, model, provider or helper that imports one
// compiles fine, and then a codegen change breaks presentation code — which is
// how nine files under `lib/page/` came to import `lib/generated/` while the rule
// was five grep commands in the constitution that nobody ran (#1833).
//
// The rule, as this test reads it: under `lib/page/`, only a file inside a
// `services/` directory may import `lib/generated/`. There is no allowlist; a
// file that needs a generated type either moves into `services/` or gets plain
// data from a service.
//
// Outside it, each a known gap rather than an oversight:
// - `export` directives.
// - `lib/` outside `lib/page/` (`lib/core/`, `lib/ai/`): the transport and its
//   facades sit below the feature layers and may wrap codegen.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// An `import` of a file under `lib/generated/`: absolute
/// (`package:privacy_gui/generated/…`) or relative (`../../generated/…`), either
/// quote, anchored to the start of the directive.
final _generatedImport = RegExp(
  r"""^\s*import\s+['"](package:privacy_gui/generated/|(\.\./)+generated/)[^'"]*['"]""",
  multiLine: true,
);

/// [source] with its comments blanked to spaces — `//` to end of line, and
/// `/* … */` — so a commented-out import does not count. Newlines are kept, so
/// a match's line number is the line in the file.
String _withoutComments(String source) => source
    .replaceAllMapped(RegExp(r'/\*[\s\S]*?\*/'),
        (m) => m[0]!.replaceAll(RegExp(r'[^\n]'), ' '))
    .replaceAllMapped(RegExp(r'//[^\n]*'), (m) => ' ' * m[0]!.length);

void main() {
  /// Every Dart file under `lib/page/` that is not inside a `services/` directory.
  List<File> nonServiceFiles() => Directory('lib/page')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.split('/').contains('services'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('the scan reaches the files it is meant to', () {
    // A guard that finds no files passes by construction.
    final paths = nonServiceFiles().map((f) => f.path).toSet();
    expect(paths, isNotEmpty);
    expect(paths, contains('lib/page/firewall/views/usp_firewall_view.dart'));
    expect(paths, isNot(contains('lib/page/dmz/services/usp_dmz_service.dart')),
        reason: 'a file inside services/ is the one place the rule allows');
  });

  test('only a file inside services/ imports lib/generated/', () {
    final offenders = <String>[];
    for (final f in nonServiceFiles()) {
      final source = _withoutComments(f.readAsStringSync());
      for (final m in _generatedImport.allMatches(source)) {
        final line = '\n'.allMatches(source.substring(0, m.start)).length + 1;
        offenders.add('${f.path}:$line: ${m[0]!.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'generated codegen types stay in the service layer '
          '(constitution 5.4.3); move this code into the feature\'s '
          '`services/`, or expose plain data from a service. '
          'Article V §5.4.\n${offenders.join('\n')}',
    );
  });

  test('a commented-out import does not count, and a real one does', () {
    // The two halves of the matcher this guard rests on, checked on literals so
    // a regex edit that drifts either way fails here rather than silently.
    const commented = '''
// import 'package:privacy_gui/generated/wan_status.g.dart';
/* import '../../generated/dhcp_clients.g.dart'; */
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
''';
    const real = '''
import 'package:flutter/material.dart';
import "../../../generated/wan_status.g.dart";
''';
    expect(_generatedImport.hasMatch(_withoutComments(commented)), isFalse);
    expect(_generatedImport.hasMatch(_withoutComments(real)), isTrue);
  });
}
