import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';

const _lanInfoSafetyOn = LanInfoUIModel(
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.1.100',
  maxAddress: '192.168.1.199',
  dnsServers: '208.67.222.222, 208.67.220.220',
);

const _lanInfoSafetyOff = LanInfoUIModel(
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.1.100',
  maxAddress: '192.168.1.199',
  dnsServers: '8.8.8.8, 8.8.4.4',
);

const menuLanDataBadgesOn = LanData(model: _lanInfoSafetyOn);
const menuLanDataBadgesOff = LanData(model: _lanInfoSafetyOff);

const menuPrivacyOn = UspInstantPrivacyState(
  isEnabled: true,
  connectedDevices: [],
  allowedDevices: [],
  macFilterContext: MacFilterContext.empty,
);

const menuPrivacyOff = UspInstantPrivacyState(
  isEnabled: false,
  connectedDevices: [],
  allowedDevices: [],
  macFilterContext: MacFilterContext.empty,
);
