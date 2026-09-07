import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/localization/fallback_font_resolver.dart';

import '../../tools/locale_strip.dart';

/// Holds `tools/locale_strip.dart` in step with the app's own font resolver.
///
/// Three sources have to agree for a stripped build to render: the ARB files say
/// which languages ship, `FallbackFontResolver` says which font *family* each
/// language needs, and `LocaleStripper.fontsByLanguage` says which *files* to
/// keep. Only the first two produce any signal when someone adds a language —
/// forget the third and the build ships that language's strings with no font to
/// draw them, which is tofu on a router that is offline by design.
///
/// The stripper's own failure direction already handles the easy half: a font no
/// language claims is kept, not deleted, so a stale entry only wastes bytes. This
/// covers the half that cannot be made safe by construction.
///
/// No fourth mapping is introduced to do it. The pubspec's `fonts:` block is
/// already the family-to-file map the engine itself reads, so the chain is
/// resolved through that rather than through a table this test would have to
/// maintain.
void main() {
  final projectRoot = Directory.current.path;

  /// Family name -> asset file names, read out of the pubspec `fonts:` block.
  ///
  /// Parsed by hand for the same reason `locale_strip.dart` does it: two nested
  /// keys do not justify a YAML dependency in a test. Families are recorded under
  /// their bare name, because that is what the resolver returns — the pubspec
  /// carries the `packages/ui_kit_library/` prefix the engine needs.
  Map<String, Set<String>> pubspecFontFiles() {
    final families = <String, Set<String>>{};
    String? current;
    for (final line in File('$projectRoot/pubspec.yaml').readAsLinesSync()) {
      final family = RegExp(r'^\s*- family:\s*(\S+)\s*$').firstMatch(line);
      if (family != null) {
        current = family.group(1)!.split('/').last;
        families[current] = <String>{};
        continue;
      }
      final asset = RegExp(r'^\s*- asset:\s*(\S+)\s*$').firstMatch(line);
      if (asset != null && current != null) {
        families[current]!.add(asset.group(1)!.split('/').last);
      }
    }
    return families;
  }

  /// The languages this build ships, from the ARB files the stripper deletes.
  List<String> arbLocales() => Directory('$projectRoot/lib/l10n')
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((n) => n.startsWith('app_') && n.endsWith('.arb'))
      .map((n) => n.substring('app_'.length, n.length - '.arb'.length))
      .toList()
    ..sort();

  test('every shipped language has a font file the stripper knows to keep', () {
    final pubspecFamilies = pubspecFontFiles();

    final missing = <String>[];
    for (final locale in arbLocales()) {
      final parts = locale.split('_');
      final family = FallbackFontResolver.bareFamilyForLocale(
        languageCode: parts.first,
        countryCode: parts.length > 1 ? parts[1] : null,
      );
      // Null means the primary Latin font covers it — nothing to keep.
      if (family == null) {
        continue;
      }

      final files = pubspecFamilies[family];
      expect(files, isNotNull,
          reason: 'the resolver returns "$family" for $locale, but no pubspec '
              'fonts: family declares it — the engine could not load it either');
      expect(files, isNotEmpty,
          reason: 'pubspec family "$family" has no asset');

      // What a `keep en,<locale>` build would actually retain — this language's
      // own entry, not the union of every entry. Asking the union instead would
      // pass a language that resolves to a family some *other* language happens
      // to keep alive: `he` resolving to NotoSansArabic looks covered until the
      // build that ships `he` without `ar` deletes the file.
      final kept = {
        ...LocaleStripper.fontsSurvivingEveryStrip,
        ...?LocaleStripper.fontsByLanguage[parts.first],
      };

      if (!files!.any(kept.contains)) {
        missing.add('$locale -> $family -> ${files.join(', ')}');
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'these languages ship strings with no font a strip would keep, '
          'so they would render as tofu offline. Add the file(s) to '
          'LocaleStripper.fontsByLanguage under the language code:\n'
          '  ${missing.join('\n  ')}',
    );
  });

  test('keeping a language keeps a file for its own family, not just any', () {
    // The test above would pass if `fontsByLanguage` listed every font under one
    // language, so this pins the per-language direction: ask the stripper what a
    // `keep en,<lang>` build retains and check the resolver's family is in it.
    final pubspecFamilies = pubspecFontFiles();

    for (final locale in ['ja', 'ko', 'zh', 'zh_TW', 'th', 'ar']) {
      final parts = locale.split('_');
      final family = FallbackFontResolver.bareFamilyForLocale(
        languageCode: parts.first,
        countryCode: parts.length > 1 ? parts[1] : null,
      )!;
      final kept = {
        ...LocaleStripper.fontsSurvivingEveryStrip,
        // A regional variant is kept under its parent language's entry, which is
        // how the stripper itself resolves it.
        ...?LocaleStripper.fontsByLanguage[parts.first],
      };

      expect(
        pubspecFamilies[family]!.any(kept.contains),
        isTrue,
        reason: '`keep en,$locale` would delete every file for $family, which '
            'is the family the resolver asks for at runtime',
      );
    }
  });

  test('the resolver names no family the pubspec does not declare', () {
    // The other direction of the same mirror: a family the resolver returns but
    // the pubspec never declares cannot be loaded offline at all, stripped build
    // or not.
    final declared = pubspecFontFiles().keys.toSet();

    for (final probe in const [
      Locale('ja'),
      Locale('ko'),
      Locale('zh'),
      Locale('zh', 'TW'),
      Locale('zh', 'HK'),
      Locale('zh', 'MO'),
      Locale('th'),
      Locale('ar'),
      Locale('el'),
      Locale('ru'),
      Locale('vi'),
    ]) {
      final family = FallbackFontResolver.bareFamilyForLocale(
        languageCode: probe.languageCode,
        countryCode: probe.countryCode,
      );
      if (family == null) {
        continue;
      }
      expect(declared, contains(family),
          reason: 'resolver -> $family for $probe');
    }
  });
}
