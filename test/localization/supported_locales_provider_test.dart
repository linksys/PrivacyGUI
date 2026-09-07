import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/supported_locales_provider.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';

import '../mocks/fake_app_settings_notifier.dart';

/// Coverage for the locale a build is allowed to run in.
///
/// `tools/locale_strip.dart` can ship a build with a single language pack, but
/// the user's choice outlives the build that made it: it is persisted to
/// SharedPreferences as a language tag and read back by a binary that may no
/// longer contain that language. These tests pin the normalization that keeps a
/// stale choice from leaking past the strings — most visibly into the country
/// segment of the legal links, where a stripped build would send the user to a
/// site in a language the build itself no longer offers a way back from.
void main() {
  group('resolveSupportedLocale', () {
    test('keeps a locale the build ships', () {
      expect(
        resolveSupportedLocale(
          const Locale('ja'),
          const [Locale('en'), Locale('ja')],
        ),
        const Locale('ja'),
      );
    });

    test('falls back to the first locale when the pack was stripped', () {
      // The English-only build reading a `ja` written by a full build.
      expect(
        resolveSupportedLocale(const Locale('ja'), const [Locale('en')]),
        const Locale('en'),
      );
    });

    test('resolves a regional variant onto the language the build ships', () {
      // Not a fallback to English: `zh_TW` strings are close enough to `zh` that
      // Flutter itself resolves them this way, and a strip that kept `zh` kept
      // the Han fonts with it.
      expect(
        resolveSupportedLocale(
          const Locale('zh', 'TW'),
          const [Locale('en'), Locale('zh')],
        ),
        const Locale('zh'),
      );
    });

    test('prefers the exact variant over its bare language', () {
      expect(
        resolveSupportedLocale(
          const Locale('zh', 'TW'),
          const [Locale('zh'), Locale('zh', 'TW')],
        ),
        const Locale('zh', 'TW'),
      );
    });

    test('falls back to English, not to the first locale in the list', () {
      // The retail list is alphabetical, so `supported.first` is `ar`: an
      // unresolvable locale used to put the whole app in Arabic, RTL and all.
      expect(
        resolveSupportedLocale(
          const Locale('xx'),
          const [Locale('ar'), Locale('en'), Locale('ja')],
        ),
        const Locale('en'),
      );
    });

    test('falls back on the real shipped list, not a hand-written one', () {
      // Pinned against the generated list, because the ordering is what made the
      // bug: nothing here is true by construction.
      expect(
        resolveSupportedLocale(
          const Locale('xx'),
          AppLocalizations.supportedLocales,
        ),
        const Locale('en'),
      );
    });

    test('still falls back within the set when English was stripped out', () {
      // Unreachable in practice — locale_strip refuses to drop the gen-l10n
      // template — but the function must not throw if it ever happens.
      expect(
        resolveSupportedLocale(const Locale('xx'), const [Locale('ja')]),
        const Locale('ja'),
      );
    });

    test('never returns a locale outside the shipped set', () {
      // The property the legal links depend on, stated directly.
      const shipped = [Locale('en')];
      for (final wanted in const [
        Locale('ja'),
        Locale('zh', 'TW'),
        Locale('ar'),
        Locale('en', 'US'),
      ]) {
        expect(shipped, contains(resolveSupportedLocale(wanted, shipped)));
      }
    });
  });

  group('providers', () {
    test('supportedLocalesProvider defaults to what the build compiled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(supportedLocalesProvider),
        AppLocalizations.supportedLocales,
      );
    });

    test('canPickLanguageProvider is false for a single-language build', () {
      final container = ProviderContainer(overrides: [
        supportedLocalesProvider.overrideWithValue(const [Locale('en')]),
      ]);
      addTearDown(container.dispose);

      expect(container.read(canPickLanguageProvider), isFalse);
    });

    test('canPickLanguageProvider is true once there is a choice', () {
      final container = ProviderContainer(overrides: [
        supportedLocalesProvider
            .overrideWithValue(const [Locale('en'), Locale('ja')]),
      ]);
      addTearDown(container.dispose);

      expect(container.read(canPickLanguageProvider), isTrue);
    });
  });

  group('activeLocaleProvider', () {
    /// A container whose persisted locale is [persisted] and whose build ships
    /// [shipped].
    ProviderContainer given({
      required Locale? persisted,
      required List<Locale> shipped,
    }) {
      final container = ProviderContainer(overrides: [
        supportedLocalesProvider.overrideWithValue(shipped),
        appSettingsProvider
            .overrideWith(() => FakeAppSettingsNotifier.of(locale: persisted)),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('normalizes a persisted locale the build no longer ships', () {
      // The whole point of the provider: every reader of this — the legal links
      // above all — used to read the raw `ja` and open linksys.com/jp/… on a build
      // whose picker is hidden, leaving no way back.
      final container =
          given(persisted: const Locale('ja'), shipped: const [Locale('en')]);

      expect(container.read(activeLocaleProvider), const Locale('en'));
    });

    test('keeps a persisted locale the build does ship', () {
      final container = given(
        persisted: const Locale('ja'),
        shipped: const [Locale('en'), Locale('ja')],
      );

      expect(container.read(activeLocaleProvider), const Locale('ja'));
    });

    test('never leaves the shipped set, whatever was persisted', () {
      // Stated as a property, because this is what the legal links depend on: the
      // country segment is derived from whatever this returns.
      for (final persisted in const [
        Locale('ja'),
        Locale('zh', 'TW'),
        Locale('ar'),
        null,
      ]) {
        const shipped = [Locale('en')];
        final container = given(persisted: persisted, shipped: shipped);

        expect(shipped, contains(container.read(activeLocaleProvider)),
            reason: 'persisted $persisted');
      }
    });
  });
}
