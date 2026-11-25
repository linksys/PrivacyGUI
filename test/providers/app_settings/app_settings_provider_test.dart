// AppSettingsNotifier: app.dart loads the saved settings at start-up, and the
// theme mode and language tiles update them.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  /// The settings once [settled] holds: load and update are not awaitable.
  Future<AppSettings> settingsWhen(bool Function(AppSettings) settled) async {
    for (var i = 0; i < 100 && !settled(container.read(appSettingsProvider));
        i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return container.read(appSettingsProvider);
  }

  test('starts with the defaults', () {
    expect(container.read(appSettingsProvider), const AppSettings());
  });

  test('load reads the settings saved on an earlier launch', () async {
    SharedPreferences.setMockInitialValues(
        {pAppSettings: '{"themeMode":"dark","locale":"ja"}'});

    container.read(appSettingsProvider.notifier).load();

    expect(
        await settingsWhen((s) => s.themeMode == ThemeMode.dark),
        const AppSettings(themeMode: ThemeMode.dark, locale: Locale('ja')));
  });

  test('load keeps the defaults on a first launch', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = container.read(appSettingsProvider.notifier);
    notifier.update(const AppSettings(themeMode: ThemeMode.light));
    await settingsWhen((s) => s.themeMode == ThemeMode.light);
    SharedPreferences.setMockInitialValues({});

    notifier.load();

    expect(await settingsWhen((s) => s.themeMode == ThemeMode.system),
        const AppSettings());
  });

  test('update saves the settings, then shows them', () async {
    SharedPreferences.setMockInitialValues({});

    container
        .read(appSettingsProvider.notifier)
        .update(const AppSettings(themeMode: ThemeMode.dark, locale: Locale('de')));

    expect(
        await settingsWhen((s) => s.themeMode == ThemeMode.dark),
        const AppSettings(themeMode: ThemeMode.dark, locale: Locale('de')));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(pAppSettings),
        '{"themeMode":"dark","locale":"de","themeColor":null}');
  });
}
