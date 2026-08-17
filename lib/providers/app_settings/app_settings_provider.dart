import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's persisted preferences, exactly as they were stored.
///
/// For `locale` specifically, prefer `activeLocaleProvider` in
/// `lib/localization/supported_locales_provider.dart`. The value here is the raw
/// setting and outlives the build that wrote it: an English-only build (see
/// `tools/locale_strip.dart`) reads back whatever language a full build last
/// persisted, and using that unnormalized sends locale-derived URLs somewhere the
/// strings are not. Read this one only to *write* the setting, or for the other
/// fields.
final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
    () => AppSettingsNotifier());

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void load() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(pAppSettings);
    state = settingsJson != null
        ? AppSettings.fromJson(settingsJson)
        : const AppSettings();
  }

  void update(AppSettings settings) {
    SharedPreferences.getInstance().then((value) {
      value.setString(pAppSettings, settings.toJson());
      state = settings;
    });
  }
}
