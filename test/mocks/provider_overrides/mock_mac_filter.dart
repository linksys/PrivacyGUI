/// Provider overrides for the MAC Filtering tab of `usp_wifi_settings_view`
/// (save-based, #1636).
///
/// A `uspMacFilterProvider` pinned to one state, with `build()` returning it
/// directly (no fetch microtask) and the local mutations left as the real
/// mixin's — but since nothing calls `save()` here, no write happens. Used by
/// the golden suite, the layout gate and the view tests.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_notifier.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';

import '../test_data/scenes/mac_filter_scene_data.dart';
import '../test_data/scenes/wifi_settings_scene_data.dart';
import 'mock_wifi_settings.dart';

class FixedMacFilterNotifier extends UspMacFilterNotifier {
  FixedMacFilterNotifier(this._fixedState);

  final MacFilterState _fixedState;

  @override
  MacFilterState build() => _fixedState;
}

/// The MAC Filtering notifier alone, defaulting to [gateMacFilterState].
List<Override> macFilterOverrides([MacFilterState? state]) => [
      uspMacFilterProvider.overrideWith(
        () => FixedMacFilterNotifier(state ?? gateMacFilterState),
      ),
    ];

/// Everything the Wi-Fi page needs to open on its MAC Filtering tab: the two
/// Wi-Fi tabs' fixtures, the capability that makes the third tab exist (#1635),
/// and [macFilter] as that tab's notifier — defaulting to [gateMacFilterState].
///
/// Pass [macFilter] as an override list to swap in a recording notifier.
List<Override> wifiMacFilterTabOverrides(
        {MacFilterState? state, List<Override>? macFilter}) =>
    [
      ...wifiSettingsOverrides(
        wifiState: quickSetupOffState,
        advancedState: defaultAdvancedState,
      ),
      ...(macFilter ?? macFilterOverrides(state)),
      deviceCapabilitiesProvider.overrideWithValue(
          DeviceCapabilities(const {DeviceCapability.wifiMacFilter})),
    ];
