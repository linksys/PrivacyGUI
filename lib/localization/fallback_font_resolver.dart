import 'package:flutter/material.dart' show Locale, ThemeData;
import 'package:ui_kit_library/ui_kit.dart' show LocaleFallbackFont;

/// Maps a locale to the bundled fallback font family for scripts the primary
/// font (NeueHaasGrotTextRound) doesn't cover: CJK, Greek, Cyrillic,
/// Vietnamese, Thai, Arabic.
///
/// These families are declared under `fonts:` in pubspec.yaml (eager-loaded and
/// registered with the engine before the first frame; assets in
/// `assets/fonts/fallback/`) as `packages/ui_kit_library/<Family>`. The single
/// source of truth for the locale→family mapping lives HERE.
///
/// **Two consumption forms, and the prefix decides which — this matters:**
///
/// Nothing registered is called by a bare name, so the name that reaches the
/// engine must always end up prefixed. What differs is *who* prefixes it:
/// [TextStyle.fontFamilyFallback]'s getter composes `packages/<package>/` onto
/// every entry when the style declares a `package`, so on such a style the value
/// to pass is the BARE one and passing a prefixed one yields a double prefix
/// that matches nothing. On a style with no `package` nobody composes anything,
/// so the PREFIXED one is what to pass.
///
/// - [bareFallbackFor] — for styles carrying `package: ui_kit_library`. That is
///   ui_kit's `appTextTheme`, hence this app's whole [ThemeData.textTheme]
///   (see [withFallbackFont]), and it is also what ui_kit's [LocaleFallbackFont]
///   merges onto `AppText`'s base style.
/// - [prefixedFallbackFor] — for a style built locally with no `package`.
///
/// Returns null for locales fully covered by the primary Latin font
/// (en/fr/de/es/pt/nordic/pl/tr …).
class FallbackFontResolver {
  FallbackFontResolver._();

  static const _prefix = 'packages/ui_kit_library';

  /// Injects the BARE-name resolver into ui_kit. Call once at startup.
  static void install() {
    LocaleFallbackFont.resolver = bareFallbackFor;
  }

  /// Bare family name (no package prefix) for [locale] — for ui_kit injection.
  static String? bareFamilyForLocale({
    required String languageCode,
    String? countryCode,
    String? scriptCode,
  }) {
    switch (languageCode.toLowerCase()) {
      case 'ja':
        return 'NotoSansJP';
      case 'ko':
        return 'NotoSansKR';
      case 'zh':
        final region = countryCode?.toUpperCase();
        final script = scriptCode?.toLowerCase();
        final isTraditional = script == 'hant' ||
            region == 'TW' ||
            region == 'HK' ||
            region == 'MO';
        if (isTraditional) {
          return (region == 'HK' || region == 'MO')
              ? 'NotoSansHK'
              : 'NotoSansTC';
        }
        return 'NotoSansSC';
      case 'th':
        return 'NotoSansThai';
      case 'ar':
        return 'NotoSansArabic';
      case 'el': // Greek
      case 'ru': // Cyrillic
      case 'vi': // Vietnamese extended Latin
        return 'NotoSansLatinExt';
      default:
        return null;
    }
  }

  /// Bare-name fallback list for [locale] — for a [TextStyle] that declares
  /// `package: ui_kit_library`, which prefixes the entries itself.
  static List<String>? bareFallbackFor(Locale? locale) {
    if (locale == null) return null;
    final fam = bareFamilyForLocale(
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
      scriptCode: locale.scriptCode,
    );
    return fam == null ? null : [fam];
  }

  /// Package-prefixed fallback list for [locale] — for a [TextStyle] built with
  /// no `package`, where nothing composes the prefix on the way out.
  ///
  /// Not for [ThemeData.textTheme]: this app's is ui_kit's `appTextTheme`, whose
  /// styles do declare a package, so [withFallbackFont] passes the bare list.
  /// `lib/app.dart` used this one until #1285 and asked the engine for
  /// `packages/ui_kit_library/packages/ui_kit_library/NotoSansTC`.
  static List<String>? prefixedFallbackFor(Locale? locale) {
    final bare = bareFallbackFor(locale);
    return bare?.map((fam) => '$_prefix/$fam').toList();
  }

  /// [theme] with [locale]'s fallback family applied to its `textTheme`, or
  /// [theme] itself where the primary font already covers the locale.
  ///
  /// Covers raw `Text` and third-party widgets, which inherit
  /// [ThemeData.textTheme]; `AppText` gets the same family from ui_kit's own
  /// per-locale injection ([install]). Without the family in the style the engine
  /// treats non-Latin code points as missing and probes the CDN, which is what
  /// bundling the subsets exists to prevent.
  ///
  /// A function rather than four copies of the same three lines: `lib/app.dart`
  /// and three test harnesses each spelled this out, all four with the prefix bug
  /// (#1285), and the harnesses could not see the fix because they reproduced it.
  static ThemeData withFallbackFont(ThemeData theme, Locale? locale) {
    final fallback = bareFallbackFor(locale);
    if (fallback == null) return theme;
    return theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamilyFallback: fallback),
    );
  }
}
