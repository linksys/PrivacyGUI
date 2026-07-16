import 'package:flutter/widgets.dart' show Locale;
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
/// **Two consumption forms — this matters:**
/// - ui_kit's [LocaleFallbackFont] (used by AppText) needs the BARE family name.
///   AppText's base TextStyle sets `package: ui_kit_library`, so `copyWith`
///   auto-prefixes fallback entries with `packages/ui_kit_library/`. Passing a
///   pre-prefixed name there produces a DOUBLE prefix that matches nothing.
/// - app.dart's ThemeData.textTheme fallback (for raw `Text`) does NOT go
///   through that base style, so it needs the PREFIXED name to match the
///   pubspec `fonts:` family.
///
/// Returns null for locales fully covered by the primary Latin font
/// (en/fr/de/es/pt/nordic/pl/tr …).
class FallbackFontResolver {
  FallbackFontResolver._();

  static const _prefix = 'packages/ui_kit_library';

  /// Injects the BARE-name resolver into ui_kit. Call once at startup.
  static void install() {
    LocaleFallbackFont.resolver = _bareFallbackFor;
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

  static List<String>? _bareFallbackFor(Locale? locale) {
    if (locale == null) return null;
    final fam = bareFamilyForLocale(
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
      scriptCode: locale.scriptCode,
    );
    return fam == null ? null : [fam];
  }

  /// Package-prefixed fallback list for [locale] — for app.dart's
  /// ThemeData.textTheme (raw `Text`, which doesn't get ui_kit's auto-prefix).
  static List<String>? prefixedFallbackFor(Locale? locale) {
    if (locale == null) return null;
    final fam = bareFamilyForLocale(
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
      scriptCode: locale.scriptCode,
    );
    return fam == null ? null : ['$_prefix/$fam'];
  }
}
