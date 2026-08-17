import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/localization/fallback_font_resolver.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

/// The non-Latin fallback family the theme hands the engine (#1285).
///
/// ## Why a name and not a width
///
/// The bug this file exists for was invisible to every width assertion in the
/// suite. `lib/app.dart` passed `ThemeData.textTheme` an already-prefixed family,
/// ui_kit's `appTextTheme` styles carry `package: 'ui_kit_library'`, and
/// [TextStyle.fontFamilyFallback]'s *getter* prefixes again — so the theme asked
/// for `packages/ui_kit_library/packages/ui_kit_library/NotoSansTC`, which matches
/// nothing registered. Measured on ui_kit v2.34.11 with 8 Han code points: the
/// broken spelling and the correct one both come out at 112.0px, because an
/// unresolvable-but-non-empty fallback list still pushes the engine into fallback
/// resolution, where `test/util/app_test_fonts.dart` has registered `Roboto` and
/// the two `.SF`/`.AppleSystem` names with the Noto bytes. Only an empty list
/// takes the 56.0px path. So the harness masks it, and the only honest assertion
/// is on the family *name*.
///
/// The registered set is read out of `pubspec.yaml` rather than restated here.
/// Restating it would let this test agree with itself while the engine resolved
/// nothing, which is precisely the failure mode being guarded.
///
/// Run against the pre-#1285 spelling — `withFallbackFont` handing the theme
/// `prefixedFallbackFor` — 11 of these 16 fail: all ten locales and the
/// every-style sweep. The five that stay green are the ones that describe the two
/// spellings and the Latin/null no-ops, which is what they are for.
void main() {
  /// Families declared under `flutter: fonts:` in pubspec.yaml — the only names
  /// the engine can resolve.
  ///
  /// Parsed by hand rather than with a YAML package: the shape is a flat list of
  /// `- family: X` lines and the test tree has no yaml dependency. The count is
  /// asserted below so a reformat that breaks the parse cannot pass as "no
  /// families declared, so every entry is fine".
  final declaredFamilies = File('pubspec.yaml')
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.startsWith('- family:'))
      .map((l) => l.substring('- family:'.length).trim())
      .toSet();

  setUpAll(() {
    expect(declaredFamilies, isNotEmpty,
        reason: 'pubspec.yaml declares fallback families as "- family: X" '
            'lines; parsing found none, so this test would pass vacuously');
    expect(declaredFamilies, contains('packages/ui_kit_library/NotoSansTC'),
        reason: 'the CJK subsets are registered under package-prefixed family '
            'names so ui_kit AppText resolves to the app\'s own files; if that '
            'changed, the resolver below needs revisiting, not this line');
  });

  /// One locale per branch of [FallbackFontResolver.bareFamilyForLocale], plus
  /// the Latin case that must stay untouched.
  const cjkLocales = [
    Locale('zh', 'TW'),
    Locale('zh', 'CN'),
    Locale('zh', 'HK'),
    Locale('ja'),
    Locale('ko'),
    Locale('th'),
    Locale('ar'),
    Locale('el'),
    Locale('ru'),
    Locale('vi'),
  ];

  group('the family the theme asks for is one the engine has (#1285)', () {
    for (final locale in cjkLocales) {
      test('${locale.toLanguageTag()} resolves to a registered family', () {
        final theme = FallbackFontResolver.withFallbackFont(
          ThemeJsonConfig.defaultConfig().createLightTheme(),
          locale,
        );

        final fallback = theme.textTheme.bodyMedium!.fontFamilyFallback;
        expect(fallback, isNotNull,
            reason: '${locale.toLanguageTag()} is a non-Latin locale and must '
                'get a fallback family, or the engine treats its code points as '
                'missing and probes the CDN');
        expect(fallback, isNotEmpty);

        // The getter, not the field: what the engine is handed is the composed
        // name, and the whole bug lived in the difference between the two.
        for (final family in fallback!) {
          expect(declaredFamilies, contains(family),
              reason: 'the theme asks the engine for "$family", which is not '
                  'declared in pubspec.yaml. Double-prefixed names look like '
                  'this and cost nothing visible — an unresolvable family is '
                  'not tofu, the engine just falls through to the system font, '
                  'so the bundled subset silently stops drawing (#1285).');
        }
      });
    }

    test('every style in the theme is covered, not just bodyMedium', () {
      final theme = FallbackFontResolver.withFallbackFont(
        ThemeJsonConfig.defaultConfig().createLightTheme(),
        const Locale('ja'),
      );

      // Raw `Text` inherits whichever style its context names — a headline is as
      // likely to hold a Japanese string as a body line, so a fix that only
      // reached bodyMedium would leave most of the theme probing the CDN.
      final styles = <String, TextStyle?>{
        'displayLarge': theme.textTheme.displayLarge,
        'headlineMedium': theme.textTheme.headlineMedium,
        'titleMedium': theme.textTheme.titleMedium,
        'bodyLarge': theme.textTheme.bodyLarge,
        'bodySmall': theme.textTheme.bodySmall,
        'labelSmall': theme.textTheme.labelSmall,
      };
      for (final entry in styles.entries) {
        expect(entry.value, isNotNull,
            reason: '${entry.key} is missing from the theme');
        expect(entry.value!.fontFamilyFallback,
            ['packages/ui_kit_library/NotoSansJP'],
            reason: '${entry.key} does not carry the ja fallback family');
      }
    });

    test('a Latin-covered locale is left alone', () {
      final base = ThemeJsonConfig.defaultConfig().createLightTheme();
      final theme =
          FallbackFontResolver.withFallbackFont(base, const Locale('en'));

      expect(theme.textTheme.bodyMedium!.fontFamilyFallback, isNull,
          reason: 'en is covered by the primary font; adding a fallback list '
              'would push the engine into fallback resolution for no reason');
      expect(theme, same(base),
          reason: 'nothing to apply means nothing to rebuild');
    });

    test('a null locale is left alone', () {
      final base = ThemeJsonConfig.defaultConfig().createLightTheme();
      expect(FallbackFontResolver.withFallbackFont(base, null), same(base));
    });
  });

  group('the two spellings, and which style each is for', () {
    test('the bare name is what a package-carrying style needs', () {
      // ui_kit's appTextTheme is built from a base style with
      // `package: 'ui_kit_library'`, and TextStyle's fontFamilyFallback getter
      // composes `packages/<package>/` onto every entry. So the value that
      // reaches the engine is the prefixed one either way; passing it in already
      // prefixed is what produced the double.
      const style = TextStyle(
        fontFamily: 'NeueHaasGrotTextRound',
        package: 'ui_kit_library',
      );

      final bare = style.copyWith(
          fontFamilyFallback:
              FallbackFontResolver.bareFallbackFor(const Locale('zh', 'TW')));
      expect(bare.fontFamilyFallback, ['packages/ui_kit_library/NotoSansTC']);

      final prefixed = style.copyWith(
          fontFamilyFallback: FallbackFontResolver.prefixedFallbackFor(
              const Locale('zh', 'TW')));
      expect(prefixed.fontFamilyFallback,
          ['packages/ui_kit_library/packages/ui_kit_library/NotoSansTC'],
          reason: 'this is the #1285 defect, kept as a test so the reason '
              'prefixedFallbackFor exists cannot be misread as "use it here"');
    });

    test('the prefixed name is what a package-less style needs', () {
      const style = TextStyle(fontFamily: 'NeueHaasGrotTextRound');

      final prefixed = style.copyWith(
          fontFamilyFallback: FallbackFontResolver.prefixedFallbackFor(
              const Locale('zh', 'TW')));
      expect(
          prefixed.fontFamilyFallback, ['packages/ui_kit_library/NotoSansTC']);
      expect(declaredFamilies, containsAll(prefixed.fontFamilyFallback!));

      final bare = style.copyWith(
          fontFamilyFallback:
              FallbackFontResolver.bareFallbackFor(const Locale('zh', 'TW')));
      expect(declaredFamilies, isNot(containsAll(bare.fontFamilyFallback!)),
          reason: 'no bare family is registered — the pubspec declares the '
              'subsets under package-prefixed names on purpose, so ui_kit '
              'AppText resolves to the app\'s own files');
    });
  });

  group('every supported locale is decided, not defaulted', () {
    test('each supported locale either gets a family or is Latin-covered', () {
      // Not an assertion that every locale needs a fallback — most do not. It is
      // an assertion that the mapping has an opinion about each one, so a locale
      // added to the app cannot pick up `null` by falling off the switch
      // unnoticed.
      const nonLatinLanguages = {
        'zh',
        'ja',
        'ko',
        'th',
        'ar',
        'el',
        'ru',
        'vi',
      };

      for (final locale in AppLocalizations.supportedLocales) {
        final family = FallbackFontResolver.bareFamilyForLocale(
          languageCode: locale.languageCode,
          countryCode: locale.countryCode,
          scriptCode: locale.scriptCode,
        );
        if (nonLatinLanguages.contains(locale.languageCode)) {
          expect(family, isNotNull,
              reason: '${locale.toLanguageTag()} is not covered by the primary '
                  'Latin font and has no fallback family');
          expect(declaredFamilies, contains('packages/ui_kit_library/$family'),
              reason: '$family is mapped but not declared in pubspec.yaml');
        } else {
          expect(family, isNull,
              reason:
                  '${locale.toLanguageTag()} is Latin-covered but was given '
                  '$family; a needless fallback list changes shaping');
        }
      }
    });
  });
}
