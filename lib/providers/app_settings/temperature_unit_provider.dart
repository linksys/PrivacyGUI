import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/app_settings/temperature_unit.dart';

/// The region of the browser's (or the platform's) preferred locale, such as
/// `US` for `en-US`, or null when it names none.
///
/// The app's own language cannot stand in for it: English ships as one locale,
/// so a user in the UK and one in the US pick the same language.
final platformRegionProvider = Provider<String?>(
  (ref) => WidgetsBinding.instance.platformDispatcher.locale.countryCode,
);

/// The unit temperatures are shown in: the one the user picked, otherwise the
/// one their region expects (#1926).
final temperatureUnitProvider = Provider<TemperatureUnit>(
  (ref) =>
      ref.watch(appSettingsProvider.select((s) => s.temperatureUnit)) ??
      temperatureUnitForRegion(ref.watch(platformRegionProvider)),
);
