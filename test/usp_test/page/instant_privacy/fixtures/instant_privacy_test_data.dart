import 'package:privacy_gui/page/instant_privacy/models/instant_privacy_device_ui_model.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';

const _testDevices = [
  InstantPrivacyDeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:01',
    displayName: 'iPhone',
  ),
  InstantPrivacyDeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    displayName: 'MacBook Pro',
  ),
  InstantPrivacyDeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:03',
    displayName: 'iPad',
  ),
];

const disabledWithDevicesState = UspInstantPrivacyState(
  isEnabled: false,
  connectedDevices: _testDevices,
  allowedDevices: [],
  macFilterContext: MacFilterContext.empty,
);

const disabledEmptyState = UspInstantPrivacyState(
  isEnabled: false,
  connectedDevices: [],
  allowedDevices: [],
  macFilterContext: MacFilterContext.empty,
);

const enabledWithDevicesState = UspInstantPrivacyState(
  isEnabled: true,
  connectedDevices: [],
  allowedDevices: _testDevices,
  macFilterContext: MacFilterContext.empty,
);
