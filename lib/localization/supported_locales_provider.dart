import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/util/languages.dart';

/// The locales this build actually shipped.
///
/// Defaults to what `gen-l10n` compiled in, which `tools/locale_strip.dart` has
/// stripped down to one on an English-only build. Everything that needs to know
/// "how many languages does this build have" reads it from here, so the language
/// picker's visibility and its contents cannot disagree — they used to, because
/// visibility was injectable while the picker read the static list directly.
///
/// Overridden in tests with `overrideWithValue` to exercise both build flavours
/// without rebuilding.
final supportedLocalesProvider = Provider<List<Locale>>(
  (ref) => AppLocalizations.supportedLocales,
);

/// Whether this build ships more than one language, i.e. whether there is
/// anything for the user to pick between.
final canPickLanguageProvider = Provider<bool>(
  (ref) => ref.watch(supportedLocalesProvider).length > 1,
);

/// The locale the app is actually running in: the user's choice, or the system's,
/// normalized against what this build shipped.
///
/// Read this rather than `appSettingsProvider.locale` anywhere a locale leaves
/// the strings — the legal links' country segment above all. The raw setting
/// outlives the build that wrote it: it persists to SharedPreferences as a
/// language tag, and an English-only build reading a leftover `ja` would open
/// `linksys.com/jp/…` for a user whose picker is now hidden. One provider so
/// there is one answer.
///
/// Deliberately not written back to [appSettingsProvider]: a retail build has to
/// still find the user's `ja` if the router is upgraded back, and normalizing on
/// read costs nothing.
final activeLocaleProvider = Provider<Locale>((ref) {
  final systemLocale =
      Locale(getLanguageData(Intl.getCurrentLocale())['value']);
  return resolveSupportedLocale(
    ref.watch(appSettingsProvider.select((s) => s.locale)) ?? systemLocale,
    ref.watch(supportedLocalesProvider),
  );
});

/// [wanted] if [supported] ships it, otherwise English.
///
/// A locale the user picked before a build stripped its language pack is no
/// longer supported. Flutter would silently fall back to English for the strings
/// while everything derived from the locale went on using the stale value —
/// including the country segment in the legal links, which sent an English-only
/// build's user to a localized site they could not read their way back out of,
/// the picker now being hidden. Normalizing once keeps the whole app on one
/// locale — see [activeLocaleProvider], which is how the app reaches this.
///
/// The match is deliberately narrower than Flutter's own resolution: an exact hit
/// wins, and failing that the first locale of the same language does. It reads
/// `languageCode` and `countryCode` only.
///
/// `scriptCode` is ignored, so `zh_Hant_TW` would resolve to whichever `zh*`
/// comes first rather than to `zh_TW`. Unreachable as the app stands — a locale
/// only enters through the picker, which stores `Locale.toLanguageTag()` output
/// for a shipped locale, and none of the 26 carries a script subtag, so the
/// three-subtag branch in `LocaleExt.fromLanguageTag` has no writer. Left alone
/// rather than fixed speculatively: `basicLocaleListResolution` would handle it,
/// but `MaterialApp` already runs that over this function's result, and adding a
/// second full resolver to chase an unreachable case buys less than it risks.
///
/// The last resort is English, not `supported.first`. That distinction only
/// shows on the retail build, where the list is alphabetical and begins with
/// `ar` — an unresolvable locale used to land the whole app in Arabic, RTL and
/// all. English is `l10n.yaml`'s template locale, the one language every build
/// is guaranteed to ship, which is what makes it the safe floor here.
Locale resolveSupportedLocale(Locale wanted, List<Locale> supported) {
  for (final locale in supported) {
    if (locale == wanted) {
      return locale;
    }
  }
  for (final locale in supported) {
    if (locale.languageCode == wanted.languageCode) {
      return locale;
    }
  }
  return supported.firstWhere(
    (locale) => locale.languageCode == 'en',
    // Only reachable if a build strips English out, which the stripper now
    // refuses to do — gen-l10n cannot run without its template locale.
    orElse: () => supported.first,
  );
}
