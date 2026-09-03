/// Guards what a ui_kit bump gets wrong outside any Dart symbol (#1456).
///
/// The analyzer cannot see either of these: `pubspec.yaml` is data, and an import
/// path that resolves is an import path that resolves.
///
/// **The ref-parity half is a backstop, not the first line of defence — measured,
/// not assumed.** Setting `generative_ui` to `v3.0.0` while `ui_kit_library` stays
/// at `v3.1.0` does not reach this test: resolution fails first, because both
/// entries pull the same `gen_ui_contracts` path dependency and pub refuses two
/// commits of it ("generative_ui from git is incompatible with ui_kit_library from
/// git"). That protection is a property of upstream's layout rather than of this
/// repository, so it holds only while both halves keep depending on
/// `gen_ui_contracts`. This test is what notices if that ever stops being true —
/// and it costs nothing today.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one repository behind both `ui_kit_library` and `generative_ui`.
const _uiKitRepo = 'https://github.com/linksys/privacyGUI-UI-kit.git';

/// The only two files allowed to reach past ui_kit's public barrel.
///
/// Both are WCAG analysis demos, and both reach into `src/` because the API they
/// demonstrate is not exported from `ui_kit.dart` *or* `testing.dart` — measured
/// at v3.1.0: swapping either import for the barrel leaves ~40 undefined names.
/// The list is pinned rather than the practice being allowed: a deep `src/` path
/// carries no compatibility promise, so a third file joining this set should be a
/// decision somebody makes on purpose.
const _filesAllowedToReachIntoSrc = {
  'lib/demo/wcag_analysis_demo.dart',
  'lib/demo/wcag_report_with_analysis_demo.dart',
};

void main() {
  group('the two ui_kit entries are one pin', () {
    late String pubspec;

    setUpAll(() {
      pubspec = File('pubspec.yaml').readAsStringSync();
    });

    test('ui_kit_library and generative_ui name the same repository', () {
      expect(_gitField(pubspec, 'ui_kit_library', 'url'), _uiKitRepo);
      expect(_gitField(pubspec, 'generative_ui', 'url'), _uiKitRepo);
    });

    test('and the same ref', () {
      // `generative_ui` only adds `path:` — it is the same package repository, so
      // two different refs would pin two different commits of one codebase. See
      // the library doc for why pub, and not this expectation, is what catches
      // that today.
      final library = _gitField(pubspec, 'ui_kit_library', 'ref');
      final generative = _gitField(pubspec, 'generative_ui', 'ref');

      expect(library, isNotEmpty);
      expect(
        generative,
        library,
        reason: 'bump both refs or neither — see #1456 §1',
      );
    });

    test('the ref is immutable — a version tag or a full commit SHA', () {
      // A branch name resolves to whatever it points at on the day of the build,
      // which makes the lockfile the only record of what shipped — and the
      // lockfile is gitignored here.
      //
      // `startsWith('v')` was not that test. It admits `v-next` and `validation`,
      // which are branch names, and rejects a pinned SHA, which is the one ref
      // *more* immutable than a tag. So the shape is spelled out instead: a
      // version tag, or 40 hex digits.
      final ref = _gitField(pubspec, 'ui_kit_library', 'ref');
      expect(
        ref,
        anyOf(
          matches(RegExp(r'^v\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$')),
          matches(RegExp(r'^[0-9a-f]{40}$')),
        ),
        reason: '"$ref" is neither a version tag nor a commit SHA, so it can '
            'move under us with nothing left recording what shipped',
      );
    });
  });

  group('reaching past ui_kit\'s public barrel stays contained', () {
    test('only the two documented demos import from ui_kit_library/src/', () {
      // The needle is the import form, quote included, so that prose mentioning
      // the path does not read as a reach — and this file is skipped because it
      // has to spell the needle out to look for it.
      const needle = "'package:ui_kit_library/src/";
      const self = 'test/dependencies/ui_kit_pin_test.dart';
      // Every directory this repository keeps Dart in, plus the root file — a
      // scan of `lib` and `test` alone would let `tools/` and `test_scripts/`
      // reach past the barrel unwatched, and they import ui_kit too.
      const roots = [
        'lib',
        'test',
        'tools',
        'test_scripts',
        'test_driver',
        'doc',
      ];

      // Those roots are relative, so this test only means anything from the
      // package root — and from anywhere else it would *pass*, having skipped
      // every root and found nothing. A guard that can pass vacuously is the one
      // kind worse than no guard, so the landmark is asserted before the scan and
      // the file count after it.
      expect(
        File('pubspec.yaml').existsSync() &&
            File('pubspec.yaml')
                .readAsStringSync()
                .contains('name: privacy_gui'),
        isTrue,
        reason: 'run this from the package root — the scan roots are relative, '
            'and from elsewhere the scan finds nothing and says so as a pass',
      );

      var scanned = 0;
      final reaching = <String>{};
      for (final root in roots) {
        final dir = Directory(root);
        if (!dir.existsSync()) continue;
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          if (entity.path == self) continue;
          scanned++;
          if (entity.readAsStringSync().contains(needle)) {
            reaching.add(entity.path);
          }
        }
      }
      for (final file in Directory('.').listSync()) {
        if (file is File && file.path.endsWith('.dart')) {
          scanned++;
          if (file.readAsStringSync().contains(needle)) {
            reaching.add(file.path);
          }
        }
      }

      expect(
        scanned,
        greaterThan(0),
        reason: 'the scan read no Dart files at all, so its verdict is empty '
            'rather than clean',
      );

      // A difference rather than an equality: a file *leaving* the set is a demo
      // being deleted, which is nobody's bug, and asserting equality would report
      // it with a message about the opposite problem.
      expect(
        reaching.difference(_filesAllowedToReachIntoSrc),
        isEmpty,
        reason:
            'import through package:ui_kit_library/ui_kit.dart, or — if the '
            'symbol genuinely is not exported — say so at the import and add the '
            'file here',
      );
    });
  });
}

/// Reads one field out of a `git:` block in `pubspec.yaml` by hand.
///
/// Text rather than a YAML parse because `yaml` is not a declared dependency of
/// this package, and the shape being read is two lines deep.
///
/// Only one indent here is structure: the two spaces before the dependency name
/// are what put it under `dependencies:`. Everything below that is style, so the
/// field is matched at any depth — a reformat to four-space nesting should not
/// fail as "$dependency has no ref", which describes a different pubspec.
String _gitField(String pubspec, String dependency, String field) {
  final block = RegExp(
    '^  $dependency:\\n(?:^ {4,}.*\\n)+',
    multiLine: true,
  ).firstMatch(pubspec);
  expect(block, isNotNull, reason: '$dependency is not a git dependency');

  final value = RegExp('^ +$field: *"?([^"\\n]+?)"? *\$', multiLine: true)
      .firstMatch(block![0]!);
  expect(value, isNotNull, reason: '$dependency has no $field');
  return value![1]!;
}
