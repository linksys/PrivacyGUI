/// Composed scenes for `instant_privacy_view` (save-based Allow toggle).
///
/// A `library;` file (not under `test/golden_test/`) so the layout gate can
/// import it, for the reason recorded here since #1380.
library;

import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_status.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

const _devices = [
  MacFilterDeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:01',
      displayName: 'Laptop',
      ipAddress: '192.168.1.10'),
  MacFilterDeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:02',
      displayName: 'Phone',
      ipAddress: '192.168.1.11'),
  MacFilterDeviceUIModel(
      mac: '7A:BB:CC:DD:EE:03',
      displayName: 'Tablet',
      isPrivateMac: true,
      ipAddress: '192.168.1.12'),
];

UspInstantPrivacyState _scene(MacFilterSettings settings,
        {List<MacFilterDeviceUIModel> devices = _devices}) =>
    UspInstantPrivacyState(
      settings: Preservable(original: settings, current: settings),
      status: MacFilterStatus(isLoading: false, connectedDevices: devices),
    );

/// Off — only the toggle card and (nothing else), devices available to lock.
final disabledWithDevicesState =
    _scene(const MacFilterSettings(mode: MacFilterMode.disabled, macs: []));

/// Off, and no devices connected — the toggle cannot usefully be turned on.
final disabledEmptyState = _scene(
  const MacFilterSettings(mode: MacFilterMode.disabled, macs: []),
  devices: const [],
);

/// On (Allow) with an allow-list that includes the private-MAC device — renders
/// the banner, the badge, the list header and rows all at once.
final enabledWithDevicesState = _scene(const MacFilterSettings(
  mode: MacFilterMode.allow,
  macs: ['AA:BB:CC:DD:EE:01', '7A:BB:CC:DD:EE:03'],
));

/// The gate scene: the state rendering every region at once.
final gateInstantPrivacyState = enabledWithDevicesState;
