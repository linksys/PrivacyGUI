/// Composed scenes for `mac_filter_view` — the golden suite's mode states plus
/// the gate scene.
///
/// A `library;` file (not under `test/golden_test/`) so the layout gate can
/// import it, for the reason `instant_privacy_scene_data.dart` records.
library;

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

/// Off — only the mode card shows, no list.
const disabledState = MacFilterState(
  mode: MacFilterMode.disabled,
  macs: [],
  connectedDevices: _devices,
);

/// Deny with a populated list.
const denyWithDevicesState = MacFilterState(
  mode: MacFilterMode.deny,
  macs: ['AA:BB:CC:DD:EE:01', '7A:BB:CC:DD:EE:03'],
  connectedDevices: _devices,
);

/// Allow with a populated list.
const allowWithDevicesState = MacFilterState(
  mode: MacFilterMode.allow,
  macs: ['AA:BB:CC:DD:EE:01'],
  connectedDevices: _devices,
);

/// Enabled with an empty list — the list-editor empty state.
const enabledEmptyState = MacFilterState(
  mode: MacFilterMode.deny,
  macs: [],
  connectedDevices: _devices,
);

/// The gate scene: the one state rendering every region at once — the mode
/// card, the list header + Add button, and device rows (one on a private MAC).
const gateMacFilterState = MacFilterState(
  mode: MacFilterMode.deny,
  macs: ['AA:BB:CC:DD:EE:01', '7A:BB:CC:DD:EE:03'],
  connectedDevices: _devices,
);
