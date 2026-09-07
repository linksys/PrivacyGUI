import 'package:flutter/widgets.dart' show Locale;
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';

/// An [AppSettingsNotifier] pinned to one value, so a test can state what was
/// persisted without reaching SharedPreferences.
///
/// A subclass rather than a Mocktail mock, matching how this repo fakes Notifiers
/// everywhere else (55 test files do it this way, 2 mock a Notifier): the thing
/// under test reads `build()`'s return value, so overriding that one method is
/// both the whole contract and less brittle than stubbing a class whose API grows.
/// Art. VIII asks for Mocktail on *external dependencies* — services, transports —
/// which this is not.
///
/// Shared because it was written twice independently before it was written once
/// here: `supported_locales_provider_test.dart` needed a locale pinned and
/// `mascot_coordinator_notifier_test.dart` a `showMascot` flag, and both got their
/// own private copy.
class FakeAppSettingsNotifier extends AppSettingsNotifier {
  FakeAppSettingsNotifier(this._settings);

  /// Pins only the fields a caller names; everything else keeps its default.
  FakeAppSettingsNotifier.of({
    Locale? locale,
    bool showMascot = true,
  }) : _settings = AppSettings(locale: locale, showMascot: showMascot);

  final AppSettings _settings;

  @override
  AppSettings build() => _settings;
}
