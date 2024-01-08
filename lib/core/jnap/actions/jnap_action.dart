part of 'better_action.dart';

// List all useful JNAP actions in the app
// Each item indicates a particular action regardless of its value
enum JNAPAction {
  transaction,
  // auto onboarding
  startBlueboothAutoOnboarding,
  getBlueboothAutoOnboardingStatus,
  getBluetoothAutoOnboardingSettings,
  // bluetooth
  btGetScanUnconfiguredResult,
  btRequestScanUnconfigured,
  // core
  checkAdminPassword,
  coreSetAdminPassword,
  getAdminPasswordAuthStatus,
  getAdminPasswordHint,
  getDataUploadUserConsent,
  getDeviceInfo,
  getUnsecuredWiFiWarning,
  setUnsecuredWiFiWarning,
  isAdminPasswordDefault,
  isServiceSupported,
  reboot,
  // ddns
  getDDNSStatus,
  // deviceList
  getDevices,
  getLocalDevice,
  setDeviceProperties,
  deleteDevice,
  // firewall
  getPortRangeForwardingRules,
  getPortRangeTriggeringRules,
  getSinglePortForwardingRules,
  setPortRangeForwardingRules,
  setPortRangeTriggeringRules,
  setSinglePortForwardingRules,
  // firmwareUpdate
  getFirmwareUpdateStatus,
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
  // nodes healthCheckManager,
  getNodesHealthCheckStatus,
  getNodesHealthCheckResults,
  runNodesHealthCheck,
  stopNodesHealCheck,
  getNodesSupportedHealthCheckModules,
  // nodes networkConnections
  getNodesWirelessNetworkConnections,
  // ownedNetwork
  getOwnedNetworkID,
  isOwnedNetwork,
  setNetworkOwner,
  // parentalControl
  getParentalControlSettings,
  // powerTable
  getPowerTableSettings,
  // qos
  getQoSSettings,
  // router
  getDHCPClientLeases,
  getIPv6Settings,
  getLANSettings,
  getMACAddressCloneSettings,
  getWANSettings,
  getWANStatus,
  setIPv6Settings,
  setMACAddressCloneSettings,
  setWANSettings,
  setLANSettings,
  renewDHCPWANLease,
  renewDHCPIPv6WANLease,
  // routerManagement
  getManagementSettings,
  setManagementSettings,
  // selectableWAN
  getPortConnectionStatus,
  getWANPort,
  setWANPort,
  // setup
  isAdminPasswordSetByUser,
  setupSetAdminPassword,
  verifyRouterResetCode,
  getWANDetectionStatus,
  getInternetConnectionStatus,
  setSimpleWiFiSettings,
  getMACAddress,
  getVersionInfo,
  startBlinkNodeLed,
  stopBlinkNodeLed,
  // smartMode
  getDeviceMode,
  getSupportedDeviceMode,
  setDeviceMode,
  // storage
  getMountedPartitions,
  getPartitions,
  // wirelessAP
  getRadioInfo,
  getWPSServerSessionStatus,
  setRadioSettings,
  // vlanTagging
  getVLANTaggingSettings,
  setVLANTaggingSettings,
  // wirelessScheduler
  getWirelessSchedulerSettings,
  //led
  getLedNightModeSetting,
  setLedNightModeSetting,
  startBlinkingNodeLed,
  stopBlinkingNodeLed;

  String get actionValue {
    return _betterActionMap[this]!;
  }
}
