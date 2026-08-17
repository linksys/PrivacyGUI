#!/usr/bin/env dart

/// Strips language packs and fallback fonts to produce an English-only build,
/// which saves 3,904 KB (3.81 MB) of delivered payload on flash-constrained
/// firmware. Measured, not estimated: 29,812 KB -> 25,908 KB.
///
/// A script rather than a branch because `app_en.arb` changes with nearly every
/// feature, so a branch whose diff is "delete the other 25 ARB files" pays a
/// merge conflict on every sync. A script also beats every compile-flag route: a
/// `--dart-define` cannot shrink anything, because `supportedLocales` references
/// every generated locale class, and deferred loading (`use-deferred-loading`)
/// makes the payload 72 KB *larger* while turning `lookupAppLocalizations` into
/// a `Future`. Deleting the ARB files before `gen-l10n` runs is the only thing
/// that removes the string tables.
///
/// The files it deletes are all tracked by git, so `restore` is a plain
/// `git checkout --` over a fixed path list — there is no backup directory to
/// leak. Never `git reset --hard`, and never a bare `git checkout`: the fixed
/// list is what promises unrelated work in progress survives.
///
/// `keep` computes and validates its whole plan — which packs, which fonts, and
/// the rewritten pubspec — before it deletes the first file, so a pubspec shape
/// it cannot parse aborts on an intact tree instead of half way through.
///
/// Usage:
///   dart run tools/locale_strip.dart keep en        # strip to English only
///   dart run tools/locale_strip.dart keep en,fr     # keep a second locale
///   dart run tools/locale_strip.dart keep all       # no-op
///   dart run tools/locale_strip.dart restore        # undo (idempotent)
///   dart run tools/locale_strip.dart verify         # assert nothing is stripped
library;

import 'dart:io';

const _usage = '''
Usage: dart run tools/locale_strip.dart <command>

  keep <locales>   Strip everything but these locales (comma-separated,
                   or "all" for a no-op). Fails if the strippable paths
                   have local changes.
  restore          Put every stripped file back. Idempotent.
  verify           Exit non-zero if anything is currently stripped.
''';

void main(List<String> args) {
  final stripper = LocaleStripper(projectRoot: Directory.current.path);
  try {
    switch (args) {
      case ['keep', final String locales]:
        stripper.keep(locales.split(','));
      case ['restore']:
        stripper.restore();
      case ['verify']:
        stripper.verify();
      default:
        stderr.write(_usage);
        exit(64); // EX_USAGE
    }
  } on LocaleStripException catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }
}

/// Raised for every condition that must abort a build rather than produce a
/// silently wrong payload.
class LocaleStripException implements Exception {
  LocaleStripException(this.message);

  final String message;

  @override
  String toString() => 'LocaleStripException: $message';
}

/// Removes the language packs and fallback fonts an English-only build does not
/// ship, and puts them back afterwards.
class LocaleStripper {
  LocaleStripper({required this.projectRoot});

  /// Root of the project being stripped. Injected so tests can run against a
  /// throwaway tree instead of the real repo.
  final String projectRoot;

  /// The sentinel that means "ship everything" — the retail build.
  static const keepAll = 'all';

  /// The paths [restore] checks out of git, so the list doubles as the promise
  /// that unrelated work in progress is never reverted.
  ///
  /// `pubspec.yaml` is deliberately absent even though [keep] rewrites it: a CI
  /// job stamps the version into it before building, and checking it out would
  /// silently revert that stamp. Listing it here made the pre-strip gate see that
  /// stamp as local work and refuse, which failed every CI build. Its `fonts:`
  /// block is put back by reinstating the declarations instead — see
  /// [_restoreFontDeclarations].
  static const strippablePaths = [
    'lib/l10n',
    'assets/fonts/fallback',
  ];

  /// The fallback fonts every build keeps regardless of which language packs it
  /// ships: extended Latin for the European scripts, and Roboto because the
  /// engine treats it as the global default fallback.
  ///
  /// Public so `test/tools/font_coverage_test.dart` can assert this and
  /// [fontsByLanguage] together cover every family the app's own resolver names.
  static const fontsSurvivingEveryStrip = {
    'NotoSans-Latin.woff2',
    'Roboto.woff2',
  };

  /// Which language needs which fallback font, so a strip that keeps a locale
  /// keeps the font that locale cannot render without.
  ///
  /// Mirrors `FallbackFontResolver.bareFamilyForLocale` in
  /// `lib/localization/fallback_font_resolver.dart`, which is the source of truth
  /// for the locale to family mapping the app resolves at runtime. This map is
  /// the same decision expressed over *file names*, because that is what a strip
  /// deletes.
  ///
  /// The two are held in step by `test/tools/font_coverage_test.dart` rather than
  /// by this comment: it walks the ARB files, asks the resolver for each locale's
  /// family, and resolves that family to a file through the pubspec's own
  /// `fonts:` block — so a language the resolver covers but this map forgets
  /// fails CI instead of shipping tofu. Do not hand-maintain a third mapping to
  /// make that check possible; the pubspec already is the family-to-file one.
  ///
  /// `el`/`ru`/`vi` resolve to NotoSansLatinExt, whose file every build keeps, so
  /// they need no entry. Languages absent from both this map and the resolver are
  /// covered by the primary Latin font.
  static const fontsByLanguage = {
    'ja': {'NotoSansCJKjp.subset.woff2'},
    'ko': {'NotoSansCJKkr.subset.woff2'},
    // A `zh` pack carries every regional variant's strings (zh, zh_TW), and
    // `_isKept` keeps them together, so keeping zh has to keep all three
    // Han subsets rather than guessing which variant will be selected.
    'zh': {
      'NotoSansCJKsc.subset.woff2',
      'NotoSansCJKtc.subset.woff2',
      'NotoSansCJKhk.subset.woff2',
    },
    'th': {'NotoSansThai.woff2'},
    'ar': {'NotoSansArabic.woff2'},
  };

  Directory get _arbDir => Directory('$projectRoot/lib/l10n');

  Directory get _fontDir => Directory('$projectRoot/assets/fonts/fallback');

  File get _pubspec => File('$projectRoot/pubspec.yaml');

  /// Deletes every language pack except those for [locales], plus the fallback
  /// fonts those locales cannot use.
  ///
  /// A regional variant travels with its parent language in both directions:
  /// keeping `zh` keeps `zh_TW` too, and keeping `zh_TW` pulls `zh` back in
  /// because gen-l10n requires a base locale as the fallback for any locale with
  /// a country code. Passing [keepAll] does nothing.
  ///
  /// Refuses a list that drops `l10n.yaml`'s template locale, which gen-l10n
  /// cannot run without.
  ///
  /// Entries are trimmed, because the list reaches this script as one string a
  /// human typed into a Jenkins build parameter, where `en, fr` is ordinary.
  void keep(List<String> requested) {
    var locales = [
      for (final locale in requested)
        if (locale.trim().isNotEmpty) locale.trim(),
    ];
    if (locales.isEmpty) {
      throw LocaleStripException(
          'no locales given — pass at least one, or "all"');
    }
    if (locales.contains(keepAll)) {
      stdout.writeln('locale_strip: "all" requested — nothing stripped');
      return;
    }
    stdout
        .writeln('locale_strip: keeping ${locales.join(', ')} in $projectRoot');
    verify();
    final available = _availableLocales();
    final unknown = locales.where((l) => !available.contains(l)).toList();
    if (unknown.isNotEmpty) {
      throw LocaleStripException(
        'no language pack for ${unknown.join(', ')} — '
        'available: ${available.join(', ')}',
      );
    }
    // Refused here rather than left to gen-l10n. Both of the shapes below make it
    // fail, loudly and with the trap putting everything back — but its error names
    // neither this script nor the LOCALES parameter that caused it, so the cost is
    // a whole CI build spent to learn what a check here says for free.
    final templateLocale = _templateLocale();
    if (templateLocale != null && !_isKept(templateLocale, locales)) {
      throw LocaleStripException(
        'l10n.yaml names app_$templateLocale.arb as its template-arb-file, so '
        'gen-l10n cannot run without it — add $templateLocale to the locale '
        'list',
      );
    }
    // A regional variant needs its parent language's pack: gen-l10n requires a
    // base locale as the fallback for any locale carrying a country code, so
    // `keep en,zh_TW` without this drops app_zh.arb and fails the generation.
    // Kept rather than rejected, because shipping zh_TW is a reasonable thing to
    // ask for — it just cannot travel alone.
    final withParents = <String>[
      ...locales,
      for (final locale in locales)
        if (_parentLanguageOf(locale) != locale &&
            !locales.contains(_parentLanguageOf(locale)) &&
            available.contains(_parentLanguageOf(locale)))
          _parentLanguageOf(locale),
    ];
    final addedParents = withParents.skip(locales.length).toList();
    if (addedParents.isNotEmpty) {
      stdout.writeln(
          '  language packs: also keeping ${addedParents.join(', ')} '
          '— gen-l10n needs a base locale as the fallback for a regional variant');
    }
    locales = withParents;
    // Everything below is computed and validated before the first deletion, so a
    // rejected pubspec shape aborts on an intact tree. Deleting first and
    // validating afterwards left a half-stripped working tree behind whenever the
    // pubspec rewrite threw, while the caller reported nothing was built.
    final doomedArbs = [
      for (final entity in _arbFiles())
        if (!_isKept(_localeOf(entity), locales)) entity,
    ];
    final doomedFonts = _fontsToStrip(locales);
    final pubspecWithoutThem = _pubspecWithout(
      doomedFonts.map(_fileNameOf).toList(),
    );

    final dropped = doomedArbs.map(_localeOf).toList()..sort();
    for (final entity in doomedArbs) {
      entity.deleteSync();
    }
    stdout.writeln('  language packs: dropped ${dropped.length} of '
        '${available.length} (${dropped.join(', ')})');
    _stripFallbackFonts(doomedFonts, pubspecWithoutThem);
    verifyDeclaredFontsExist();
    stdout.writeln('locale_strip: strip complete');
  }

  /// The fallback font files no kept locale needs.
  ///
  /// Driven by [fontsByLanguage] rather than by "everything but English",
  /// because `keep en,ja` ships the whole Japanese UI and deleting its only CJK
  /// font renders that UI as tofu boxes. There is no recovery on the router this
  /// build targets: the bundle is served offline from firmware `/www/`, and
  /// `fontFallbackBaseUrl` needs internet.
  ///
  /// A font on disk that no language claims is kept, not deleted. A new language
  /// pack whose entry is missing from the map is then a build that ships an
  /// unused font — wasted bytes, which is recoverable — instead of one that
  /// renders tofu.
  List<File> _fontsToStrip(List<String> locales) {
    // A regional variant needs its parent language's font, in both directions:
    // `keep zh` also keeps zh_TW's strings, and `keep zh_TW` is a Han locale in
    // its own right. Mapping every kept locale to its parent language covers both.
    final keptLanguages = locales.map(_parentLanguageOf).toSet();
    final needed = {
      ...fontsSurvivingEveryStrip,
      for (final language in keptLanguages) ...?fontsByLanguage[language],
    };
    final unclaimed = <String>[];
    final claimed = {
      ...fontsSurvivingEveryStrip,
      for (final fonts in fontsByLanguage.values) ...fonts,
    };
    final doomed = <File>[];
    for (final font in _fontFiles()) {
      final name = _fileNameOf(font);
      if (needed.contains(name)) {
        continue;
      }
      if (!claimed.contains(name)) {
        unclaimed.add(name);
        continue;
      }
      doomed.add(font);
    }
    if (unclaimed.isNotEmpty) {
      unclaimed.sort();
      stdout.writeln('  fallback fonts: kept ${unclaimed.join(', ')} — no '
          'language claims them, so this script will not delete them. Add them '
          'to fontsByLanguage or fontsSurvivingEveryStrip to make the '
          'decision explicit.');
    }
    return doomed;
  }

  /// Deletes [doomed] and writes the [pubspecWithoutThem] computed for them.
  ///
  /// Both arguments are computed by [keep] before it deletes anything, so this
  /// method cannot fail partway and leave the tree and the pubspec disagreeing.
  ///
  /// `FallbackFontResolver` is deliberately left alone: it goes on naming
  /// families that no longer exist, which costs nothing because the engine keys
  /// its CDN fallback off unresolved *code points*, not family names — the
  /// resolver returning null instead would not change a single request. Do not
  /// add a build flag to teach it which fonts survived; it would buy nothing and
  /// create a second source of truth alongside this script.
  ///
  /// The cost of this strip lands on user-supplied text in a script no kept
  /// locale uses (a CJK SSID on an English-only build), which shows as tofu while
  /// the router is offline. `fontFallbackBaseUrl` still renders it once the client
  /// has internet.
  void _stripFallbackFonts(List<File> doomed, _PubspecEdit pubspecWithoutThem) {
    if (doomed.isEmpty) {
      stdout.writeln('  fallback fonts: nothing to delete');
      return;
    }
    for (final font in doomed) {
      font.deleteSync();
    }
    final removed = doomed.map(_fileNameOf).toList()..sort();
    stdout.writeln('  fallback fonts: deleted ${removed.join(', ')}');
    pubspecWithoutThem.write(_pubspec);
    stdout.writeln('  pubspec.yaml: removed '
        '${pubspecWithoutThem.familiesRemoved} font declaration(s)');
  }

  /// Computes the pubspec contents without the `fonts:` families that declare
  /// [fontFileNames], without writing anything.
  ///
  /// Throws if the block cannot be parsed, which is what lets [keep] reject a
  /// pubspec shape it does not understand while the tree is still intact.
  ///
  /// A family is a `- family:` line plus every following line indented more
  /// deeply, so a family with two weights or an interleaved comment parses the
  /// same as the single-asset shape the repo happens to use today:
  ///
  ///     - family: packages/ui_kit_library/NotoSansSC
  ///       fonts:
  ///         - asset: assets/fonts/fallback/NotoSansCJKsc.subset.woff2
  ///         - asset: assets/fonts/fallback/NotoSansCJKsc.bold.woff2
  ///           weight: 700
  _PubspecEdit _pubspecWithout(List<String> fontFileNames) {
    final lines = _pubspec.readAsLinesSync();
    final block = _fontsBlockOf(lines, 'pubspec.yaml');
    final dropped = <int>{};
    var familiesRemoved = 0;
    final unmatched = {...fontFileNames};

    for (var i = block.start + 1; i < block.end; i++) {
      if (!_isFamilyHeader(lines[i])) {
        continue;
      }
      final familyEnd = _familyEndFrom(lines, i, block.end);
      final declared = <String>[];
      for (var j = i; j < familyEnd; j++) {
        final asset = _assetPathOf(lines[j]);
        if (asset != null) {
          declared.add(asset.split('/').last);
        }
      }
      final doomedHere =
          declared.where((name) => fontFileNames.contains(name)).toList();
      if (doomedHere.isEmpty) {
        continue;
      }
      // A family whose assets are only partly doomed would leave a declaration
      // pointing at a deleted file, which fails the Flutter build with an error
      // that never mentions this script.
      if (doomedHere.length != declared.length) {
        throw LocaleStripException(
          'pubspec.yaml line ${i + 1} declares both stripped and surviving '
          'fonts in one family (${declared.join(', ')}) — split the family or '
          'add the surviving fonts to the strip',
        );
      }
      unmatched.removeAll(doomedHere);
      familiesRemoved++;
      for (var j = i; j < familyEnd; j++) {
        dropped.add(j);
      }
    }

    if (unmatched.isNotEmpty) {
      final missing = unmatched.toList()..sort();
      throw LocaleStripException(
        'pubspec.yaml has no fonts: declaration for ${missing.join(', ')} — '
        'the fonts: block shape is not what this script understands, so it '
        'stopped before deleting anything',
      );
    }

    final kept = [
      for (var i = 0; i < lines.length; i++)
        if (!dropped.contains(i)) lines[i],
    ];
    return _PubspecEdit(kept, familiesRemoved);
  }

  bool _isFamilyHeader(String line) => line.trimLeft().startsWith('- family:');

  /// Index one past the last line belonging to the family starting at [start].
  ///
  /// The family owns every following line indented more deeply than its own
  /// `- family:` line, which is what makes the scan tolerate extra weights and
  /// comments inside the family.
  int _familyEndFrom(List<String> lines, int start, int blockEnd) {
    final indent = _indentOf(lines[start]);
    for (var i = start + 1; i < blockEnd; i++) {
      if (lines[i].trim().isEmpty) {
        continue;
      }
      if (_indentOf(lines[i]) <= indent) {
        return i;
      }
    }
    return blockEnd;
  }

  int _indentOf(String line) => line.length - line.trimLeft().length;

  /// The path an `- asset:` line points at, or null if [line] is not one.
  ///
  /// Tolerates the quoting and trailing comments YAML allows, because a path this
  /// failed to read used to abort the strip *after* the deletions.
  String? _assetPathOf(String line) {
    var trimmed = line.trim();
    if (trimmed.startsWith('#') || !trimmed.startsWith('- asset:')) {
      return null;
    }
    trimmed = trimmed.substring('- asset:'.length).trim();
    if (trimmed.startsWith('"') || trimmed.startsWith("'")) {
      final quote = trimmed[0];
      final close = trimmed.indexOf(quote, 1);
      return close < 0 ? trimmed.substring(1) : trimmed.substring(1, close);
    }
    final comment = trimmed.indexOf(' #');
    return (comment < 0 ? trimmed : trimmed.substring(0, comment)).trim();
  }

  /// Throws unless every font the pubspec declares is present on disk.
  ///
  /// A missing font file fails the Flutter build with an error that never
  /// mentions this script, so catching it here is what keeps a mis-stripped
  /// pubspec debuggable.
  void verifyDeclaredFontsExist() {
    final lines = _pubspec.readAsLinesSync();
    final block = _fontsBlockOf(lines, 'pubspec.yaml');
    final missing = <String>[];
    // Scoped to the fonts: block so an `- asset:` line elsewhere in the pubspec
    // cannot be mistaken for a font declaration.
    for (var i = block.start + 1; i < block.end; i++) {
      final assetPath = _assetPathOf(lines[i]);
      if (assetPath == null) {
        continue;
      }
      if (!File('$projectRoot/$assetPath').existsSync()) {
        missing.add(assetPath);
      }
    }
    if (missing.isNotEmpty) {
      throw LocaleStripException(
        'pubspec.yaml declares fonts that are not on disk: '
        '${missing.join(', ')}',
      );
    }
  }

  List<File> _fontFiles() => _fontDir.existsSync()
      ? _fontDir.listSync().whereType<File>().toList()
      : <File>[];

  /// Puts every stripped file back: [strippablePaths] by checking them out of
  /// git, and the pubspec's `fonts:` block by reinstating the committed one.
  ///
  /// A no-op on a tree nothing was stripped from — it does not touch the pubspec
  /// at all in that case, which is what keeps it out of an uncommitted `fonts:`
  /// edit's way.
  ///
  /// Idempotent, so it is safe from an exit handler that may already have run.
  /// On CI a killed build cannot leak anyway, because the job re-clones its
  /// workspace; this matters for the developer who runs a stripped build locally.
  void restore() {
    stdout.writeln('locale_strip: restoring ${strippablePaths.join(', ')} '
        'in $projectRoot');
    final stripped = _localChanges();
    stdout.writeln(stripped.isEmpty
        ? '  nothing was stripped'
        : '  putting back:\n${stripped.split('\n').map((l) => '    $l').join('\n')}');
    final result = Process.runSync(
      'git',
      ['checkout', '--', ...strippablePaths],
      workingDirectory: projectRoot,
    );
    if (result.exitCode != 0) {
      throw LocaleStripException(
        'could not restore ${strippablePaths.join(', ')}: ${result.stderr}',
      );
    }
    // Both only when something was actually stripped. An empty [_localChanges]
    // means no language pack is missing, so no strip reached the `fonts:` block
    // either and there is nothing to put back — while rewriting it anyway would
    // *destroy* an uncommitted edit to that block. That is not hypothetical:
    // build_web.sh arms this from an EXIT trap before the strip, so a developer
    // with such an edit gets refused by [_verifyFontsBlockIsCommitted] — the gate
    // built to protect the edit — and then the trap reaches here and discards it.
    // The generated sources are likewise already correct on a clean tree, and
    // deleting them would break the next `flutter run` for no reason.
    if (stripped.isNotEmpty) {
      _restoreFontDeclarations();
      _deleteGeneratedLocalizations();
    }
    stdout.writeln('locale_strip: restore complete');
  }

  /// Deletes `lib/l10n/gen`, which holds English-only generated output after a
  /// strip.
  ///
  /// The `git checkout` above cannot: the directory is gitignored, so it is not
  /// git's to restore. Leaving it means a `gen-l10n` that fails after this point
  /// keeps a stripped tree's generated sources, which [verify] is deliberately
  /// blind to — the app would compile and show English only, with a clean
  /// `git status` to say nothing is wrong. Deleting is safe because the caller
  /// regenerates, and a missing directory fails the build loudly.
  void _deleteGeneratedLocalizations() {
    final generated = Directory('$projectRoot/lib/l10n/gen');
    if (!generated.existsSync()) {
      return;
    }
    generated.deleteSync(recursive: true);
    stdout.writeln('  deleted lib/l10n/gen — run `flutter gen-l10n` to '
        'regenerate it');
  }

  /// Replaces the pubspec's `fonts:` block with the committed one, leaving the
  /// rest of the file — notably a CI job's version stamp — exactly as it is.
  void _restoreFontDeclarations() {
    final committed = _committedPubspecLines();
    final current = _pubspec.readAsLinesSync();
    final wanted = _fontsBlockOf(committed, 'the committed pubspec.yaml');
    final present = _fontsBlockOf(current, 'pubspec.yaml');
    if (_sameLines(wanted, present)) {
      stdout.writeln('  pubspec.yaml already declares every fallback font');
      return;
    }
    final restored = [
      ...current.take(present.start),
      ...wanted.lines,
      ...current.skip(present.end),
    ];
    _pubspec.writeAsStringSync('${restored.join('\n')}\n');
    stdout.writeln('  reinstated the pubspec.yaml fonts: block '
        '(${present.lines.length} lines -> ${wanted.lines.length})');
  }

  bool _sameLines(_FontsBlock a, _FontsBlock b) =>
      _sameStrings(a.lines, b.lines);

  List<String> _committedPubspecLines() {
    final result = Process.runSync(
      'git',
      ['show', 'HEAD:./pubspec.yaml'],
      workingDirectory: projectRoot,
    );
    if (result.exitCode != 0) {
      throw LocaleStripException(
        'could not read the committed pubspec.yaml: ${result.stderr}',
      );
    }
    final lines = (result.stdout as String).split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast(); // the trailing newline, which is not a line
    }
    return lines;
  }

  /// Locates the `fonts:` block in [lines], for the [what] named in errors.
  ///
  /// The block runs from `  fonts:` to the next non-blank line indented two
  /// spaces or less, which is the next key or comment in the `flutter:` section.
  /// Everything more deeply indented belongs to the block, including the
  /// comments interleaved between families.
  _FontsBlock _fontsBlockOf(List<String> lines, String what) {
    final start = lines.indexWhere((line) => line.trimRight() == '  fonts:');
    if (start < 0) {
      throw LocaleStripException('no "  fonts:" line in $what');
    }
    var end = lines.length;
    for (var i = start + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        continue;
      }
      if (line.length - line.trimLeft().length <= 2) {
        end = i;
        break;
      }
    }
    return _FontsBlock(start, end, lines.sublist(start, end));
  }

  /// Throws unless nothing inside the blast radius of [restore] has local
  /// changes: [strippablePaths], plus the pubspec's `fonts:` block.
  ///
  /// Runs before a strip, so uncommitted work is never inside that blast radius.
  /// Also the `verify` subcommand, for asserting by hand or from CI that a tree
  /// is intact — `build_web.sh` does not call it after the build, because the
  /// restore runs from an EXIT trap that a post-build check would sit inside.
  void verify() {
    final changes = _localChanges();
    if (changes.isNotEmpty) {
      throw LocaleStripException(
        'local changes in ${strippablePaths.join(', ')} — commit or stash them '
        'first, because restoring would discard them:\n$changes',
      );
    }
    _verifyFontsBlockIsCommitted();
    stdout.writeln('  no local changes in ${strippablePaths.join(', ')} '
        'or the pubspec.yaml fonts: block');
  }

  /// Throws when the pubspec's `fonts:` block differs from the committed one.
  ///
  /// [strippablePaths] cannot cover this: `pubspec.yaml` is excluded from it
  /// because a CI job stamps the version in before every build, and a
  /// whole-file gate refused every one of those builds. But [restore] rewrites
  /// the `fonts:` block from `git show HEAD`, so uncommitted edits *inside that
  /// block* are still inside the blast radius — the exact failure the exclusion
  /// was meant to avoid, just narrower. Comparing only the block closes the hole
  /// without ever seeing the version stamp.
  ///
  /// A stripped tree never reaches here: its deleted language packs make
  /// [_localChanges] non-empty, so [verify] has already thrown. [restore] reads
  /// [_localChanges] directly and is unaffected either way.
  void _verifyFontsBlockIsCommitted() {
    if (!_pubspec.existsSync()) {
      return;
    }
    final committed = _fontsBlockOf(
      _committedPubspecLines(),
      'the committed pubspec.yaml',
    );
    final current = _fontsBlockOf(_pubspec.readAsLinesSync(), 'pubspec.yaml');
    // Compared without trailing blank lines: when `fonts:` is the last key in the
    // file its block runs to EOF, so appending anything below it — a CI version
    // stamp, say — lands a blank line inside the block's range without touching a
    // single declaration.
    final committedLines = _withoutTrailingBlanks(committed.lines);
    final currentLines = _withoutTrailingBlanks(current.lines);
    if (_sameStrings(committedLines, currentLines)) {
      return;
    }
    throw LocaleStripException(
      'the pubspec.yaml fonts: block has local changes — commit or stash them '
      'first, because restoring would discard them:\n'
      '  committed: ${committedLines.length} lines\n'
      '  working:   ${currentLines.length} lines',
    );
  }

  List<String> _withoutTrailingBlanks(List<String> lines) {
    var end = lines.length;
    while (end > 0 && lines[end - 1].trim().isEmpty) {
      end--;
    }
    return lines.sublist(0, end);
  }

  bool _sameStrings(List<String> a, List<String> b) =>
      a.length == b.length &&
      Iterable.generate(a.length).every((i) => a[i] == b[i]);

  /// `git status --porcelain` over [strippablePaths] — empty when they are all
  /// as committed. Deliberately blind to `pubspec.yaml`, which a CI job stamps
  /// the version into on every build.
  String _localChanges() {
    final result = Process.runSync(
      'git',
      ['status', '--porcelain', '--', ...strippablePaths],
      workingDirectory: projectRoot,
    );
    if (result.exitCode != 0) {
      throw LocaleStripException('could not read git status: ${result.stderr}');
    }
    return (result.stdout as String).trim();
  }

  /// The locale of `l10n.yaml`'s `template-arb-file`, or null when there is no
  /// `l10n.yaml` to read — a throwaway test tree, say.
  ///
  /// Parsed by hand rather than with a YAML package: this is a script run by a
  /// shell build step, and one top-level key does not justify a dependency. A
  /// shape this cannot read is treated as "no template", which only gives up the
  /// check — [keep] never depends on it to decide what to delete.
  String? _templateLocale() {
    final config = File('$projectRoot/l10n.yaml');
    if (!config.existsSync()) {
      return null;
    }
    for (final line in config.readAsLinesSync()) {
      final match = RegExp(r'^template-arb-file:\s*(\S+)\s*$').firstMatch(line);
      if (match == null) {
        continue;
      }
      final fileName = match.group(1)!;
      if (!fileName.startsWith('app_') || !fileName.endsWith('.arb')) {
        return null;
      }
      return fileName.substring('app_'.length, fileName.length - '.arb'.length);
    }
    return null;
  }

  /// Whether [locale] survives a strip that keeps [kept], counting a regional
  /// variant as part of its parent language's pack.
  bool _isKept(String locale, List<String> kept) =>
      kept.contains(locale) || kept.contains(_parentLanguageOf(locale));

  String _parentLanguageOf(String locale) => locale.split('_').first;

  List<String> _availableLocales() =>
      _arbFiles().map(_localeOf).toList()..sort();

  List<File> _arbFiles() => _arbDir
      .listSync()
      .whereType<File>()
      .where((f) => _fileNameOf(f).startsWith('app_'))
      .where((f) => _fileNameOf(f).endsWith('.arb'))
      .toList();

  String _localeOf(File arb) {
    final name = _fileNameOf(arb);
    return name.substring('app_'.length, name.length - '.arb'.length);
  }

  String _fileNameOf(FileSystemEntity entity) => entity.uri.pathSegments.last;
}

/// A pubspec rewrite that has been computed but not yet written, so the caller
/// can validate the whole plan before it deletes the first file.
class _PubspecEdit {
  _PubspecEdit(this.lines, this.familiesRemoved);

  final List<String> lines;

  /// How many `fonts:` families the rewrite drops, for the log line.
  final int familiesRemoved;

  void write(File pubspec) =>
      pubspec.writeAsStringSync('${lines.join('\n')}\n');
}

/// Where the pubspec's `fonts:` block is and what it says, so a restore can swap
/// the committed block in without disturbing a line outside it.
class _FontsBlock {
  _FontsBlock(this.start, this.end, this.lines);

  /// Index of the `  fonts:` line.
  final int start;

  /// Index one past the block's last line.
  final int end;

  final List<String> lines;
}
