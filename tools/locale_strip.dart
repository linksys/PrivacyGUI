#!/usr/bin/env dart

/// Strips language packs and fallback fonts to produce an English-only build.
///
/// See docs/adr/0001-english-only-build-by-build-time-stripping.md for why this
/// is a build-time script rather than a branch, and why on-demand language packs
/// were rejected.
///
/// The files it deletes are all tracked by git, so `restore` is a plain
/// `git checkout --` over a fixed path list — there is no backup directory to
/// leak.
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
  /// silently revert that stamp. Its `fonts:` block is put back by reinstating the
  /// declarations instead — see [_restoreFontDeclarations].
  static const strippablePaths = [
    'lib/l10n',
    'assets/fonts/fallback',
  ];

  /// The only fallback fonts an English-only build can use: extended Latin for
  /// the European scripts, and Roboto because the engine treats it as the global
  /// default fallback.
  static const _fontsSurvivingEnglishOnly = {
    'NotoSans-Latin.woff2',
    'Roboto.woff2',
  };

  Directory get _arbDir => Directory('$projectRoot/lib/l10n');

  Directory get _fontDir => Directory('$projectRoot/assets/fonts/fallback');

  File get _pubspec => File('$projectRoot/pubspec.yaml');

  /// Deletes every language pack except those for [locales], plus the fallback
  /// fonts those locales cannot use.
  ///
  /// A regional variant travels with its parent language, so keeping `zh` keeps
  /// `zh_TW` too. Passing [keepAll] does nothing.
  ///
  /// Entries are trimmed, because the list reaches this script as one string a
  /// human typed into a Jenkins build parameter, where `en, fr` is ordinary.
  void keep(List<String> requested) {
    final locales = [
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
    final dropped = <String>[];
    for (final entity in _arbFiles()) {
      final locale = _localeOf(entity);
      if (!_isKept(locale, locales)) {
        entity.deleteSync();
        dropped.add(locale);
      }
    }
    dropped.sort();
    stdout.writeln('  language packs: dropped ${dropped.length} of '
        '${available.length} (${dropped.join(', ')})');
    _stripFallbackFonts();
    verifyDeclaredFontsExist();
    stdout.writeln('locale_strip: strip complete');
  }

  /// Deletes the non-Latin fallback fonts and their pubspec declarations.
  ///
  /// `FallbackFontResolver` is deliberately left alone — see ADR 0001: it goes on
  /// naming families that no longer exist, which costs nothing because the engine
  /// keys its CDN fallback off unresolved code points, not family names.
  void _stripFallbackFonts() {
    final removed = <String>[];
    for (final font in _fontFiles()) {
      final name = _fileNameOf(font);
      if (!_fontsSurvivingEnglishOnly.contains(name)) {
        font.deleteSync();
        removed.add(name);
      }
    }
    removed.sort();
    if (removed.isNotEmpty) {
      stdout.writeln('  fallback fonts: deleted ${removed.join(', ')}');
      _removeFontDeclarations(removed);
    } else {
      stdout.writeln('  fallback fonts: nothing to delete');
    }
  }

  /// Rewrites the pubspec without the `fonts:` entries for [fontFileNames].
  ///
  /// Each entry is a fixed three-line group, so the asset line identifies the
  /// group and the two lines above it are the family header:
  ///
  ///     - family: packages/ui_kit_library/NotoSansSC
  ///       fonts:
  ///         - asset: assets/fonts/fallback/NotoSansCJKsc.subset.woff2
  void _removeFontDeclarations(List<String> fontFileNames) {
    final lines = _pubspec.readAsLinesSync();
    final dropped = <int>{};
    for (var i = 0; i < lines.length; i++) {
      final isDoomedAsset = lines[i].contains('- asset:') &&
          fontFileNames.any((name) => lines[i].endsWith('/$name'));
      if (!isDoomedAsset) {
        continue;
      }
      if (i < 2 || !lines[i - 2].contains('- family:')) {
        throw LocaleStripException(
          'pubspec.yaml line ${i + 1} declares a stripped font in an '
          'unexpected shape — expected a "- family:" line two lines above',
        );
      }
      dropped.addAll([i - 2, i - 1, i]);
    }
    final kept = [
      for (var i = 0; i < lines.length; i++)
        if (!dropped.contains(i)) lines[i],
    ];
    _pubspec.writeAsStringSync('${kept.join('\n')}\n');
    stdout.writeln('  pubspec.yaml: removed ${dropped.length ~/ 3} '
        'font declaration(s)');
  }

  /// Throws unless every font the pubspec declares is present on disk.
  ///
  /// A missing font file fails the Flutter build with an error that never
  /// mentions this script, so catching it here is what keeps a mis-stripped
  /// pubspec debuggable.
  void verifyDeclaredFontsExist() {
    final missing = <String>[];
    for (final line in _pubspec.readAsLinesSync()) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('- asset:')) {
        continue;
      }
      final assetPath = trimmed.substring('- asset:'.length).trim();
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
    _restoreFontDeclarations();
    stdout.writeln('locale_strip: restore complete');
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
      a.lines.length == b.lines.length &&
      Iterable.generate(a.lines.length).every((i) => a.lines[i] == b.lines[i]);

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

  /// Throws unless none of [strippablePaths] has local changes.
  ///
  /// Runs before a strip so uncommitted work is never inside the blast radius of
  /// the [restore] that follows, and after a build to prove nothing leaked.
  void verify() {
    final changes = _localChanges();
    if (changes.isNotEmpty) {
      throw LocaleStripException(
        'local changes in ${strippablePaths.join(', ')} — commit or stash them '
        'first, because restoring would discard them:\n$changes',
      );
    }
    stdout.writeln('  no local changes in ${strippablePaths.join(', ')}');
  }

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
