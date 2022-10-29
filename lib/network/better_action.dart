// List all useful JNAP services in the app
enum JNAPService {
  core(value: 'http://linksys.com/jnap/core/Core'),
  core2(value: 'http://linksys.com/jnap/core/Core2'),
  core3(value: 'http://linksys.com/jnap/core/Core3'),
  core4(value: 'http://linksys.com/jnap/core/Core4'),
  core5(value: 'http://linksys.com/jnap/core/Core5'),
  core6(value: 'http://linksys.com/jnap/core/Core6'),
  core7(value: 'http://linksys.com/jnap/core/Core7'),
  ddns(value: 'http://linksys.com/jnap/ddns/DDNS'),
  ddns2(value: 'http://linksys.com/jnap/ddns/DDNS2'),
  ddns3(value: 'http://linksys.com/jnap/ddns/DDNS3'),
  ddns4(value: 'http://linksys.com/jnap/ddns/DDNS4'),
  deviceList(value: 'http://linksys.com/jnap/devicelist/DeviceList'),
  deviceList2(value: 'http://linksys.com/jnap/devicelist/DeviceList2'),
  deviceList4(value: 'http://linksys.com/jnap/devicelist/DeviceList4'),
  deviceList5(value: 'http://linksys.com/jnap/devicelist/DeviceList5'),
  deviceList6(value: 'http://linksys.com/jnap/devicelist/DeviceList6'),
  deviceList7(value: 'http://linksys.com/jnap/devicelist/DeviceList7'),
  firewall(value: 'http://linksys.com/jnap/firewall/Firewall'),
  firewall2(value: 'http://linksys.com/jnap/firewall/Firewall2'),
  guestNetwork(value: 'http://linksys.com/jnap/guestnetwork/GuestNetwork'),
  guestNetwork2(value: 'http://linksys.com/jnap/guestnetwork/GuestNetwork2'),
  guestNetwork3(value: 'http://linksys.com/jnap/guestnetwork/GuestNetwork3'),
  guestNetwork4(value: 'http://linksys.com/jnap/guestnetwork/GuestNetwork4'),
  guestNetwork5(value: 'http://linksys.com/jnap/guestnetwork/GuestNetwork5'),
  healthCheckManager(
      value: 'http://linksys.com/jnap/healthcheck/HealthCheckManager'),
  locale(value: 'http://linksys.com/jnap/locale/Locale'),
  locale2(value: 'http://linksys.com/jnap/locale/Locale2'),
  locale3(value: 'http://linksys.com/jnap/locale/Locale3'),
  macFilter(value: 'http://linksys.com/jnap/macfilter/MACFilter'),
  motionSensing(value: 'http://linksys.com/jnap/motionsensing/MotionSensing'),
  motionSensing2(value: 'http://linksys.com/jnap/motionsensing/MotionSensing2'),
  networkConnections(
      value: 'http://linksys.com/jnap/networkconnections/NetworkConnections'),
  networkConnections2(
      value: 'http://linksys.com/jnap/networkconnections/NetworkConnections2'),
  networkConnections3(
      value: 'http://linksys.com/jnap/networkconnections/NetworkConnections3'),
  networkSecurity(
      value: 'http://linksys.com/jnap/networksecurity/NetworkSecurity'),
  networkSecurity2(
      value: 'http://linksys.com/jnap/networksecurity/NetworkSecurity2'),
  networkSecurity3(
      value: 'http://linksys.com/jnap/networksecurity/NetworkSecurity3'),
  nodesDiagnostics(
      value: 'http://linksys.com/jnap/nodes/diagnostics/Diagnostics'),
  nodesDiagnostics2(
      value: 'http://linksys.com/jnap/nodes/diagnostics/Diagnostics2'),
  nodesDiagnostics3(
      value: 'http://linksys.com/jnap/nodes/diagnostics/Diagnostics3'),
  nodesDiagnostics5(
      value: 'http://linksys.com/jnap/nodes/diagnostics/Diagnostics5'),
  nodesNetworkConnections(
      value:
          'http://linksys.com/jnap/nodes/networkconnections/NodesNetworkConnections'),
  ownedNetwork(value: 'http://linksys.com/jnap/ownednetwork/OwnedNetwork'),
  ownedNetwork2(value: 'http://linksys.com/jnap/ownednetwork/OwnedNetwork2'),
  ownedNetwork3(value: 'http://linksys.com/jnap/ownednetwork/OwnedNetwork3'),
  parentalControl(
      value: 'http://linksys.com/jnap/parentalcontrol/ParentalControl'),
  parentalControl2(
      value: 'http://linksys.com/jnap/parentalcontrol/ParentalControl2'),
  powerTable(value: 'http://linksys.com/jnap/powertable/PowerTable'),
  qos(value: 'http://linksys.com/jnap/qos/QoS'),
  qos2(value: 'http://linksys.com/jnap/qos/QoS2'),
  qos3(value: 'http://linksys.com/jnap/qos/QoS3'),
  router(value: 'http://linksys.com/jnap/router/Router'),
  router3(value: 'http://linksys.com/jnap/router/Router3'),
  router4(value: 'http://linksys.com/jnap/router/Router4'),
  router5(value: 'http://linksys.com/jnap/router/Router5'),
  router6(value: 'http://linksys.com/jnap/router/Router6'),
  router7(value: 'http://linksys.com/jnap/router/Router7'),
  router8(value: 'http://linksys.com/jnap/router/Router8'),
  router9(value: 'http://linksys.com/jnap/router/Router9'),
  router10(value: 'http://linksys.com/jnap/router/Router10'),
  router11(value: 'http://linksys.com/jnap/router/Router11'),
  routerManagement(
      value: 'http://linksys.com/jnap/routermanagement/RouterManagement'),
  routerManagement2(
      value: 'http://linksys.com/jnap/routermanagement/RouterManagement2'),
  routerManagement3(
      value: 'http://linksys.com/jnap/routermanagement/RouterManagement3'),
  setup(value: 'http://linksys.com/jnap/nodes/setup/Setup'),
  setup2(value: 'http://linksys.com/jnap/nodes/setup/Setup2'),
  setup3(value: 'http://linksys.com/jnap/nodes/setup/Setup3'),
  setup4(value: 'http://linksys.com/jnap/nodes/setup/Setup4'),
  setup5(value: 'http://linksys.com/jnap/nodes/setup/Setup5'),
  setup6(value: 'http://linksys.com/jnap/nodes/setup/Setup6'),
  setup7(value: 'http://linksys.com/jnap/nodes/setup/Setup7'),
  setup8(value: 'http://linksys.com/jnap/nodes/setup/Setup8'),
  smartMode(value: 'http://linksys.com/jnap/nodes/smartmode/SmartMode'),
  smartMode2(value: 'http://linksys.com/jnap/nodes/smartmode/SmartMode2'),
  selectableWAN(value: 'http://linksys.com/jnap/nodes/setup/SelectableWAN'),
  wirelessAP(value: 'http://linksys.com/jnap/wirelessap/WirelessAP'),
  wirelessAP2(value: 'http://linksys.com/jnap/wirelessap/WirelessAP2'),
  wirelessAP4(value: 'http://linksys.com/jnap/wirelessap/WirelessAP4'),
  wirelessScheduler(
      value: 'http://linksys.com/jnap/wirelessscheduler/WirelessScheduler'),
  wirelessScheduler2(
      value: 'http://linksys.com/jnap/wirelessscheduler/WirelessScheduler2');

  const JNAPService({required this.value});

  final String value;

  static List<JNAPService> get appSupportedServices => JNAPService.values;
}

// List all useful JNAP actions in the app
// Each item indicates a particular action regardless of its value
enum JNAPAction {
  transaction,
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
  reboot,
  // ddns
  getDDNSStatus,
  // deviceList
  getDevices,
  getLocalDevice,
  setDeviceProperties,
  // firewall
  getPortRangeForwardingRules,
  getPortRangeTriggeringRules,
  getSinglePortForwardingRules,
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
  // nodes networkConnections
  getNodesWirelessNetworkConnections,
  // ownedNetwork
  getOwnedNetworkID,
  isOwnedNetwork,
  setNetworkOwner,
  getCloudIds,
  setCloudIds,
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
  setWANSettings,
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
  // smartMode
  getDeviceMode,
  getSupportedDeviceMode,
  setDeviceMode,
  // wirelessAP
  getRadioInfo,
  getWPSServerSessionStatus,
  setRadioSettings,
  // wirelessScheduler
  getWirelessSchedulerSettings;

  String get actionValue {
    return _betterActionMap[this]!;
  }
}

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
      value: 'http://linksys.com/jnap/core/SetUnsecuredWiFiWarning'
  ),
  isAdminPasswordDefault(
      value: 'http://linksys.com/jnap/core/IsAdminPasswordDefault'),
  reboot(value: 'http://linksys.com/jnap/core/Reboot'),
  getDDNSStatus(value: 'http://linksys.com/jnap/ddns/GetDDNSStatus'),
  getDDNSStatus2(value: 'http://linksys.com/jnap/ddns/GetDDNSStatus2'),
  getDevices(value: 'http://linksys.com/jnap/devicelist/GetDevices'),
  getDevices3(value: 'http://linksys.com/jnap/devicelist/GetDevices3'),
  getLocalDevice(value: 'http://linksys.com/jnap/devicelist/GetLocalDevice'),
  setDeviceProperties(value: 'http://linksys.com/jnap/devicelist/SetDeviceProperties'),
  getPortRangeForwardingRules(
      value: 'http://linksys.com/jnap/firewall/GetPortRangeForwardingRules'),
  getPortRangeTriggeringRules(
      value: 'http://linksys.com/jnap/firewall/GetPortRangeTriggeringRules'),
  getSinglePortForwardingRules(
      value: 'http://linksys.com/jnap/firewall/GetSinglePortForwardingRules'),
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
  getNodeNeighborInfo(
      value: 'http://linksys.com/jnap/nodes/diagnostics/GetNodeNeighborInfo'),
  getSlaveBackhaulStatus(
      value:
          'http://linksys.com/jnap/nodes/diagnostics/GetSlaveBackhaulStatus'),
  refreshSlaveBackhaulData(
      value:
          'http://linksys.com/jnap/nodes/diagnostics/RefreshSlaveBackhaulData'),
  getNodesWirelessNetworkConnections(
      value:
          'http://linksys.com/jnap/nodes/networkconnections/GetNodesWirelessNetworkConnections'),
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
  getWANSettings3(value: 'http://linksys.com/jnap/router/GetWANSettings3'),
  getWANSettings4(value: 'http://linksys.com/jnap/router/GetWANSettings4'),
  getWANSettings5(value: 'http://linksys.com/jnap/router/GetWANSettings5'),
  getWANStatus(value: 'http://linksys.com/jnap/router/GetWANStatus'),
  getWANStatus3(value: 'http://linksys.com/jnap/router/GetWANStatus3'),
  getWANDetectionStatus(
      value: 'http://linksys.com/jnap/nodes/setup/GetWANDetectionStatus'),
  setIPv6Settings(value: 'http://linksys.com/jnap/router/SetIPv6Settings'),
  setIPv6Settings2(value: 'http://linksys.com/jnap/router/SetIPv6Settings2'),
  setWANSettings(value: 'http://linksys.com/jnap/router/SetWANSettings'),
  setWANSettings3(value: 'http://linksys.com/jnap/router/SetWANSettings3'),
  setWANSettings4(value: 'http://linksys.com/jnap/router/SetWANSettings4'),
  renewDHCPWANLease(value: 'http://linksys.com/jnap/router/RenewDHCPWANLease'),
  renewDHCPIPv6Lease(value: 'http://linksys.com/jnap/router/RenewDHCPIPv6WANLease'),
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
  getDeviceMode(value: 'http://linksys.com/jnap/nodes/smartmode/GetDeviceMode'),
  getSupportedDeviceModes(value:'http://linksys.com/jnap/nodes/smartmode/GetSupportedDeviceModes'),
  setDeviceMode(value: 'http://linksys.com/jnap/nodes/smartmode/SetDeviceMode'),
  getRadioInfo(value: 'http://linksys.com/jnap/wirelessap/GetRadioInfo'),
  getRadioInfo3(value: 'http://linksys.com/jnap/wirelessap/GetRadioInfo3'),
  getWPSServerSessionStatus(
      value: 'http://linksys.com/jnap/wirelessap/GetWPSServerSessionStatus'),
  setRadioSettings(
      value: 'http://linksys.com/jnap/wirelessap/SetRadioSettings'),
  setRadioSettings3(
      value: 'http://linksys.com/jnap/wirelessap/SetRadioSettings3'),
  getWirelessSchedulerSettings(
      value:
          'http://linksys.com/jnap/wirelessscheduler/GetWirelessSchedulerSettings'),
  getPortConnectionStatus(
      value: 'http://linksys.com/jnap/wirelessap/SetRadioSettings3'),
  getWANPort(value: 'http://linksys.com/jnap/wirelessap/SetRadioSettings3'),
  setWANPort(value: 'http://linksys.com/jnap/wirelessap/SetRadioSettings3'),
  getInternetConnectionStatus(
      value: 'http://linksys.com/jnap/nodes/setup/GetInternetConnectionStatus'),
  setSimpleWiFiSettings(
    value: 'http://linksys.com/jnap/nodes/setup/SetSimpleWiFiSettings'
  ),
  getCloudIds(value: 'http://linksys.com/jnap/ownednetwork/GetCloudIDs'),
  setCloudIds(value: 'http://linksys.com/jnap/ownednetwork/SetCloudIDs');

  const _JNAPActionValue({required this.value});

  final String value;
}

// The better action map
var _betterActionMap = <JNAPAction, String>{};

// Update actions to better actions by the given service
void _updateBetterActions(JNAPService service) {
  switch (service) {
    case JNAPService.core:
      break;
    case JNAPService.core2:
      _betterActionMap[JNAPAction.checkAdminPassword] =
          _JNAPActionValue.checkAdminPassword2.value;
      break;
    case JNAPService.core3:
      _betterActionMap[JNAPAction.coreSetAdminPassword] =
          _JNAPActionValue.coreSetAdminPassword2.value;
      break;
    case JNAPService.core4:
      break;
    case JNAPService.core5:
      break;
    case JNAPService.core6:
      break;
    case JNAPService.core7:
      _betterActionMap[JNAPAction.checkAdminPassword] =
          _JNAPActionValue.checkAdminPassword3.value;
      _betterActionMap[JNAPAction.coreSetAdminPassword] =
          _JNAPActionValue.coreSetAdminPassword3.value;
      break;
    case JNAPService.ddns:
      break;
    case JNAPService.ddns2:
      break;
    case JNAPService.ddns3:
      _betterActionMap[JNAPAction.getDDNSStatus] =
          _JNAPActionValue.getDDNSStatus2.value;
      break;
    case JNAPService.ddns4:
      break;
    case JNAPService.deviceList:
      break;
    case JNAPService.deviceList2:
      break;
    case JNAPService.deviceList4:
      _betterActionMap[JNAPAction.getDevices] =
          _JNAPActionValue.getDevices3.value;
      break;
    case JNAPService.deviceList5:
      break;
    case JNAPService.deviceList6:
      break;
    case JNAPService.deviceList7:
      break;
    case JNAPService.firewall:
      break;
    case JNAPService.firewall2:
      break;
    case JNAPService.guestNetwork:
      break;
    case JNAPService.guestNetwork2:
      _betterActionMap[JNAPAction.getGuestNetworkSettings] =
          _JNAPActionValue.getGuestNetworkSettings2.value;
      _betterActionMap[JNAPAction.setGuestNetworkSettings] =
          _JNAPActionValue.setGuestNetworkSettings3.value;
      break;
    case JNAPService.guestNetwork3:
      break;
    case JNAPService.guestNetwork4:
      _betterActionMap[JNAPAction.getGuestRadioSettings] =
          _JNAPActionValue.getGuestRadioSettings2.value;
      _betterActionMap[JNAPAction.setGuestRadioSettings] =
          _JNAPActionValue.setGuestRadioSettings2.value;
      break;
    case JNAPService.guestNetwork5:
      break;
    case JNAPService.healthCheckManager:
      break;
    case JNAPService.locale:
      break;
    case JNAPService.locale2:
      break;
    case JNAPService.locale3:
      break;
    case JNAPService.macFilter:
      break;
    case JNAPService.motionSensing:
      break;
    case JNAPService.motionSensing2:
      break;
    case JNAPService.networkConnections:
      break;
    case JNAPService.networkConnections2:
      _betterActionMap[JNAPAction.getNetworkConnections] =
          _JNAPActionValue.getNetworkConnections2.value;
      break;
    case JNAPService.networkConnections3:
      break;
    case JNAPService.networkSecurity:
      break;
    case JNAPService.networkSecurity2:
      break;
    case JNAPService.networkSecurity3:
      _betterActionMap[JNAPAction.getNetworkSecuritySettings] =
          _JNAPActionValue.getNetworkSecuritySettings2.value;
      _betterActionMap[JNAPAction.setNetworkSecuritySettings] =
          _JNAPActionValue.setNetworkSecuritySettings2.value;
      break;
    case JNAPService.nodesDiagnostics:
      break;
    case JNAPService.nodesDiagnostics2:
      break;
    case JNAPService.nodesDiagnostics3:
      break;
    case JNAPService.nodesDiagnostics5:
      break;
    case JNAPService.nodesNetworkConnections:
      break;
    case JNAPService.ownedNetwork:
      break;
    case JNAPService.ownedNetwork2:
      break;
    case JNAPService.ownedNetwork3:
      _betterActionMap[JNAPAction.getCloudIds] = _JNAPActionValue.getCloudIds.value;
      _betterActionMap[JNAPAction.setCloudIds] = _JNAPActionValue.setCloudIds.value;
      break;
    case JNAPService.parentalControl:
      break;
    case JNAPService.parentalControl2:
      break;
    case JNAPService.powerTable:
      break;
    case JNAPService.qos:
      break;
    case JNAPService.qos2:
      _betterActionMap[JNAPAction.getQoSSettings] =
          _JNAPActionValue.getQoSSettings2.value;
      break;
    case JNAPService.qos3:
      break;
    case JNAPService.router:
      break;
    case JNAPService.router3:
      break;
    case JNAPService.router4:
      break;
    case JNAPService.router5:
      _betterActionMap[JNAPAction.getIPv6Settings] =
          _JNAPActionValue.getIPv6Settings2.value;
      _betterActionMap[JNAPAction.getWANStatus] =
          _JNAPActionValue.getWANStatus3.value;
      _betterActionMap[JNAPAction.setIPv6Settings] =
          _JNAPActionValue.setIPv6Settings2.value;
      break;
    case JNAPService.router6:
      break;
    case JNAPService.router7:
      _betterActionMap[JNAPAction.getWANSettings] =
          _JNAPActionValue.getWANSettings3.value;
      _betterActionMap[JNAPAction.setWANSettings] =
          _JNAPActionValue.setWANSettings3.value;
      break;
    case JNAPService.router8:
      _betterActionMap[JNAPAction.getWANSettings] =
          _JNAPActionValue.getWANSettings4.value;
      _betterActionMap[JNAPAction.setWANSettings] =
          _JNAPActionValue.setWANSettings4.value;
      break;
    case JNAPService.router9:
      break;
    case JNAPService.router10:
      _betterActionMap[JNAPAction.getWANSettings] =
          _JNAPActionValue.getWANSettings5.value;
      break;
    case JNAPService.router11:
      break;
    case JNAPService.routerManagement:
      break;
    case JNAPService.routerManagement2:
      _betterActionMap[JNAPAction.getManagementSettings] =
          _JNAPActionValue.getManagementSettings2.value;
      _betterActionMap[JNAPAction.setManagementSettings] =
          _JNAPActionValue.setManagementSettings2.value;
      break;
    case JNAPService.routerManagement3:
      break;
    case JNAPService.setup:
      break;
    case JNAPService.setup2:
      break;
    case JNAPService.setup3:
      break;
    case JNAPService.setup4:
      break;
    case JNAPService.setup5:
      break;
    case JNAPService.setup6:
      break;
    case JNAPService.setup7:
      break;
    case JNAPService.setup8:
      _betterActionMap[JNAPAction.setupSetAdminPassword] =
          _JNAPActionValue.setupSetAdminPassword2.value;
      break;
    case JNAPService.smartMode:
      break;
    case JNAPService.smartMode2:
      break;
    case JNAPService.selectableWAN:
      break;
    case JNAPService.wirelessAP:
      break;
    case JNAPService.wirelessAP2:
      break;
    case JNAPService.wirelessAP4:
      _betterActionMap[JNAPAction.getRadioInfo] =
          _JNAPActionValue.getRadioInfo3.value;
      _betterActionMap[JNAPAction.setRadioSettings] =
          _JNAPActionValue.setRadioSettings3.value;
      break;
    case JNAPService.wirelessScheduler:
      break;
    case JNAPService.wirelessScheduler2:
      break;
  }
}

// Set an initial value (lowest version) to each JNAP action
void initBetterActions() {
  _betterActionMap[JNAPAction.transaction] = _JNAPActionValue.transaction.value;
  _betterActionMap[JNAPAction.checkAdminPassword] =
      _JNAPActionValue.checkAdminPassword.value;
  _betterActionMap[JNAPAction.coreSetAdminPassword] =
      _JNAPActionValue.coreSetAdminPassword.value;
  _betterActionMap[JNAPAction.getAdminPasswordAuthStatus] =
      _JNAPActionValue.getAdminPasswordAuthStatus.value;
  _betterActionMap[JNAPAction.getAdminPasswordHint] =
      _JNAPActionValue.getAdminPasswordHint.value;
  _betterActionMap[JNAPAction.getDataUploadUserConsent] =
      _JNAPActionValue.getDataUploadUserConsent.value;
  _betterActionMap[JNAPAction.getDeviceInfo] =
      _JNAPActionValue.getDeviceInfo.value;
  _betterActionMap[JNAPAction.getUnsecuredWiFiWarning] =
      _JNAPActionValue.getUnsecuredWiFiWarning.value;
  _betterActionMap[JNAPAction.setUnsecuredWiFiWarning] =
      _JNAPActionValue.setUnsecuredWiFiWarning.value;
  _betterActionMap[JNAPAction.isAdminPasswordDefault] =
      _JNAPActionValue.isAdminPasswordDefault.value;
  _betterActionMap[JNAPAction.reboot] = _JNAPActionValue.reboot.value;
  _betterActionMap[JNAPAction.getDDNSStatus] =
      _JNAPActionValue.getDDNSStatus.value;
  _betterActionMap[JNAPAction.getDevices] = _JNAPActionValue.getDevices.value;
  _betterActionMap[JNAPAction.getLocalDevice] = _JNAPActionValue.getLocalDevice.value;
  _betterActionMap[JNAPAction.setDeviceProperties] = _JNAPActionValue.setDeviceProperties.value;
  _betterActionMap[JNAPAction.getPortRangeForwardingRules] =
      _JNAPActionValue.getPortRangeForwardingRules.value;
  _betterActionMap[JNAPAction.getPortRangeTriggeringRules] =
      _JNAPActionValue.getPortRangeTriggeringRules.value;
  _betterActionMap[JNAPAction.getSinglePortForwardingRules] =
      _JNAPActionValue.getSinglePortForwardingRules.value;
  _betterActionMap[JNAPAction.getGuestNetworkClients] =
      _JNAPActionValue.getGuestNetworkClients.value;
  _betterActionMap[JNAPAction.getGuestNetworkSettings] =
      _JNAPActionValue.getGuestNetworkSettings.value;
  _betterActionMap[JNAPAction.getGuestRadioSettings] =
      _JNAPActionValue.getGuestRadioSettings.value;
  _betterActionMap[JNAPAction.setGuestNetworkSettings] =
      _JNAPActionValue.setGuestNetworkSettings.value;
  _betterActionMap[JNAPAction.setGuestRadioSettings] =
      _JNAPActionValue.setGuestRadioSettings.value;
  _betterActionMap[JNAPAction.clearHealthCheckHistory] =
      _JNAPActionValue.clearHealthCheckHistory.value;
  _betterActionMap[JNAPAction.getHealthCheckResults] =
      _JNAPActionValue.getHealthCheckResults.value;
  _betterActionMap[JNAPAction.getHealthCheckStatus] =
      _JNAPActionValue.getHealthCheckStatus.value;
  _betterActionMap[JNAPAction.getSupportedHealthCheckModules] =
      _JNAPActionValue.getSupportedHealthCheckModules.value;
  _betterActionMap[JNAPAction.runHealthCheck] =
      _JNAPActionValue.runHealthCheck.value;
  _betterActionMap[JNAPAction.stopHealthCheck] =
      _JNAPActionValue.stopHealthCheck.value;
  _betterActionMap[JNAPAction.getLocalTime] =
      _JNAPActionValue.getLocalTime.value;
  _betterActionMap[JNAPAction.getTimeSettings] =
      _JNAPActionValue.getTimeSettings.value;
  _betterActionMap[JNAPAction.getLocale] =
      _JNAPActionValue.getLocale.value;
  _betterActionMap[JNAPAction.setLocale] =
      _JNAPActionValue.setLocale.value;
  _betterActionMap[JNAPAction.setTimeSettings] =
      _JNAPActionValue.setTimeSettings.value;
  _betterActionMap[JNAPAction.getMACFilterSettings] =
      _JNAPActionValue.getMACFilterSettings.value;
  _betterActionMap[JNAPAction.getActiveMotionSensingBots] =
      _JNAPActionValue.getActiveMotionSensingBots.value;
  _betterActionMap[JNAPAction.getMotionSensingSettings] =
      _JNAPActionValue.getMotionSensingSettings.value;
  _betterActionMap[JNAPAction.getNetworkConnections] =
      _JNAPActionValue.getNetworkConnections.value;
  _betterActionMap[JNAPAction.getNetworkSecuritySettings] =
      _JNAPActionValue.getNetworkSecuritySettings.value;
  _betterActionMap[JNAPAction.setNetworkSecuritySettings] =
      _JNAPActionValue.setNetworkSecuritySettings.value;
  _betterActionMap[JNAPAction.getBackhaulInfo] =
      _JNAPActionValue.getBackhaulInfo.value;
  _betterActionMap[JNAPAction.getNodeNeighborInfo] =
      _JNAPActionValue.getNodeNeighborInfo.value;
  _betterActionMap[JNAPAction.getSlaveBackhaulStatus] =
      _JNAPActionValue.getSlaveBackhaulStatus.value;
  _betterActionMap[JNAPAction.refreshSlaveBackhaulData] =
      _JNAPActionValue.refreshSlaveBackhaulData.value;
  _betterActionMap[JNAPAction.getNodesWirelessNetworkConnections] =
      _JNAPActionValue.getNodesWirelessNetworkConnections.value;
  _betterActionMap[JNAPAction.getOwnedNetworkID] =
      _JNAPActionValue.getOwnedNetworkID.value;
  _betterActionMap[JNAPAction.isOwnedNetwork] =
      _JNAPActionValue.isOwnedNetwork.value;
  _betterActionMap[JNAPAction.setNetworkOwner] =
      _JNAPActionValue.setNetworkOwner.value;
  _betterActionMap[JNAPAction.getParentalControlSettings] =
      _JNAPActionValue.getParentalControlSettings.value;
  _betterActionMap[JNAPAction.getPowerTableSettings] =
      _JNAPActionValue.getPowerTableSettings.value;
  _betterActionMap[JNAPAction.getQoSSettings] =
      _JNAPActionValue.getQoSSettings.value;
  _betterActionMap[JNAPAction.getDHCPClientLeases] =
      _JNAPActionValue.getDHCPClientLeases.value;
  _betterActionMap[JNAPAction.getIPv6Settings] =
      _JNAPActionValue.getIPv6Settings.value;
  _betterActionMap[JNAPAction.getLANSettings] =
      _JNAPActionValue.getLANSettings.value;
  _betterActionMap[JNAPAction.getMACAddressCloneSettings] =
      _JNAPActionValue.getMACAddressCloneSettings.value;
  _betterActionMap[JNAPAction.getWANSettings] =
      _JNAPActionValue.getWANSettings.value;
  _betterActionMap[JNAPAction.getWANStatus] =
      _JNAPActionValue.getWANStatus.value;
  _betterActionMap[JNAPAction.setIPv6Settings] =
      _JNAPActionValue.setIPv6Settings.value;
  _betterActionMap[JNAPAction.setWANSettings] =
      _JNAPActionValue.setWANSettings.value;
  _betterActionMap[JNAPAction.getManagementSettings] =
      _JNAPActionValue.getManagementSettings.value;
  _betterActionMap[JNAPAction.setManagementSettings] =
      _JNAPActionValue.setManagementSettings.value;
  _betterActionMap[JNAPAction.isAdminPasswordSetByUser] =
      _JNAPActionValue.isAdminPasswordSetByUser.value;
  _betterActionMap[JNAPAction.setupSetAdminPassword] =
      _JNAPActionValue.setupSetAdminPassword.value;
  _betterActionMap[JNAPAction.verifyRouterResetCode] =
      _JNAPActionValue.verifyRouterResetCode.value;
  _betterActionMap[JNAPAction.getDeviceMode] =
      _JNAPActionValue.getDeviceMode.value;
  _betterActionMap[JNAPAction.getSupportedDeviceMode] =
      _JNAPActionValue.getSupportedDeviceModes.value;
  _betterActionMap[JNAPAction.setDeviceMode] =
      _JNAPActionValue.setDeviceMode.value;
  _betterActionMap[JNAPAction.getRadioInfo] =
      _JNAPActionValue.getRadioInfo.value;
  _betterActionMap[JNAPAction.getWPSServerSessionStatus] =
      _JNAPActionValue.getWPSServerSessionStatus.value;
  _betterActionMap[JNAPAction.setRadioSettings] =
      _JNAPActionValue.setRadioSettings.value;
  _betterActionMap[JNAPAction.getWirelessSchedulerSettings] =
      _JNAPActionValue.getWirelessSchedulerSettings.value;
  _betterActionMap[JNAPAction.getWANDetectionStatus] =
      _JNAPActionValue.getWANDetectionStatus.value;
  _betterActionMap[JNAPAction.getPortConnectionStatus] =
      _JNAPActionValue.getPortConnectionStatus.value;
  _betterActionMap[JNAPAction.getWANPort] = _JNAPActionValue.getWANPort.value;
  _betterActionMap[JNAPAction.setWANPort] = _JNAPActionValue.setWANPort.value;
  _betterActionMap[JNAPAction.getInternetConnectionStatus] =
      _JNAPActionValue.getInternetConnectionStatus.value;
  _betterActionMap[JNAPAction.setSimpleWiFiSettings] =
      _JNAPActionValue.setSimpleWiFiSettings.value;
  _betterActionMap[JNAPAction.getCloudIds] = _JNAPActionValue.getCloudIds.value;
  _betterActionMap[JNAPAction.setCloudIds] = _JNAPActionValue.setCloudIds.value;
  _betterActionMap[JNAPAction.renewDHCPWANLease] = _JNAPActionValue.renewDHCPWANLease.value;
  _betterActionMap[JNAPAction.renewDHCPIPv6WANLease] = _JNAPActionValue.renewDHCPIPv6Lease.value;
}

void buildBetterActions(List<String> routerServices) {
  initBetterActions();
  final List<JNAPService> supportedServices = routerServices
      .where((routerService) => JNAPService.appSupportedServices
          .any((supportedService) => routerService == supportedService.value))
      .map((service) => JNAPService.appSupportedServices
          .firstWhere((supportedService) => supportedService.value == service))
      .toList();

  for (final service in supportedServices) {
    _updateBetterActions(service);
  }
}
