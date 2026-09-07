library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tools/locale_strip.dart';

/// Tests for the English-only build flavour stripper.
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
  ///
  /// [templateLocale] writes the `l10n.yaml` that names gen-l10n's template, the
  /// same way the real repo does. Pass null for a tree without one.
  void givenProject({
    required List<String> locales,
    List<String> fonts = const [],
    String? templateLocale = 'en',
  }) {
    Directory('${project.path}/lib/l10n').createSync(recursive: true);
    for (final locale in locales) {
      File('${project.path}/lib/l10n/app_$locale.arb')
          .writeAsStringSync('{"@@locale":"$locale"}');
    }
    if (templateLocale != null) {
      File('${project.path}/l10n.yaml').writeAsStringSync(
        'arb-dir: lib/l10n\n'
        'template-arb-file: app_$templateLocale.arb\n'
        'output-localization-file: app_localizations.dart\n',
      );
    }
    // The real repo gitignores the gen-l10n output, which is why restore has to
    // delete it rather than check it out. Without this the directory reads as
    // untracked, i.e. as a strip that never happened.
    File('${project.path}/.gitignore').writeAsStringSync('lib/l10n/gen/\n');
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

    test('refuses a locale list that drops the gen-l10n template', () {
      // l10n.yaml names app_en.arb as its template, so `keep fr` deletes the one
      // file gen-l10n cannot run without. It fails loudly and the trap restores,
      // but its error names neither this script nor LOCALES, so the whole CI
      // build is spent to learn what this check says for free.
      givenProject(locales: ['en', 'fr', 'ja']);

      expect(
        () => LocaleStripper(projectRoot: project.path).keep(['fr']),
        throwsA(isA<LocaleStripException>()),
      );
      expect(remainingArbFiles(), ['app_en.arb', 'app_fr.arb', 'app_ja.arb']);
    });

    test('keeps the parent language a kept regional variant needs', () {
      // gen-l10n requires a base locale as the fallback for any locale carrying a
      // country code, so keeping zh_TW alone deletes app_zh.arb and fails the
      // generation. The variant is a reasonable thing to ask for — it just cannot
      // travel without its parent.
      givenProject(locales: ['en', 'zh', 'zh_TW', 'ja']);

      LocaleStripper(projectRoot: project.path).keep(['en', 'zh_TW']);

      expect(
          remainingArbFiles(), ['app_en.arb', 'app_zh.arb', 'app_zh_TW.arb']);
    });

    test('keeps the fonts a regional variant pulls its parent in for', () {
      // The parent came back for gen-l10n's sake, so the Han fonts have to come
      // with it or zh_TW ships its strings and renders them as tofu.
      givenProject(locales: [
        'en',
        'zh',
        'zh_TW'
      ], fonts: [
        'NotoSans-Latin.woff2',
        'NotoSansCJKtc.subset.woff2',
        'Roboto.woff2',
      ]);

      LocaleStripper(projectRoot: project.path).keep(['en', 'zh_TW']);

      expect(remainingFontFiles(), [
        'NotoSans-Latin.woff2',
        'NotoSansCJKtc.subset.woff2',
        'Roboto.woff2',
      ]);
    });

    test('strips normally in a tree with no l10n.yaml to read', () {
      // The template check gives itself up rather than guessing when there is no
      // l10n.yaml, so a tree without one still strips.
      givenProject(locales: ['en', 'ja', 'fr'], templateLocale: null);

      LocaleStripper(projectRoot: project.path).keep(['ja']);

      expect(remainingArbFiles(), ['app_ja.arb']);
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
    /// Every fallback font the real repo ships, so a test that keeps a locale is
    /// asserting against the same set of candidates a real build strips from.
    const allFonts = [
      'NotoSans-Latin.woff2',
      'NotoSansArabic.woff2',
      'NotoSansCJKhk.subset.woff2',
      'NotoSansCJKjp.subset.woff2',
      'NotoSansCJKkr.subset.woff2',
      'NotoSansCJKsc.subset.woff2',
      'NotoSansCJKtc.subset.woff2',
      'NotoSansThai.woff2',
      'Roboto.woff2',
    ];

    test('deletes the fonts an English-only build cannot use', () {
      givenProject(locales: ['en', 'ja'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).keep(['en']);

      expect(remainingFontFiles(), ['NotoSans-Latin.woff2', 'Roboto.woff2']);
    });

    test('keeps the font a second kept locale needs', () {
      // The build ships the whole Japanese UI, so deleting its only CJK font
      // renders that UI as tofu boxes. There is no recovery on the router this
      // targets: the bundle is served offline from firmware, and the engine's CDN
      // fallback needs internet.
      givenProject(locales: ['en', 'ja', 'zh'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).keep(['en', 'ja']);

      expect(remainingFontFiles(), [
        'NotoSans-Latin.woff2',
        'NotoSansCJKjp.subset.woff2',
        'Roboto.woff2',
      ]);
    });

    test('keeps the pubspec declaration of a second kept locale\'s font', () {
      givenProject(locales: ['en', 'ja'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).keep(['en', 'ja']);

      expect(
        pubspecContent(),
        contains('- asset: assets/fonts/fallback/NotoSansCJKjp.subset.woff2'),
      );
    });

    test('keeps every Han subset when a Chinese pack survives', () {
      // A zh pack carries every regional variant's strings, and the stripper keeps
      // them together, so all three Han subsets have to survive rather than the
      // one a guess at the selected variant would pick.
      givenProject(locales: ['en', 'zh', 'zh_TW'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).keep(['en', 'zh']);

      expect(remainingFontFiles(), [
        'NotoSans-Latin.woff2',
        'NotoSansCJKhk.subset.woff2',
        'NotoSansCJKsc.subset.woff2',
        'NotoSansCJKtc.subset.woff2',
        'Roboto.woff2',
      ]);
    });

    test('keeps the Han subsets when only a regional variant is kept', () {
      // zh_TW is a Han locale in its own right, so its font cannot depend on the
      // parent pack being named explicitly.
      givenProject(locales: ['en', 'zh', 'zh_TW'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).keep(['en', 'zh_TW']);

      expect(remainingFontFiles(), contains('NotoSansCJKtc.subset.woff2'));
    });

    test('keeps Thai and Arabic when those locales are kept', () {
      givenProject(locales: ['en', 'th', 'ar', 'ja'], fonts: allFonts);

      LocaleStripper(projectRoot: project.path).keep(['en', 'th', 'ar']);

      expect(remainingFontFiles(), [
        'NotoSans-Latin.woff2',
        'NotoSansArabic.woff2',
        'NotoSansThai.woff2',
        'Roboto.woff2',
      ]);
    });

    test('keeps a font no language claims rather than guessing', () {
      // A font added to the repo without a _fontsByLanguage entry is wasted bytes
      // if kept and tofu if deleted, so the recoverable failure is the right one.
      givenProject(
        locales: ['en', 'ja'],
        fonts: [...allFonts, 'NotoSansDevanagari.woff2'],
      );

      LocaleStripper(projectRoot: project.path).keep(['en']);

      expect(remainingFontFiles(), contains('NotoSansDevanagari.woff2'));
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

    test('parses a family that declares more than one weight', () {
      // Line arithmetic on a fixed three-line shape rejected this legal YAML, and
      // rejected it *after* deleting, which is what left a half-stripped tree
      // behind. The scan is indentation-aware so the extra lines travel with the
      // family they belong to.
      givenProject(locales: ['en', 'th'], fonts: allFonts);
      final pubspec = File('${project.path}/pubspec.yaml');
      pubspec.writeAsStringSync(pubspec.readAsStringSync().replaceFirst(
            '        - asset: assets/fonts/fallback/NotoSansThai.woff2',
            '        - asset: assets/fonts/fallback/NotoSansThai.woff2\n'
                '        - asset: assets/fonts/fallback/NotoSansThai.woff2\n'
                '          weight: 700',
          ));
      commitEverything();

      LocaleStripper(projectRoot: project.path).keep(['en']);

      expect(pubspecContent(), isNot(contains('NotoSansThai')));
      expect(pubspecContent(), isNot(contains('weight: 700')));
    });

    test('reads an asset path that is quoted or trailed by a comment', () {
      // Both are legal YAML the repo does not happen to use. Failing to read the
      // path used to abort the strip after the deletions, via the
      // "declares fonts that are not on disk" guard.
      givenProject(locales: ['en', 'th', 'ar'], fonts: allFonts);
      final pubspec = File('${project.path}/pubspec.yaml');
      pubspec.writeAsStringSync(pubspec
          .readAsStringSync()
          .replaceFirst(
            '- asset: assets/fonts/fallback/NotoSansThai.woff2',
            '- asset: "assets/fonts/fallback/NotoSansThai.woff2"',
          )
          .replaceFirst(
            '- asset: assets/fonts/fallback/NotoSansArabic.woff2',
            '- asset: assets/fonts/fallback/NotoSansArabic.woff2  # RTL',
          ));
      commitEverything();

      LocaleStripper(projectRoot: project.path).keep(['en']);

      expect(pubspecContent(), isNot(contains('NotoSansThai')));
      expect(pubspecContent(), isNot(contains('NotoSansArabic')));
    });

    test('deletes nothing when it cannot make sense of the fonts: block', () {
      // The guarantee behind arming the build's restore trap: a pubspec this
      // cannot parse aborts while the tree is still intact, rather than leaving
      // deleted language packs behind while the caller reports nothing was built.
      givenProject(locales: ['en', 'ja', 'zh'], fonts: allFonts);
      final pubspec = File('${project.path}/pubspec.yaml');
      // One family declaring both a doomed and a surviving font: removing it would
      // drop Roboto's declaration too, keeping it would point at a deleted file.
      pubspec.writeAsStringSync(pubspec.readAsStringSync().replaceFirst(
            '        - asset: assets/fonts/fallback/NotoSansThai.woff2',
            '        - asset: assets/fonts/fallback/NotoSansThai.woff2\n'
                '        - asset: assets/fonts/fallback/Roboto.woff2',
          ));
      commitEverything();

      expect(
        () => LocaleStripper(projectRoot: project.path).keep(['en']),
        throwsA(isA<LocaleStripException>()),
      );
      expect(remainingArbFiles(), ['app_en.arb', 'app_ja.arb', 'app_zh.arb']);
      expect(remainingFontFiles(), allFonts);
      expect(pubspecContent(), contains('NotoSansCJKsc'));
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

    test(
        'leaves an uncommitted fonts: block edit alone when nothing was '
        'stripped', () {
      // The exact sequence build_web.sh produces, because it arms the restore
      // from an EXIT trap *before* the strip: the developer has an uncommitted
      // edit inside the fonts: block, `keep` refuses it — that gate exists to
      // protect this edit — and then the trap runs restore. Rewriting the block
      // from HEAD at that point destroys what the gate just declined to build
      // over.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      final pubspec = File('${project.path}/pubspec.yaml');
      const edit = '    # WIP: an uncommitted edit inside the fonts: block';
      pubspec.writeAsStringSync(
        pubspec
            .readAsStringSync()
            .replaceFirst('  fonts:\n', '  fonts:\n$edit\n'),
      );
      final stripper = LocaleStripper(projectRoot: project.path);
      expect(() => stripper.keep(['en']), throwsA(isA<LocaleStripException>()));

      stripper.restore();

      expect(pubspecContent(), contains(edit));
    });

    test('puts back the comments interleaved between font families', () {
      // The real pubspec explains why Roboto is declared with a bare family name
      // in comments inside the fonts: block. Restoring the block by line range
      // has to bring those back, not just the declarations.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      final pubspec = File('${project.path}/pubspec.yaml');
      pubspec.writeAsStringSync(pubspec.readAsStringSync().replaceFirst(
            '    - family: packages/ui_kit_library/Roboto',
            '    # Roboto is the engine default global fallback\n'
                '    - family: packages/ui_kit_library/Roboto',
          ));
      commitEverything();
      final stripper = LocaleStripper(projectRoot: project.path);
      stripper.keep(['en']);

      stripper.restore();

      expect(pubspecContent(),
          contains('# Roboto is the engine default global fallback'));
      expect(pubspecContent(), contains('NotoSansCJKsc'));
    });

    test('leaves the rest of the pubspec untouched when it restores', () {
      // The block swap is bounded by the next key at two-space indent, so
      // everything after the fonts: block has to survive it verbatim.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      final pubspec = File('${project.path}/pubspec.yaml');
      pubspec.writeAsStringSync('${pubspec.readAsStringSync()}'
          '  assets:\n    - assets/config/\n');
      commitEverything();
      final stripper = LocaleStripper(projectRoot: project.path);
      stripper.keep(['en']);

      stripper.restore();

      expect(pubspecContent(), contains('    - assets/config/'));
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

  group('a CI job that edits pubspec.yaml', () {
    const allFonts = ['NotoSans-Latin.woff2', 'NotoSansCJKsc.subset.woff2'];

    /// Mimics the build step that stamps a version or build number into the
    /// pubspec before building, which leaves it modified (` M `) in git.
    void givenTheJobStampedTheVersion() {
      final pubspec = File('${project.path}/pubspec.yaml');
      pubspec.writeAsStringSync(
        pubspec.readAsStringSync().replaceFirst(
              'name: test_app',
              'name: test_app\nversion: 9.9.9+42',
            ),
      );
    }

    test('strips anyway, instead of refusing to build', () {
      // The Jenkins job stamps the version before building, so pubspec.yaml is
      // always modified by the time the strip runs. Refusing on that basis fails
      // every CI build.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      givenTheJobStampedTheVersion();

      expect(
        () => LocaleStripper(projectRoot: project.path).keep(['en']),
        returnsNormally,
      );
      expect(remainingArbFiles(), ['app_en.arb']);
    });

    test('keeps the version the job stamped when it restores', () {
      // Restoring pubspec.yaml with `git checkout --` would revert the version
      // along with the font declarations, silently un-stamping the build.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      givenTheJobStampedTheVersion();
      final stripper = LocaleStripper(projectRoot: project.path);
      stripper.keep(['en']);

      stripper.restore();

      expect(pubspecContent(), contains('version: 9.9.9+42'));
      expect(pubspecContent(), contains('NotoSansCJKsc'));
    });

    test('still refuses when a language pack itself is edited', () {
      // The gate that matters is unchanged: an edited ARB is inside the blast
      // radius of the git checkout that restore performs.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      File('${project.path}/lib/l10n/app_ja.arb')
          .writeAsStringSync('{"@@locale":"ja","edited":"yes"}');

      expect(
        () => LocaleStripper(projectRoot: project.path).keep(['en']),
        throwsA(isA<LocaleStripException>()),
      );
    });
  });

  group('verify', () {
    const allFonts = ['NotoSans-Latin.woff2', 'NotoSansCJKsc.subset.woff2'];

    test('passes on a tree with nothing stripped', () {
      givenProject(locales: ['en', 'ja'], fonts: allFonts);

      expect(LocaleStripper(projectRoot: project.path).verify, returnsNormally);
    });

    test('passes when only pubspec.yaml is modified', () {
      // What a CI job's version stamp looks like — not something to fail on.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      File('${project.path}/pubspec.yaml')
          .writeAsStringSync('${pubspecContent()}\nversion: 9.9.9+42\n');

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

    test('refuses when the pubspec fonts: block itself is edited', () {
      // The narrow half of the pubspec exclusion. restore rewrites this block
      // from `git show HEAD`, so an uncommitted edit inside it is inside the
      // blast radius even though the whole-file gate cannot be used.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      final pubspec = File('${project.path}/pubspec.yaml');
      pubspec.writeAsStringSync(pubspec.readAsStringSync().replaceFirst(
            '  fonts:\n',
            '  fonts:\n    - family: packages/ui_kit_library/MyNewFont\n'
                '      fonts:\n'
                '        - asset: assets/fonts/fallback/NotoSans-Latin.woff2\n',
          ));

      expect(
        () => LocaleStripper(projectRoot: project.path).verify(),
        throwsA(isA<LocaleStripException>()),
      );
    });

    test('still passes when the job stamps a version below the fonts block',
        () {
      // The gate has to stay blind to everything outside the block, including a
      // blank line the stamp lands after it when fonts: is the file's last key.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      final pubspec = File('${project.path}/pubspec.yaml');
      pubspec.writeAsStringSync('${pubspec.readAsStringSync()}\n'
          'version: 9.9.9+42\n');

      expect(LocaleStripper(projectRoot: project.path).verify, returnsNormally);
    });
  });

  group('generated localizations', () {
    const allFonts = ['NotoSans-Latin.woff2', 'NotoSansCJKsc.subset.woff2'];

    /// `lib/l10n/gen` as `flutter gen-l10n` leaves it — gitignored, so git cannot
    /// restore it and only the stripper can clear it.
    File givenGeneratedLocalizations() {
      final generated = File('${project.path}/lib/l10n/gen/'
          'app_localizations.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// generated for every locale');
      return generated;
    }

    test('deletes the generated sources a strip made English-only', () {
      // Left in place, a gen-l10n that fails after the restore keeps a stripped
      // tree's generated output while `git status` says the tree is clean, so the
      // app silently compiles English-only.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      final generated = givenGeneratedLocalizations();
      final stripper = LocaleStripper(projectRoot: project.path);
      stripper.keep(['en']);

      stripper.restore();

      expect(generated.existsSync(), isFalse);
    });

    test('leaves them alone when nothing was stripped', () {
      // A bare `restore` on a clean tree must not break the next `flutter run`.
      givenProject(locales: ['en', 'ja'], fonts: allFonts);
      final generated = givenGeneratedLocalizations();

      LocaleStripper(projectRoot: project.path).restore();

      expect(generated.existsSync(), isTrue);
    });
  });
}
