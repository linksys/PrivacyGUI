import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

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

/// [wanted] if [supported] ships it, otherwise the first supported locale.
///
/// A locale the user picked before a build stripped its language pack is no
/// longer supported. Flutter would silently fall back to English for the strings
/// while everything derived from the locale went on using the stale value —
/// including the country segment in the legal links, which sent an English-only
/// build's user to a localized site they could not read their way back out of,
/// the picker now being hidden. Normalizing once keeps the whole app on one
/// locale.
///
/// The match follows Flutter's own resolution: an exact hit wins, and failing
/// that a locale of the same language does, so a persisted `zh_TW` still
/// resolves against a build shipping only `zh`.
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
  return supported.first;
}
