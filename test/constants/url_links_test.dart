import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

/// Coverage for the country segment the app splices into `store.linksys.com`
/// links.
///
/// This is the hop `activeLocaleProvider` exists to feed, and it had no tests at
/// all: the locale a user picked reaches the network here, so a normalization bug
/// upstream shows up as a link to a site in the wrong language. The English-only
/// build makes it sharper — the picker is hidden there, so whatever this resolves
/// to is what the user is stuck with.
void main() {
  group('officialWebUrlFor', () {
    test('splices the mapped country in for a language-only locale', () {
      expect(
        officialWebUrlFor(linkSupport, locale: const Locale('ja')),
        'https://store.linksys.com/jp/linksys-support',
      );
    });

    test('prefers the locale country code over the language mapping', () {
      // `zh` maps to `cn`, but a zh_TW user must not be sent to the China store.
      expect(
        officialWebUrlFor(linkSupport, locale: const Locale('zh', 'TW')),
        'https://store.linksys.com/tw/linksys-support',
      );
      expect(
        officialWebUrlFor(linkSupport, locale: const Locale('zh')),
        'https://store.linksys.com/cn/linksys-support',
      );
    });

    test('sends an English locale to the US store', () {
      // Pinned deliberately: this is the default a user with no language
      // preference now lands on, because activeLocaleProvider resolves an absent
      // setting to `en` rather than leaving it null. The same URL was already
      // live for anyone who explicitly picked English.
      expect(
        officialWebUrlFor(linkSupport, locale: const Locale('en')),
        'https://store.linksys.com/us/linksys-support',
      );
    });

    test('leaves the URL bare when no locale is given', () {
      // The pre-activeLocaleProvider behaviour, kept for callers that have no
      // locale to offer — remote_assistance_dialog passes none.
      expect(officialWebUrlFor(linkSupport), linkSupport);
    });

    test('leaves other hosts alone, country segment or not', () {
      // The blast radius of the locale argument, stated directly: the legal pages
      // and every FAQ article are on different hosts and must come through
      // untouched, whatever the locale.
      for (final url in [linkEULA, linkTerms, linkPrivacy, linkThirdParty]) {
        expect(officialWebUrlFor(url, locale: const Locale('ja')), url);
      }
    });

    test('maps every locale this build ships', () {
      // The property that keeps `/null/` out of a real URL. Nothing validates
      // officialWebConutryMapping against the ARB files, so a new language pack
      // whose entry is missing would splice the string "null" into the path —
      // and only for the two store links, which is exactly the kind of gap that
      // ships.
      for (final locale in AppLocalizations.supportedLocales) {
        final url = officialWebUrlFor(linkSupport, locale: locale);

        expect(url, isNot(contains('/null/')), reason: 'locale $locale');
        expect(url, startsWith('https://store.linksys.com/'));
      }
    });
  });
}
