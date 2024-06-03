part of 'better_action.dart';

// List all possible values of each single JNAP action
enum _JNAPActionValue {
  transaction(value: 'http://linksys.com/jnap/core/Transaction'),
  checkAdminPassword(value: 'http://linksys.com/jnap/core/CheckAdminPassword'),
  checkAdminPassword2(
      value: 'http://linksys.com/jnap/core/CheckAdminPassword2'),
  checkAdminPassword3(
      value: 'http://linksys.com/jnap/core/CheckAdminPassword3'),
  coreSetAdminPassword(value: 'http://linksys.com/jnap/core/SetAdminPassword'),
  coreSetAdminPassword2(
      value: 'http://linksys.com/jnap/core/SetAdminPassword2'),
  coreSetAdminPassword3(
      value: 'http://linksys.com/jnap/core/SetAdminPassword3'),
  getAdminPasswordAuthStatus(
      value: 'http://linksys.com/jnap/core/GetAdminPasswordAuthStatus'),
  getAdminPasswordHint(
      value: 'http://linksys.com/jnap/core/GetAdminPasswordHint'),
  getDataUploadUserConsent(
      value: 'http://linksys.com/jnap/core/GetDataUploadUserConsent'),
  getDeviceInfo(value: 'http://linksys.com/jnap/core/GetDeviceInfo'),
  getUnsecuredWiFiWarning(
      value: 'http://linksys.com/jnap/core/GetUnsecuredWiFiWarning'),
  setUnsecuredWiFiWarning(
      value: 'http://linksys.com/jnap/core/SetUnsecuredWiFiWarning'),
  isAdminPasswordDefault(
      value: 'http://linksys.com/jnap/core/IsAdminPasswordDefault'),
  isServiceSupported(value: 'http://linksys.com/jnap/core/IsServiceSupported'),
  reboot(value: 'http://linksys.com/jnap/core/Reboot'),
  factoryReset(value: 'http://linksys.com/jnap/core/FactoryReset'),
  getDDNSSettings(value: 'http://linksys.com/jnap/ddns/GetDDNSSettings'),
  getDDNSStatus(value: 'http://linksys.com/jnap/ddns/GetDDNSStatus'),
  getDDNSStatus2(value: 'http://linksys.com/jnap/ddns/GetDDNSStatus2'),
  getSupportedDDNSProviders(
      value: 'http://linksys.com/jnap/ddns/GetSupportedDDNSProviders'),
  setDDNSSetting(value: 'http://linksys.com/jnap/ddns/SetDDNSSettings'),
  getDevices(value: 'http://linksys.com/jnap/devicelist/GetDevices'),
  getDevices3(value: 'http://linksys.com/jnap/devicelist/GetDevices3'),
  getLocalDevice(value: 'http://linksys.com/jnap/devicelist/GetLocalDevice'),
  setDeviceProperties(
      value: 'http://linksys.com/jnap/devicelist/SetDeviceProperties'),
  deleteDevice(value: 'http://linksys.com/jnap/devicelist/DeleteDevice'),

  ///
  execSysCommand(value: 'http://linksys.com/jnap/diagnostics/ExecSysCommand'),
  getPinStatus(value: 'http://linksys.com/jnap/diagnostics/GetPingStatus'),
  getSysInfoData(value: 'http://linksys.com/jnap/diagnostics/GetSysinfoData'),
  getSystemStats(value: 'http://linksys.com/jnap/diagnostics/GetSystemStats'),
  getTracerouteStatus(
      value: 'http://linksys.com/jnap/diagnostics/GetTracerouteStatus'),
  restorePreviousFirmware(
      value: 'http://linksys.com/jnap/diagnostics/RestorePreviousFirmware'),
  sendSysinfoEmail(
      value: 'http://linksys.com/jnap/diagnostics/SendSysinfoEmail'),
  startPing(value: 'http://linksys.com/jnap/diagnostics/StartPing'),
  startTracroute(value: 'http://linksys.com/jnap/diagnostics/StartTraceroute'),
  stopPing(value: 'http://linksys.com/jnap/diagnostics/StopPing'),
  stopTracroute(value: 'http://linksys.com/jnap/diagnostics/StopTraceroute'),

  ///
  getPortRangeForwardingRules(
      value: 'http://linksys.com/jnap/firewall/GetPortRangeForwardingRules'),
  getPortRangeTriggeringRules(
      value: 'http://linksys.com/jnap/firewall/GetPortRangeTriggeringRules'),
  getSinglePortForwardingRules(
      value: 'http://linksys.com/jnap/firewall/GetSinglePortForwardingRules'),
  setPortRangeForwardingRules(
      value: 'http://linksys.com/jnap/firewall/SetPortRangeForwardingRules'),
  setPortRangeTriggeringRules(
      value: 'http://linksys.com/jnap/firewall/SetPortRangeTriggeringRules'),
  setSinglePortForwardingRules(
      value: 'http://linksys.com/jnap/firewall/SetSinglePortForwardingRules'),
  getIPv6FirewallRules(
      value: 'http://linksys.com/jnap/firewall/GetIPv6FirewallRules'),
  setIPv6FirewallRules(
      value: 'http://linksys.com/jnap/firewall/SetIPv6FirewallRules'),
  getFirewallSettings(value: 'http://linksys.com/jnap/firewall/GetFirewallSettings'),
  setFirewallSettings(value: 'http://linksys.com/jnap/firewall/SetFirewallSettings'),
  getDMZSettings(value: 'http://linksys.com/jnap/firewall/GetDMZSettings'),
  setDMZSettings(value: 'http://linksys.com/jnap/firewall/SetDMZSettings'),
  getFirmwareUpdateStatus(
      value: 'http://linksys.com/jnap/firmwareupdate/GetFirmwareUpdateStatus'),
  getNodesFirmwareUpdateStatus(
      value:
          'http://linksys.com/jnap/nodes/firmwareupdate/GetFirmwareUpdateStatus'),
  getFirmwareUpdateSettings(
      value:
          'http://linksys.com/jnap/firmwareupdate/GetFirmwareUpdateSettings'),
  setFirmwareUpdateSettings(
      value:
          'http://linksys.com/jnap/firmwareupdate/SetFirmwareUpdateSettings'),
  updateFirmwareNow(
      value: 'http://linksys.com/jnap/nodes/firmwareupdate/UpdateFirmwareNow'),
  nodesUpdateFirmwareNow(
      value: 'http://linksys.com/jnap/nodes/firmwareupdate/UpdateFirmwareNow'),

  // TODO - Checking for the reference
  getGamingPrioritizationSettings(
      value:
          'http://linksys.com/jnap/gamingprioritization/GetGamingPrioritizationSettings:'),
  // TODO - Checking for the reference
  setGamingPrioritizationSettings(
      value:
          'http://linksys.com/jnap/gamingprioritization/SetGamingPrioritizationSettings'),
  getGuestNetworkClients(
      value: 'http://linksys.com/jnap/guestnetwork/GetGuestNetworkClients'),
  getGuestNetworkSettings(
      value: 'http://linksys.com/jnap/guestnetwork/GetGuestNetworkSettings'),
  getGuestNetworkSettings2(
      value: 'http://linksys.com/jnap/guestnetwork/GetGuestNetworkSettings2'),
  getGuestRadioSettings(
      value: 'http://linksys.com/jnap/guestnetwork/GetGuestRadioSettings'),
  getGuestRadioSettings2(
      value: 'http://linksys.com/jnap/guestnetwork/GetGuestRadioSettings2'),
  setGuestNetworkSettings(
      value: 'http://linksys.com/jnap/guestnetwork/SetGuestNetworkSettings'),
  // setGuestNetworkSettings2(value: 'http://linksys.com/jnap/guestnetwork/SetGuestNetworkSettings2'),
  setGuestNetworkSettings3(
      value: 'http://linksys.com/jnap/guestnetwork/SetGuestNetworkSettings3'),
  setGuestRadioSettings(
      value: 'http://linksys.com/jnap/guestnetwork/SetGuestRadioSettings'),
  setGuestRadioSettings2(
      value: 'http://linksys.com/jnap/guestnetwork/SetGuestRadioSettings2'),
  clearHealthCheckHistory(
      value: 'http://linksys.com/jnap/healthcheck/ClearHealthCheckHistory'),
  getHealthCheckResults(
      value: 'http://linksys.com/jnap/healthcheck/GetHealthCheckResults'),
  getHealthCheckStatus(
      value: 'http://linksys.com/jnap/healthcheck/GetHealthCheckStatus'),
  getSupportedHealthCheckModules(
      value:
          'http://linksys.com/jnap/healthcheck/GetSupportedHealthCheckModules'),
  runHealthCheck(value: 'http://linksys.com/jnap/healthcheck/RunHealthCheck'),
  stopHealthCheck(value: 'http://linksys.com/jnap/healthcheck/StopHealthCheck'),
  getLocalTime(value: 'http://linksys.com/jnap/locale/GetLocalTime'),
  getTimeSettings(value: 'http://linksys.com/jnap/locale/GetTimeSettings'),
  getLocale(value: 'http://linksys.com/jnap/locale/GetLocale'),
  setLocale(value: 'http://linksys.com/jnap/locale/SetLocale'),
  setTimeSettings(value: 'http://linksys.com/jnap/locale/SetTimeSettings'),
  getMACFilterSettings(
      value: 'http://linksys.com/jnap/macfilter/GetMACFilterSettings'),
  setMACFilterSettings(
      value: 'http://linksys.com/jnap/macfilter/SetMACFilterSettings'),
  getActiveMotionSensingBots(
      value:
          'http://linksys.com/jnap/motionsensing/GetActiveMotionSensingBots'),
  getMotionSensingSettings(
      value: 'http://linksys.com/jnap/motionsensing/GetMotionSensingSettings'),
  getNetworkConnections(
      value:
          'http://linksys.com/jnap/networkconnections/GetNetworkConnections'),
  getNetworkConnections2(
      value:
          'http://linksys.com/jnap/networkconnections/GetNetworkConnections2'),
  getNetworkSecuritySettings(
      value:
          'http://linksys.com/jnap/networksecurity/GetNetworkSecuritySettings'),
  getNetworkSecuritySettings2(
      value:
          'http://linksys.com/jnap/networksecurity/GetNetworkSecuritySettings2'),
  setNetworkSecuritySettings(
      value:
          'http://linksys.com/jnap/networksecurity/SetNetworkSecuritySettings'),
  setNetworkSecuritySettings2(
      value:
          'http://linksys.com/jnap/networksecurity/SetNetworkSecuritySettings2'),
  getBackhaulInfo(
      value: 'http://linksys.com/jnap/nodes/diagnostics/GetBackhaulInfo'),
  getBackhaulInfo2(
      value: 'http://linksys.com/jnap/nodes/diagnostics/GetBackhaulInfo2'),
  getNodeNeighborInfo(
      value: 'http://linksys.com/jnap/nodes/diagnostics/GetNodeNeighborInfo'),
  getSlaveBackhaulStatus(
      value:
          'http://linksys.com/jnap/nodes/diagnostics/GetSlaveBackhaulStatus'),
  refreshSlaveBackhaulData(
      value:
          'http://linksys.com/jnap/nodes/diagnostics/RefreshSlaveBackhaulData'),
  getNodesHealthCheckStatus(
      value: 'http://linksys.com/jnap/nodes/healthcheck/GetHealthCheckStatus'),
  getNodesHealthCheckResults(
      value: 'http://linksys.com/jnap/nodes/healthcheck/GetHealthCheckResults'),
  runNodesHealthCheck(
      value: 'http://linksys.com/jnap/nodes/healthcheck/RunHealthCheck'),
  stopNodesHealCheck(
      value: 'http://linksys.com/jnap/nodes/healthcheck/StopHealthCheck'),
  getNodesSupportedHealthCheckModules(
      value:
          'http://linksys.com/jnap/nodes/healthcheck/GetSupportedHealthCheckModules'),
  getNodesWirelessNetworkConnections(
      value:
          'http://linksys.com/jnap/nodes/networkconnections/GetNodesWirelessNetworkConnections'),
  // nodes optimization
  setTopologyOptimizationSettings(
      value:
          'http://linksys.com/jnap/nodes/topologyoptimization/SetTopologyOptimizationSettings'),
  setTopologyOptimizationSettings2(
      value:
          'http://linksys.com/jnap/nodes/topologyoptimization/SetTopologyOptimizationSettings2'),
  getTopologyOptimizationSettings(
      value:
          'http://linksys.com/jnap/nodes/topologyoptimization/GetTopologyOptimizationSettings'),
  getTopologyOptimizationSettings2(
      value:
          'http://linksys.com/jnap/nodes/topologyoptimization/GetTopologyOptimizationSettings2'),
  getOwnedNetworkID(
      value: 'http://linksys.com/jnap/ownednetwork/GetOwnedNetworkID'),
  isOwnedNetwork(value: 'http://linksys.com/jnap/ownednetwork/IsOwnedNetwork'),
  setNetworkOwner(
      value: 'http://linksys.com/jnap/ownednetwork/SetNetworkOwner'),
  getParentalControlSettings(
      value:
          'http://linksys.com/jnap/parentalcontrol/GetParentalControlSettings'),
  getPowerTableSettings(
      value: 'http://linksys.com/jnap/powertable/GetPowerTableSettings'),
  getQoSSettings(value: 'http://linksys.com/jnap/qos/GetQoSSettings'),
  getQoSSettings2(value: 'http://linksys.com/jnap/qos/GetQoSSettings2'),
  getDHCPClientLeases(
      value: 'http://linksys.com/jnap/router/GetDHCPClientLeases'),
  getIPv6Settings(value: 'http://linksys.com/jnap/router/GetIPv6Settings'),
  getIPv6Settings2(value: 'http://linksys.com/jnap/router/GetIPv6Settings2'),
  getLANSettings(value: 'http://linksys.com/jnap/router/GetLANSettings'),
  getMACAddressCloneSettings(
      value: 'http://linksys.com/jnap/router/GetMACAddressCloneSettings'),
  getWANSettings(value: 'http://linksys.com/jnap/router/GetWANSettings'),
  // TODO - Checking for the reference
  getWANSettings2(value: 'http://linksys.com/jnap/router/GetWANSettings2'),
  getWANSettings3(value: 'http://linksys.com/jnap/router/GetWANSettings3'),
  getWANSettings4(value: 'http://linksys.com/jnap/router/GetWANSettings4'),
  getWANSettings5(value: 'http://linksys.com/jnap/router/GetWANSettings5'),
  getWANStatus(value: 'http://linksys.com/jnap/router/GetWANStatus'),
  // TODO - Checking for the reference
  getWANStatus2(value: 'http://linksys.com/jnap/router/GetWANStatus2'),
  getWANStatus3(value: 'http://linksys.com/jnap/router/GetWANStatus3'),
  getWANDetectionStatus(
      value: 'http://linksys.com/jnap/nodes/setup/GetWANDetectionStatus'),
  setIPv6Settings(value: 'http://linksys.com/jnap/router/SetIPv6Settings'),
  setIPv6Settings2(value: 'http://linksys.com/jnap/router/SetIPv6Settings2'),
  setMACAddressCloneSettings(
      value: 'http://linksys.com/jnap/router/SetMACAddressCloneSettings'),
  setWANSettings(value: 'http://linksys.com/jnap/router/SetWANSettings'),
  // TODO - Checking for the reference
  setWANSettings2(value: 'http://linksys.com/jnap/router/SetWANSettings2'),
  setWANSettings3(value: 'http://linksys.com/jnap/router/SetWANSettings3'),
  setWANSettings4(value: 'http://linksys.com/jnap/router/SetWANSettings4'),
  setLANSettings(value: 'http://linksys.com/jnap/router/SetLANSettings'),
  renewDHCPWANLease(value: 'http://linksys.com/jnap/router/RenewDHCPWANLease'),
  renewDHCPIPv6Lease(
      value: 'http://linksys.com/jnap/router/RenewDHCPIPv6WANLease'),
  getManagementSettings(
      value: 'http://linksys.com/jnap/routermanagement/GetManagementSettings'),
  getManagementSettings2(
      value: 'http://linksys.com/jnap/routermanagement/GetManagementSettings2'),
  setManagementSettings(
      value: 'http://linksys.com/jnap/routermanagement/SetManagementSettings'),
  setManagementSettings2(
      value: 'http://linksys.com/jnap/routermanagement/SetManagementSettings2'),
  isAdminPasswordSetByUser(
      value: 'http://linksys.com/jnap/nodes/setup/IsAdminPasswordSetByUser'),
  setupSetAdminPassword(
      value: 'http://linksys.com/jnap/nodes/setup/SetAdminPassword'),
  setupSetAdminPassword2(
      value: 'http://linksys.com/jnap/nodes/setup/SetAdminPassword2'),
  verifyRouterResetCode(
      value: 'http://linksys.com/jnap/nodes/setup/VerifyRouterResetCode'),
  getVersionInfo(value: 'http://linksys.com/jnap/nodes/setup/GetVersionInfo'),
  getDeviceMode(value: 'http://linksys.com/jnap/nodes/smartmode/GetDeviceMode'),
  getSupportedDeviceModes(
      value: 'http://linksys.com/jnap/nodes/smartmode/GetSupportedDeviceModes'),
  setDeviceMode(value: 'http://linksys.com/jnap/nodes/smartmode/SetDeviceMode'),
  getRadioInfo(value: 'http://linksys.com/jnap/wirelessap/GetRadioInfo'),
  // TODO - Checking for the reference
  getRadioInfo2(value: 'http://linksys.com/jnap/wirelessap/GetRadioInfo2'),
  getRadioInfo3(value: 'http://linksys.com/jnap/wirelessap/GetRadioInfo3'),
  // TODO - Checking for the reference
  getMountPartitions(
      value: 'http://linksys.com/jnap/storage/GetMountedPartitions'),
  // TODO - Checking for the reference
  getPartitions(value: 'http://linksys.com/jnap/storage/GetPartitions'),
  getWPSServerSessionStatus(
      value: 'http://linksys.com/jnap/wirelessap/GetWPSServerSessionStatus'),
  setRadioSettings(
      value: 'http://linksys.com/jnap/wirelessap/SetRadioSettings'),
  // TODO - Checking for the reference
  setRadioSettings2(
      value: 'http://linksys.com/jnap/wirelessap/SetRadioSettings2'),
  setRadioSettings3(
      value: 'http://linksys.com/jnap/wirelessap/SetRadioSettings3'),
  // TODO - Checking for the reference
  getVLANTaggingSettings(
      value: 'http://linksys.com/jnap/vlantagging/GetVLANTaggingSettings'),
  // TODO - Checking for the reference
  getVLANTaggingSettings2(
      value: 'http://linksys.com/jnap/vlantagging/GetVLANTaggingSettings2'),
  // TODO - Checking for the reference
  setVLANTaggingSettings(
      value: 'http://linksys.com/jnap/vlantagging/SetVLANTaggingSettings'),
  // TODO - Checking for the reference
  setVLANTaggingSettings2(
      value: 'http://linksys.com/jnap/vlantagging/SetVLANTaggingSettings2'),
  getWirelessSchedulerSettings(
      value:
          'http://linksys.com/jnap/wirelessscheduler/GetWirelessSchedulerSettings'),
  getPortConnectionStatus(
      value: 'http://linksys.com/jnap/nodes/setup/GetPortConnectionStatus'),
  getWANPort(value: 'http://linksys.com/jnap/nodes/setup/GetWANPort'),
  setWANPort(value: 'http://linksys.com/jnap/nodes/setup/SetWANPort'),
  getInternetConnectionStatus(
      value: 'http://linksys.com/jnap/nodes/setup/GetInternetConnectionStatus'),
  getSimpleWiFiSettings(
      value: 'http://linksys.com/jnap/nodes/setup/GetSimpleWiFiSettings'),
  setSimpleWiFiSettings(
      value: 'http://linksys.com/jnap/nodes/setup/SetSimpleWiFiSettings'),
  getMACAddress(value: 'http://linksys.com/jnap/nodes/setup/GetMACAddress'),
  getBluetoothAutoOnboardingSettings(
      value:
          'http://linksys.com/jnap/nodes/autoonboarding/GetBluetoothAutoOnboardingSettings'),
  setBluetoothAutoOnboardingSettings(
      value:
          'http://linksys.com/jnap/nodes/autoonboarding/SetBluetoothAutoOnboardingSettings'),
  getBluetoothAutoOnboardingStatus(
      value:
          'http://linksys.com/jnap/nodes/autoonboarding/GetBluetoothAutoOnboardingStatus'),
  getBluetoothAutoOnboardingStatus2(
      value:
          'http://linksys.com/jnap/nodes/autoonboarding/GetBluetoothAutoOnboardingStatus2'),
  startBluetoothAutoOnboarding(
      value:
          'http://linksys.com/jnap/nodes/autoonboarding/StartBluetoothAutoOnboarding'),
  startBluetoothAutoOnboarding2(
      value:
          'http://linksys.com/jnap/nodes/autoonboarding/StartBluetoothAutoOnboarding2'),
  btGetScanUnconfiguredResult2(
      value:
          'http://linksys.com/jnap/nodes/bluetooth/BTGetScanUnconfiguredResult2'),
  btRequestScanUnconfigured2(
      value:
          'http://linksys.com/jnap/nodes/bluetooth/BTRequestScanUnconfigured2'),
  startBlinkingNodeLed(
      value: 'http://linksys.com/jnap/nodes/setup/StartBlinkingNodeLed'),
  stopBlinkingNodeLed(
      value: 'http://linksys.com/jnap/nodes/setup/StopBlinkingNodeLed'),
  getLedNightModeSetting(
      value: 'http://linksys.com/jnap/routerleds/GetLedNightModeSetting'),
  setLedNightModeSetting(
      value: 'http://linksys.com/jnap/routerleds/SetLedNightModeSetting'),
  setLedNightModeSetting2(
      value: 'http://linksys.com/jnap/routerleds/SetLedNightModeSetting2'),
  getIptvSettings(value: 'http://linksys.com/jnap/iptv/GetIPTVSettings'),
  setIptvSettings(value: 'http://linksys.com/jnap/iptv/SetIPTVSettings'),
  //mlo
  getMLOSettings(value: 'http://linksys.com/jnap/wirelessap/GetMLOSettings'),
  setMLOSettings(value: 'http://linksys.com/jnap/wirelessap/SetMLOSettings'),
  //dfs
  getDFSSettings(value: 'http://linksys.com/jnap/wirelessap/GetDFSSettings'),
  setDFSSettings(value: 'http://linksys.com/jnap/wirelessap/SetDFSSettings'),
  //airtime fairness
  getAirtimeFairnessSettings(
      value: 'http://linksys.com/jnap/wirelessap/GetAirtimeFairnessSettings'),
  setAirtimeFairnessSettings(
      value: 'http://linksys.com/jnap/wirelessap/SetAirtimeFairnessSettings'),
  getSelectedChannels(
      value: 'http://linksys.com/jnap/nodes/setup/GetSelectedChannels'),
  startAutoChannelSelection(
      value: 'http://linksys.com/jnap/nodes/setup/StartAutoChannelSelection'),
  //ui
  getRemoteSetting(value: 'http://linksys.com/jnap/ui/GetRemoteSetting'),
  setRemoteSetting(value: 'http://linksys.com/jnap/ui/SetRemoteSetting'),
  getAutoConfigurationSettings(
      value:
          'http://linksys.com/jnap/nodes/setup/GetAutoConfigurationSettings'),

  setUserAcknowledgedAutoConfiguration(
      value:
          'http://linksys.com/jnap/nodes/setup/SetUserAcknowledgedAutoConfiguration'),
  ;

  const _JNAPActionValue({required this.value});

  final String value;
}
