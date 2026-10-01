/// Composed scenes for `mac_filter_view` (save-based toggle).
///
/// A `library;` file (not under `test/golden_test/`) so the layout gate can
/// import it, for the reason `instant_privacy_scene_data.dart` records.
library;

import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_status.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
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

MacFilterState _scene(MacFilterSettings settings) => MacFilterState(
      settings: Preservable(original: settings, current: settings),
      status:
          const MacFilterStatus(isLoading: false, connectedDevices: _devices),
    );

/// Off — only the toggle card shows, no list.
final disabledState = _scene(const MacFilterSettings(
  mode: MacFilterMode.disabled,
  macs: [],
));

/// Deny with a populated list — toggle on, header + Add + rows.
final denyWithDevicesState = _scene(const MacFilterSettings(
  mode: MacFilterMode.deny,
  macs: ['AA:BB:CC:DD:EE:01', '7A:BB:CC:DD:EE:03'],
));

/// Deny with an empty list — the list-editor empty state.
final denyEmptyState = _scene(const MacFilterSettings(
  mode: MacFilterMode.deny,
  macs: [],
));

/// The gate scene: the state rendering every region at once — the toggle card,
/// the list header + Add button, and device rows (one on a private MAC).
final gateMacFilterState = denyWithDevicesState;
