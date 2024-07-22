import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
