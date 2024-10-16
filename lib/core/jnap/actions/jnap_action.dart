part of 'better_action.dart';

// List all useful JNAP actions in the app
// Each item indicates a particular action regardless of its value
enum JNAPAction {
  transaction,
  // auto onboarding
  startBlueboothAutoOnboarding,
  getBluetoothAutoOnboardingStatus,
  getBluetoothAutoOnboardingSettings,
  setBluetoothAutoOnboardingSettings,
  setWiredAutoOnboardingSettings,
  getWiredAutoOnboardingSettings,
  // bluetooth
  btGetScanUnconfiguredResult,
  btRequestScanUnconfigured,
  // core
  checkAdminPassword,
  pnpCheckAdminPassword,
  coreSetAdminPassword,
  pnpSetAdminPassword,
  getAdminPasswordAuthStatus,
  getAdminPasswordHint,
  getDataUploadUserConsent,
  getDeviceInfo,
  getUnsecuredWiFiWarning,
  setUnsecuredWiFiWarning,
  isAdminPasswordDefault,
  isServiceSupported,
  reboot,
  reboot2,
  factoryReset,
  factoryReset2,
  // ddns
  getDDNSSettings,
  getDDNSStatus,
  getSupportedDDNSProviders,
  setDDNSSetting,
  // deviceList
  getDevices,
  getLocalDevice,
  setDeviceProperties,
  deleteDevice,
  // diagnostics
  execSysCommand,
  getPingStatus,
  getSysInfoData,
  getSystemStats,
  getTracerouteStatus,
  restorePreviousFirmware,
  sendSysinfoEmail,
  startPing,
  startTracroute,
  stopPing,
  stopTracroute,
  // firewall
  getPortRangeForwardingRules,
  getPortRangeTriggeringRules,
  getSinglePortForwardingRules,
  setPortRangeForwardingRules,
  setPortRangeTriggeringRules,
  setSinglePortForwardingRules,
  getIPv6FirewallRules,
  setIPv6FirewallRules,
  getFirewallSettings,
  setFirewallSettings,
  getDMZSettings,
  setDMZSettings,
  getALGSettings,
  setALGSettings,
  // firmwareUpdate
  getFirmwareUpdateStatus,
  getNodesFirmwareUpdateStatus,
  getFirmwareUpdateSettings,
  setFirmwareUpdateSettings,
  updateFirmwareNow,
  nodesUpdateFirmwareNow,
  // gamingPrioritization
  getGamingPrioritizationSettings,
  setGamingPrioritizationSettings,
  // guestNetwork
  getGuestNetworkClients,
  getGuestNetworkSettings,
  getGuestRadioSettings,
  setGuestNetworkSettings,
  setGuestRadioSettings,
  // healthCheckManager
  clearHealthCheckHistory,
  getHealthCheckResults,
  getHealthCheckStatus,
  getSupportedHealthCheckModules,
  runHealthCheck,
  stopHealthCheck,
  // locale
  getLocalTime,
  getTimeSettings,
  getLocale,
  setLocale,
  setTimeSettings,
  // macFilter
  getMACFilterSettings,
  setMACFilterSettings,
  getSTABSSIDs,
  // motionSensing
  getActiveMotionSensingBots,
  getMotionSensingSettings,
  // networkConnections
  getNetworkConnections,
  // networkSecurity
  getNetworkSecuritySettings,
  setNetworkSecuritySettings,
  // nodes diagnostics
  getBackhaulInfo,
  getNodeNeighborInfo,
  getSlaveBackhaulStatus,
  refreshSlaveBackhaulData,
  // nodes networkConnections
  getNodesWirelessNetworkConnections,
  // nodes optimization
  setTopologyOptimizationSettings,
  getTopologyOptimizationSettings,
  // ownedNetwork
  getOwnedNetworkID,
  isOwnedNetwork,
  setNetworkOwner,
  // parentalControl
  getParentalControlSettings,
  // powerTable
  getPowerTableSettings,
  setPowerTableSettings,
  // product
  getSoftSKUSettings,
  // qos
  getQoSSettings,
  // router
  getDHCPClientLeases,
  getIPv6Settings,
  getLANSettings,
  getMACAddressCloneSettings,
  getWANSettings,
  getWANStatus,
  getRoutingSettings,
  setIPv6Settings,
  setMACAddressCloneSettings,
  setWANSettings,
  setLANSettings,
  setRoutingSettings,
  releaseDHCPWANLease,
  releaseDHCPIPv6WANLease,
  renewDHCPWANLease,
  renewDHCPIPv6WANLease,
  getEthernetPortConnections,
  getExpressForwardingSettings,
  setExpressForwardingSettings, 
  getWANExternal,
  // routerManagement
  getManagementSettings,
  setManagementSettings,
  // routerUpnp
  getUPnPSettings,
  setUPnPSettings,
  // selectableWAN
  getPortConnectionStatus,
  getWANPort,
  setWANPort,
  // setup
  isAdminPasswordSetByUser,
  getAutoConfigurationSettings,
  setupSetAdminPassword,
  verifyRouterResetCode,
  getWANDetectionStatus,
  getInternetConnectionStatus,
  getSimpleWiFiSettings,
  setSimpleWiFiSettings,
  getMACAddress,
  getVersionInfo,
  startBlinkNodeLed,
  stopBlinkNodeLed,
  setUserAcknowledgedAutoConfiguration,
  // SmartConnect
  getSmartConnectPin,
  getSmartConnectStatus,
  // smartMode
  getDeviceMode,
  getSupportedDeviceMode,
  setDeviceMode,
  // wirelessAP
  getRadioInfo,
  getWPSServerSessionStatus,
  setRadioSettings,
  clientDeauth,
  // vlanTagging
  getVLANTaggingSettings,
  setVLANTaggingSettings,
  // vpn
  setVPNUser,
  getVPNUser,
  setVPNGateway,
  getVPNGateway,
  setVPNService,
  getVPNService,
  testVPNConnection,
  getTunneledUser,
  setTunneledUser,
  setVPNApply,
  // wirelessScheduler
  getWirelessSchedulerSettings,
  //led
  getLedNightModeSetting,
  setLedNightModeSetting,
  startBlinkingNodeLed,
  stopBlinkingNodeLed,
  //iptv
  getIptvSettings,
  setIptvSettings,
  //mlo
  getMLOSettings,
  setMLOSettings,
  //dfs
  getDFSSettings,
  setDFSSettings,
  //airtime fairness
  getAirtimeFairnessSettings,
  setAirtimeFairnessSettings,
  //ui
  getRemoteSetting,
  setRemoteSetting,
  //channelFinder
  getSelectedChannels,
  startAutoChannelSelection,
  ;
  
  String get actionValue {
    return _betterActionMap[this]!;
  }
}
