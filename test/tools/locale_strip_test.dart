library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tools/locale_strip.dart';

/// Tests for the English-only build flavour stripper (see
/// docs/adr/0001-english-only-build-by-build-time-stripping.md).
///
/// The seam under test is [LocaleStripper]'s behaviour against a real directory
/// tree: given a project layout, what does the filesystem look like afterwards.
/// Nothing reaches inside the implementation.
///
/// Each test builds a throwaway project in a temp directory rather than
/// touching the real repo, because the stripper deletes tracked files.
void main() {
  late Directory project;

  /// A pubspec whose `fonts:` block declares one family per font file, in the
  /// same three-line shape the real pubspec uses.
  String pubspecDeclaring(List<String> fonts) {
    final buffer = StringBuffer('name: test_app\n\nflutter:\n  fonts:\n');
    for (final font in fonts) {
      final family = font.split('.').first;
      buffer.writeln('    - family: packages/ui_kit_library/$family');
      buffer.writeln('      fonts:');
      buffer.writeln('        - asset: assets/fonts/fallback/$font');
    }
    return buffer.toString();
  }

  /// Commits everything in the throwaway project.
  ///
  /// The stripper restores by checking out of git, so a project it can operate on
  /// is always a git repo with the strippable paths committed — same as the real
  /// one.
  void commitEverything() {
    for (final args in [
      ['init', '-q'],
      ['config', 'user.email', 'test@example.com'],
      ['config', 'user.name', 'Test'],
      ['add', '-A'],
      ['commit', '-qm', 'baseline'],
    ]) {
      final result =
          Process.runSync('git', args, workingDirectory: project.path);
      expect(result.exitCode, 0, reason: 'git ${args.first}: ${result.stderr}');
    }
  }

  /// Builds a minimal project layout: [locales] ARB files and [fonts] fallback
  /// font files, plus the pubspec that declares them, all committed to git.
  void givenProject({
    required List<String> locales,
    List<String> fonts = const [],
  }) {
    Directory('${project.path}/lib/l10n').createSync(recursive: true);
    for (final locale in locales) {
      File('${project.path}/lib/l10n/app_$locale.arb')
          .writeAsStringSync('{"@@locale":"$locale"}');
    }
    Directory('${project.path}/assets/fonts/fallback')
        .createSync(recursive: true);
    for (final font in fonts) {
      File('${project.path}/assets/fonts/fallback/$font')
          .writeAsStringSync('font-bytes');
    }
    File('${project.path}/pubspec.yaml')
        .writeAsStringSync(pubspecDeclaring(fonts));
    commitEverything();
  }

  List<String> remainingFontFiles() =>
      Directory('${project.path}/assets/fonts/fallback')
          .listSync()
          .map((e) => e.uri.pathSegments.last)
          .toList()
        ..sort();

  String pubspecContent() =>
      File('${project.path}/pubspec.yaml').readAsStringSync();

  List<String> remainingArbFiles() => Directory('${project.path}/lib/l10n')
      .listSync()
      .map((e) => e.uri.pathSegments.last)
      .where((name) => name.endsWith('.arb'))
      .toList()
    ..sort();

  setUp(() {
    project = Directory.systemTemp.createTempSync('locale_strip_test');
  });

  tearDown(() {
    if (project.existsSync()) {
      project.deleteSync(recursive: true);
    }
  });

  group('keep', () {
    test('deletes every ARB file except the locales being kept', () {
      givenProject(locales: ['en', 'ja', 'zh', 'fr']);

      LocaleStripper(projectRoot: project.path).keep(['en']);

      expect(remainingArbFiles(), ['app_en.arb']);
    });

    test('keeps several locales when asked for several', () {
      givenProject(locales: ['en', 'ja', 'zh', 'fr']);

      LocaleStripper(projectRoot: project.path).keep(['en', 'fr']);

      expect(remainingArbFiles(), ['app_en.arb', 'app_fr.arb']);
    });

    test('keeps a regional variant alongside its parent language', () {
      // zh_TW ships inside zh's language pack, so keeping zh must keep both.
      givenProject(locales: ['en', 'zh', 'zh_TW', 'ja']);

      LocaleStripper(projectRoot: project.path).keep(['en', 'zh']);

      expect(
          remainingArbFiles(), ['app_en.arb', 'app_zh.arb', 'app_zh_TW.arb']);
    });

    test('refuses to strip a locale the project does not have', () {
      givenProject(locales: ['en', 'ja']);

      expect(
        () => LocaleStripper(projectRoot: project.path).keep(['en', 'kl']),
        throwsA(isA<LocaleStripException>()),
      );
    });

    test('refuses to strip every locale away', () {
      // An empty list would otherwise delete all 26 packs and build an app with
      // no strings at all.
      givenProject(locales: ['en', 'ja']);

      expect(
        () => LocaleStripper(projectRoot: project.path).keep(['']),
        throwsA(isA<LocaleStripException>()),
      );
    });

    test('leaves every ARB file in place when asked to keep all', () {
      givenProject(locales: ['en', 'ja', 'zh']);

      LocaleStripper(projectRoot: project.path).keep(['all']);

      expect(remainingArbFiles(), ['app_en.arb', 'app_ja.arb', 'app_zh.arb']);
    });

    test('tolerates the whitespace a Jenkins parameter arrives with', () {
      // The locale list comes in as one string a human typed into a build
      // parameter, so "en, fr" has to mean what it looks like.
      givenProject(locales: ['en', 'ja', 'fr']);

      LocaleStripper(projectRoot: project.path).keep(['en', ' fr']);

      expect(remainingArbFiles(), ['app_en.arb', 'app_fr.arb']);
    });
  });

  group('keep, fallback fonts', () {
    const allFonts = [
      'NotoSans-Latin.woff2',
      'NotoSansArabic.woff2',
      'NotoSansCJKsc.subset.woff2',
      'NotoSansThai.woff2',
      'Roboto.woff2',
    ];

    test('deletes the fonts an English-only build cannot use', () {
      givenProject(locales: ['en', 'ja'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).keep(['en']);

      expect(remainingFontFiles(), ['NotoSans-Latin.woff2', 'Roboto.woff2']);
    });

    test('removes the pubspec declaration of every deleted font', () {
      // A pubspec that still declares a deleted font fails the build with an
      // error that does not mention this script, so the declaration has to go.
      givenProject(locales: ['en'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).keep(['en']);

      expect(pubspecContent(), isNot(contains('NotoSansArabic')));
      expect(pubspecContent(), isNot(contains('NotoSansCJKsc')));
      expect(pubspecContent(), isNot(contains('NotoSansThai')));
    });

    test('leaves the declarations of surviving fonts intact', () {
      givenProject(locales: ['en'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).keep(['en']);

      expect(
        pubspecContent(),
        contains('- asset: assets/fonts/fallback/NotoSans-Latin.woff2'),
      );
      expect(
        pubspecContent(),
        contains('- family: packages/ui_kit_library/NotoSans-Latin'),
      );
      expect(
        pubspecContent(),
        contains('- asset: assets/fonts/fallback/Roboto.woff2'),
      );
    });

    test('leaves every font in place when asked to keep all', () {
      givenProject(locales: ['en', 'ja'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).keep(['all']);

      expect(remainingFontFiles(), allFonts);
    });

    test('refuses to leave the pubspec declaring a font that is gone', () {
      // The guard that turns a fragile text edit into a loud failure: if the
      // pubspec rewrite ever misses an entry, abort instead of building.
      givenProject(locales: ['en'], fonts: allFonts);
      final stripper = LocaleStripper(projectRoot: project.path);
      stripper.keep(['en']);

      File('${project.path}/assets/fonts/fallback/Roboto.woff2').deleteSync();

      expect(
        stripper.verifyDeclaredFontsExist,
        throwsA(isA<LocaleStripException>()),
      );
    });
  });

  group('restore', () {
    const allFonts = [
      'NotoSans-Latin.woff2',
      'NotoSansCJKsc.subset.woff2',
      'Roboto.woff2',
    ];

    test('puts back every stripped language pack and font', () {
      givenProject(locales: ['en', 'ja', 'zh'], fonts: allFonts);
      final stripper = LocaleStripper(projectRoot: project.path);
      stripper.keep(['en']);

      stripper.restore();

      expect(remainingArbFiles(), ['app_en.arb', 'app_ja.arb', 'app_zh.arb']);
      expect(remainingFontFiles(), allFonts);
      expect(pubspecContent(), contains('NotoSansCJKsc'));
    });

    test('is safe to run when nothing was stripped', () {
      // Every build starts with a restore so a killed run cannot leak into the
      // next one, which means restore has to be a no-op on a clean tree.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).restore();

      expect(remainingArbFiles(), ['app_en.arb', 'app_ja.arb']);
      expect(remainingFontFiles(), allFonts);
    });

    test('leaves files outside its own paths alone', () {
      // restore is a `git checkout --` over a fixed path list, never a reset, so
      // unrelated work in progress must survive it.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      final unrelated = File('${project.path}/lib/unrelated.dart')
        ..writeAsStringSync('// work in progress');
      final stripper = LocaleStripper(projectRoot: project.path);
      stripper.keep(['en']);

      stripper.restore();

      expect(unrelated.readAsStringSync(), '// work in progress');
    });
  });

  group('verify', () {
    const allFonts = ['NotoSans-Latin.woff2', 'NotoSansCJKsc.subset.woff2'];

    test('passes on a tree with nothing stripped', () {
      givenProject(locales: ['en', 'ja'], fonts: allFonts);

      expect(LocaleStripper(projectRoot: project.path).verify, returnsNormally);
    });

    test('fails while a strip is still in place', () {
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      final stripper = LocaleStripper(projectRoot: project.path);
      stripper.keep(['en']);

      expect(stripper.verify, throwsA(isA<LocaleStripException>()));
    });

    test('refuses to strip a tree that already has local changes', () {
      // Stripping on top of uncommitted work would let the restore afterwards
      // throw that work away, so the gate has to come first.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      File('${project.path}/lib/l10n/app_ja.arb')
          .writeAsStringSync('{"@@locale":"ja","edited":"yes"}');

      expect(
        () => LocaleStripper(projectRoot: project.path).keep(['en']),
        throwsA(isA<LocaleStripException>()),
      );
    });

    test('ignores local changes outside the paths it strips', () {
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      File('${project.path}/lib/unrelated.dart')
          .writeAsStringSync('// work in progress');

      expect(
        () => LocaleStripper(projectRoot: project.path).keep(['en']),
        returnsNormally,
      );
    });
  });
}
