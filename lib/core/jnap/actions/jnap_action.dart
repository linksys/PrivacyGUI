part of 'better_action.dart';

// List all useful JNAP actions in the app.
// Each item is one action, whatever its version: it declares its URL at the
// lowest version, and the URL each service that defines a newer version
// upgrades it to. That is the only place an action's URLs are written (#1923).
enum JNAPAction {
  transaction('core/Transaction'),
  // auto onboarding
  startBlueboothAutoOnboarding(
      'nodes/autoonboarding/StartBluetoothAutoOnboarding',
      upgrades: {
        JNAPService.autoOnboarding3:
            'nodes/autoonboarding/StartBluetoothAutoOnboarding2',
      }),
  getBluetoothAutoOnboardingStatus(
      'nodes/autoonboarding/GetBluetoothAutoOnboardingStatus',
      upgrades: {
        JNAPService.autoOnboarding2:
            'nodes/autoonboarding/GetBluetoothAutoOnboardingStatus2',
      }),
  getBluetoothAutoOnboardingSettings(
      'nodes/autoonboarding/GetBluetoothAutoOnboardingSettings'),
  setBluetoothAutoOnboardingSettings(
      'nodes/autoonboarding/SetBluetoothAutoOnboardingSettings'),
  setWiredAutoOnboardingSettings(
      'nodes/autoonboarding/SetWiredAutoOnboardingSettings'),
  getWiredAutoOnboardingSettings(
      'nodes/autoonboarding/GetWiredAutoOnboardingSettings'),
  // bluetooth
  btGetScanUnconfiguredResult('nodes/bluetooth/BTGetScanUnconfiguredResult2'),
  btRequestScanUnconfigured('nodes/bluetooth/BTRequestScanUnconfigured2'),
  // core
  checkAdminPassword('core/CheckAdminPassword', upgrades: {
    JNAPService.core2: 'core/CheckAdminPassword2',
    JNAPService.core7: 'core/CheckAdminPassword3',
  }),
  pnpCheckAdminPassword('core/CheckAdminPassword2', upgrades: {
    JNAPService.core7: 'core/CheckAdminPassword3',
  }),
  coreSetAdminPassword('core/SetAdminPassword', upgrades: {
    JNAPService.core3: 'core/SetAdminPassword2',
    JNAPService.core7: 'core/SetAdminPassword3',
  }),
  pnpSetAdminPassword('core/SetAdminPassword2', upgrades: {
    JNAPService.core7: 'core/SetAdminPassword3',
  }),
  getAdminPasswordAuthStatus('core/GetAdminPasswordAuthStatus'),
  getAdminPasswordHint('core/GetAdminPasswordHint'),
  getDataUploadUserConsent('core/GetDataUploadUserConsent'),
  getDeviceInfo('core/GetDeviceInfo'),
  getUnsecuredWiFiWarning('core/GetUnsecuredWiFiWarning'),
  setUnsecuredWiFiWarning('core/SetUnsecuredWiFiWarning'),
  isAdminPasswordDefault('core/IsAdminPasswordDefault'),
  isServiceSupported('core/IsServiceSupported'),
  reboot('core/Reboot'),
  reboot2('core/Reboot2'),
  factoryReset('core/FactoryReset'),
  factoryReset2('core/FactoryReset2'),
  // ddns
  getDDNSSettings('ddns/GetDDNSSettings'),
  getDDNSStatus('ddns/GetDDNSStatus', upgrades: {
    JNAPService.ddns3: 'ddns/GetDDNSStatus2',
  }),
  getSupportedDDNSProviders('ddns/GetSupportedDDNSProviders'),
  setDDNSSetting('ddns/SetDDNSSettings'),
  // deviceList
  getDevices('devicelist/GetDevices', upgrades: {
    JNAPService.deviceList4: 'devicelist/GetDevices3',
  }),
  getLocalDevice('devicelist/GetLocalDevice'),
  setDeviceProperties('devicelist/SetDeviceProperties'),
  deleteDevice('devicelist/DeleteDevice'),
  // diagnostics
  execSysCommand('diagnostics/ExecSysCommand'),
  getPingStatus('diagnostics/GetPingStatus'),
  getSysInfoData('diagnostics/GetSysinfoData'),
  getSystemStats('diagnostics/GetSystemStats', upgrades: {
    JNAPService.diagnostics10: 'diagnostics/GetSystemStats2',
  }),
  getTracerouteStatus('diagnostics/GetTracerouteStatus'),
  restorePreviousFirmware('diagnostics/RestorePreviousFirmware'),
  sendSysinfoEmail('diagnostics/SendSysinfoEmail'),
  startPing('diagnostics/StartPing'),
  startTracroute('diagnostics/StartTraceroute'),
  stopPing('diagnostics/StopPing'),
  stopTracroute('diagnostics/StopTraceroute'),
  // firewall
  getPortRangeForwardingRules('firewall/GetPortRangeForwardingRules'),
  getPortRangeTriggeringRules('firewall/GetPortRangeTriggeringRules'),
  getSinglePortForwardingRules('firewall/GetSinglePortForwardingRules'),
  setPortRangeForwardingRules('firewall/SetPortRangeForwardingRules'),
  setPortRangeTriggeringRules('firewall/SetPortRangeTriggeringRules'),
  setSinglePortForwardingRules('firewall/SetSinglePortForwardingRules'),
  getIPv6FirewallRules('firewall/GetIPv6FirewallRules'),
  setIPv6FirewallRules('firewall/SetIPv6FirewallRules'),
  getFirewallSettings('firewall/GetFirewallSettings'),
  setFirewallSettings('firewall/SetFirewallSettings'),
  getDMZSettings('firewall/GetDMZSettings'),
  setDMZSettings('firewall/SetDMZSettings'),
  getALGSettings('firewall/GetALGSettings'),
  setALGSettings('firewall/SetALGSettings'),
  // firmwareUpdate
  getFirmwareUpdateStatus('firmwareupdate/GetFirmwareUpdateStatus'),
  getNodesFirmwareUpdateStatus('nodes/firmwareupdate/GetFirmwareUpdateStatus'),
  getFirmwareUpdateSettings('firmwareupdate/GetFirmwareUpdateSettings'),
  setFirmwareUpdateSettings('firmwareupdate/SetFirmwareUpdateSettings'),
  updateFirmwareNow('nodes/firmwareupdate/UpdateFirmwareNow'),
  nodesUpdateFirmwareNow('nodes/firmwareupdate/UpdateFirmwareNow'),
  // gamingPrioritization
  getGamingPrioritizationSettings(
      'gamingprioritization/GetGamingPrioritizationSettings'),
  setGamingPrioritizationSettings(
      'gamingprioritization/SetGamingPrioritizationSettings'),
  // guestNetwork
  getGuestNetworkClients('guestnetwork/GetGuestNetworkClients'),
  getGuestNetworkSettings('guestnetwork/GetGuestNetworkSettings', upgrades: {
    JNAPService.guestNetwork2: 'guestnetwork/GetGuestNetworkSettings2',
    JNAPService.guestNetwork3: 'guestnetwork/GetGuestRadioSettings',
    JNAPService.guestNetwork4: 'guestnetwork/GetGuestRadioSettings2',
  }),
  getGuestRadioSettings('guestnetwork/GetGuestRadioSettings', upgrades: {
    JNAPService.guestNetwork4: 'guestnetwork/GetGuestRadioSettings2',
  }),
  setGuestNetworkSettings('guestnetwork/SetGuestNetworkSettings', upgrades: {
    JNAPService.guestNetwork2: 'guestnetwork/SetGuestNetworkSettings3',
    JNAPService.guestNetwork3: 'guestnetwork/SetGuestRadioSettings',
    JNAPService.guestNetwork4: 'guestnetwork/SetGuestRadioSettings2',
  }),
  setGuestRadioSettings('guestnetwork/SetGuestRadioSettings', upgrades: {
    JNAPService.guestNetwork4: 'guestnetwork/SetGuestRadioSettings2',
  }),
  // healthCheckManager
  clearHealthCheckHistory('healthcheck/ClearHealthCheckHistory'),
  getHealthCheckResults('healthcheck/GetHealthCheckResults'),
  getCloseHealthCheckServers('healthcheck/GetCloseHealthCheckServers'),
  getHealthCheckStatus('healthcheck/GetHealthCheckStatus'),
  getSupportedHealthCheckModules('healthcheck/GetSupportedHealthCheckModules'),
  runHealthCheck('healthcheck/RunHealthCheck'),
  stopHealthCheck('healthcheck/StopHealthCheck'),
  // locale
  getLocalTime('locale/GetLocalTime'),
  getTimeSettings('locale/GetTimeSettings'),
  getLocale('locale/GetLocale'),
  setLocale('locale/SetLocale'),
  setTimeSettings('locale/SetTimeSettings'),
  // macFilter
  getMACFilterSettings('macfilter/GetMACFilterSettings'),
  setMACFilterSettings('macfilter/SetMACFilterSettings'),
  getSTABSSIDs('macfilter/GetSTABSSIDS'),
  // motionSensing
  getActiveMotionSensingBots('motionsensing/GetActiveMotionSensingBots'),
  getMotionSensingSettings('motionsensing/GetMotionSensingSettings'),
  // networkConnections
  getNetworkConnections('networkconnections/GetNetworkConnections', upgrades: {
    JNAPService.networkConnections2:
        'networkconnections/GetNetworkConnections2',
  }),
  // networkSecurity
  getNetworkSecuritySettings('networksecurity/GetNetworkSecuritySettings',
      upgrades: {
        JNAPService.networkSecurity3:
            'networksecurity/GetNetworkSecuritySettings2',
      }),
  setNetworkSecuritySettings('networksecurity/SetNetworkSecuritySettings',
      upgrades: {
        JNAPService.networkSecurity3:
            'networksecurity/SetNetworkSecuritySettings2',
      }),
  // nodes diagnostics
  getBackhaulInfo('nodes/diagnostics/GetBackhaulInfo', upgrades: {
    JNAPService.nodesDiagnostics6: 'nodes/diagnostics/GetBackhaulInfo2',
  }),
  getNodeNeighborInfo('nodes/diagnostics/GetNodeNeighborInfo'),
  getSlaveBackhaulStatus('nodes/diagnostics/GetSlaveBackhaulStatus'),
  refreshSlaveBackhaulData('nodes/diagnostics/RefreshSlaveBackhaulData'),
  // nodes networkConnections
  getNodesWirelessNetworkConnections(
      'nodes/networkconnections/GetNodesWirelessNetworkConnections',
      upgrades: {
        JNAPService.nodesNetworkConnections2:
            'nodes/networkconnections/GetNodesWirelessNetworkConnections2',
      }),
  refreshNodesWirelessNetworkConnections(
      'nodes/networkconnections/RefreshNodesWirelessNetworkConnections'),
  // nodes optimization
  setTopologyOptimizationSettings(
      'nodes/topologyoptimization/SetTopologyOptimizationSettings',
      upgrades: {
        JNAPService.nodesTopologyOptimization2:
            'nodes/topologyoptimization/SetTopologyOptimizationSettings2',
      }),
  getTopologyOptimizationSettings(
      'nodes/topologyoptimization/GetTopologyOptimizationSettings',
      upgrades: {
        JNAPService.nodesTopologyOptimization2:
            'nodes/topologyoptimization/GetTopologyOptimizationSettings2',
      }),
  // ownedNetwork
  getOwnedNetworkID('ownednetwork/GetOwnedNetworkID'),
  isOwnedNetwork('ownednetwork/IsOwnedNetwork'),
  setNetworkOwner('ownednetwork/SetNetworkOwner'),
  // parentalControl
  getParentalControlSettings('parentalcontrol/GetParentalControlSettings'),
  // powerTable
  getPowerTableSettings('powertable/GetPowerTableSettings'),
  setPowerTableSettings('powertable/SetPowerTableSettings'),
  // product
  getSoftSKUSettings('product/GetSoftSKUSettings'),
  // qos
  getQoSSettings('qos/GetQoSSettings', upgrades: {
    JNAPService.qos2: 'qos/GetQoSSettings2',
  }),
  // router
  getDHCPClientLeases('router/GetDHCPClientLeases'),
  getIPv6Settings('router/GetIPv6Settings', upgrades: {
    JNAPService.router5: 'router/GetIPv6Settings2',
  }),
  getLANSettings('router/GetLANSettings'),
  getMACAddressCloneSettings('router/GetMACAddressCloneSettings'),
  getWANSettings('router/GetWANSettings', upgrades: {
    JNAPService.router3: 'router/GetWANSettings2',
    JNAPService.router7: 'router/GetWANSettings3',
    JNAPService.router8: 'router/GetWANSettings4',
    JNAPService.router10: 'router/GetWANSettings5',
  }),
  getWANStatus('router/GetWANStatus', upgrades: {
    JNAPService.router3: 'router/GetWANStatus2',
    JNAPService.router5: 'router/GetWANStatus3',
  }),
  getRoutingSettings('router/GetRoutingSettings'),
  setIPv6Settings('router/SetIPv6Settings', upgrades: {
    JNAPService.router5: 'router/SetIPv6Settings2',
  }),
  setMACAddressCloneSettings('router/SetMACAddressCloneSettings'),
  setWANSettings('router/SetWANSettings', upgrades: {
    JNAPService.router3: 'router/SetWANSettings2',
    JNAPService.router7: 'router/SetWANSettings3',
    JNAPService.router8: 'router/SetWANSettings4',
    JNAPService.router14: 'router/SetWANSettings5',
  }),
  setLANSettings('router/SetLANSettings'),
  setRoutingSettings('router/SetRoutingSettings'),
  releaseDHCPWANLease('router/ReleaseDHCPWANLease'),
  releaseDHCPIPv6WANLease('router/ReleaseDHCPIPv6WANLease'),
  renewDHCPWANLease('router/RenewDHCPWANLease'),
  renewDHCPIPv6WANLease('router/RenewDHCPIPv6WANLease'),
  getEthernetPortConnections('router/GetEthernetPortConnections'),
  getExpressForwardingSettings(null, upgrades: {
    JNAPService.router6: 'router/GetExpressForwardingSettings',
  }),
  setExpressForwardingSettings(null, upgrades: {
    JNAPService.router6: 'router/SetExpressForwardingSettings',
  }),
  // routerManagement
  getManagementSettings('routermanagement/GetManagementSettings', upgrades: {
    JNAPService.routerManagement2: 'routermanagement/GetManagementSettings2',
  }),
  setManagementSettings('routermanagement/SetManagementSettings', upgrades: {
    JNAPService.routerManagement2: 'routermanagement/SetManagementSettings2',
  }),
  // routerUpnp
  getUPnPSettings('routerupnp/GetUPnPSettings'),
  setUPnPSettings('routerupnp/SetUPnPSettings'),
  // autoipoe
  getAutoIPoECapabilities('autoipoe/GetAutoIPoECapabilities'),
  getAutoIPoESettings('autoipoe/GetAutoIPoESettings'),
  setAutoIPoESettings('autoipoe/SetAutoIPoESettings'),
  applyAutoIPoE('autoipoe/ApplyAutoIPoE'),
  getAutoIPoEStatus('autoipoe/GetAutoIPoEStatus'),
  getAutoIPoELog('autoipoe/GetAutoIPoELog'),
  resetAutoIPoE('autoipoe/ResetAutoIPoE'),
  // selectableWAN
  getPortConnectionStatus('nodes/setup/GetPortConnectionStatus'),
  getWANPort('nodes/setup/GetWANPort'),
  setWANPort('nodes/setup/SetWANPort'),
  // setup
  isAdminPasswordSetByUser('nodes/setup/IsAdminPasswordSetByUser'),
  getAutoConfigurationSettings('nodes/setup/GetAutoConfigurationSettings'),
  setupSetAdminPassword('nodes/setup/SetAdminPassword', upgrades: {
    JNAPService.setup8: 'nodes/setup/SetAdminPassword2',
  }),
  verifyRouterResetCode('nodes/setup/VerifyRouterResetCode'),
  getWANDetectionStatus('nodes/setup/GetWANDetectionStatus'),
  getInternetConnectionStatus('nodes/setup/GetInternetConnectionStatus'),
  getSimpleWiFiSettings('nodes/setup/GetSimpleWiFiSettings'),
  setSimpleWiFiSettings('nodes/setup/SetSimpleWiFiSettings'),
  getMACAddress('nodes/setup/GetMACAddress'),
  getVersionInfo('nodes/setup/GetVersionInfo'),
  startBlinkNodeLed('nodes/setup/StartBlinkingNodeLed'),
  stopBlinkNodeLed('nodes/setup/StopBlinkingNodeLed'),
  setUserAcknowledgedAutoConfiguration(
      'nodes/setup/SetUserAcknowledgedAutoConfiguration'),
  // SmartConnect
  getSmartConnectPin('nodes/smartconnect/GetSmartConnectPIN'),
  getSmartConnectStatus('nodes/smartconnect/GetSmartConnectStatus'),
  // smartMode
  getDeviceMode('nodes/smartmode/GetDeviceMode'),
  getSupportedDeviceMode('nodes/smartmode/GetSupportedDeviceModes'),
  setDeviceMode('nodes/smartmode/SetDeviceMode'),
  // wirelessAP
  getRadioInfo('wirelessap/GetRadioInfo', upgrades: {
    JNAPService.wirelessAP3: 'wirelessap/GetRadioInfo2',
    JNAPService.wirelessAP4: 'wirelessap/GetRadioInfo3',
  }),
  getWPSServerSessionStatus('wirelessap/GetWPSServerSessionStatus'),
  setRadioSettings('wirelessap/SetRadioSettings', upgrades: {
    JNAPService.wirelessAP3: 'wirelessap/SetRadioSettings2',
    JNAPService.wirelessAP4: 'wirelessap/SetRadioSettings3',
  }),
  clientDeauth(null, upgrades: {
    JNAPService.wirelessAP5: 'wirelessap/ClientDeauth',
  }),
  // vlanTagging
  getVLANTaggingSettings('vlantagging/GetVLANTaggingSettings', upgrades: {
    JNAPService.vlanTagging2: 'vlantagging/GetVLANTaggingSettings2',
  }),
  setVLANTaggingSettings('vlantagging/SetVLANTaggingSettings', upgrades: {
    JNAPService.vlanTagging2: 'vlantagging/SetVLANTaggingSettings2',
  }),
  // vpn
  setVPNUser('vpn/SetVPNUser'),
  getVPNUser('vpn/GetVPNUser'),
  setVPNGateway('vpn/SetVPNGateway'),
  getVPNGateway('vpn/GetVPNGateway'),
  setVPNService('vpn/SetVPNService'),
  getVPNService('vpn/GetVPNService'),
  testVPNConnection('vpn/TestVPNConnection'),
  getTunneledUser('vpn/GetTunneledUser'),
  setTunneledUser('vpn/SetTunneledUser'),
  setVPNApply('vpn/SetVPNApply'),
  // wirelessScheduler
  getWirelessSchedulerSettings(
      'wirelessscheduler/GetWirelessSchedulerSettings'),
  //led
  getLedNightModeSetting('routerleds/GetLedNightModeSetting'),
  setLedNightModeSetting('routerleds/SetLedNightModeSetting', upgrades: {
    JNAPService.routerLEDs4: 'routerleds/SetLedNightModeSetting2',
  }),
  startBlinkingNodeLed('nodes/setup/StartBlinkingNodeLed'),
  stopBlinkingNodeLed('nodes/setup/StopBlinkingNodeLed'),
  //iptv
  getIptvSettings('iptv/GetIPTVSettings'),
  setIptvSettings('iptv/SetIPTVSettings'),
  //mlo
  getMLOSettings('wirelessap/GetMLOSettings'),
  setMLOSettings('wirelessap/SetMLOSettings'),
  //dfs
  getDFSSettings('wirelessap/GetDFSSettings'),
  setDFSSettings('wirelessap/SetDFSSettings'),
  //airtime fairness
  getAirtimeFairnessSettings('wirelessap/GetAirtimeFairnessSettings'),
  setAirtimeFairnessSettings('wirelessap/SetAirtimeFairnessSettings'),
  //ui
  getRemoteSetting('ui/GetRemoteSetting'),
  setRemoteSetting('ui/SetRemoteSetting'),
  //channelFinder
  getSelectedChannels('nodes/setup/GetSelectedChannels'),
  startAutoChannelSelection('nodes/setup/StartAutoChannelSelection'),
  // auto master
  getAutoMasterStatus('nodes/setup/GetAutoMasterStatus'),
  ;

  const JNAPAction(this._path, {Map<JNAPService, String> upgrades = const {}})
      : _upgrades = upgrades;

  /// The action's URL at its lowest version, under `http://linksys.com/jnap/`.
  /// Null for an action that only a service defines: it has no URL until the
  /// router reports that service.
  final String? _path;

  /// The URL the action takes, under `http://linksys.com/jnap/`, when the
  /// router reports each of these services. buildBetterActions applies a
  /// router's services from the lowest version up, so the highest one wins.
  final Map<JNAPService, String> _upgrades;

  String get actionValue {
    return _betterActionMap[this]!;
  }
}
