part 'jnap_action.dart';

part 'jnap_action_value.dart';

part 'jnap_service.dart';

// The better action map
var _betterActionMap = <JNAPAction, String>{};

// Update actions to better actions by the given service
void _updateBetterActions(JNAPService service) {
  switch (service) {
    case JNAPService.autoOnboarding:
      break;
    case JNAPService.bluetooth:
      break;
    case JNAPService.bluetooth2:
      break;
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
    case JNAPService.firmwareUpdate:
      break;
    case JNAPService.firmwareUpdate2:
      break;
    case JNAPService.gamingPrioritization:
      _betterActionMap[JNAPAction.getGamingPrioritizationSettings] =
          _JNAPActionValue.getGamingPrioritizationSettings.value;
      _betterActionMap[JNAPAction.setGamingPrioritizationSettings] =
          _JNAPActionValue.setGamingPrioritizationSettings.value;
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
      _betterActionMap[JNAPAction.getGuestNetworkSettings] =
          _JNAPActionValue.getGuestRadioSettings.value;
      _betterActionMap[JNAPAction.setGuestNetworkSettings] =
          _JNAPActionValue.setGuestRadioSettings.value;
      break;
    case JNAPService.guestNetwork4:
      _betterActionMap[JNAPAction.getGuestNetworkSettings] =
          _JNAPActionValue.getGuestRadioSettings2.value;
      _betterActionMap[JNAPAction.setGuestNetworkSettings] =
          _JNAPActionValue.setGuestRadioSettings2.value;
      _betterActionMap[JNAPAction.getGuestRadioSettings] =
          _JNAPActionValue.getGuestRadioSettings2.value;
      _betterActionMap[JNAPAction.setGuestRadioSettings] =
          _JNAPActionValue.setGuestRadioSettings2.value;
      break;
    case JNAPService.guestNetwork5:
      break;
    case JNAPService.healthCheckManager:
      _betterActionMap[JNAPAction.getNodesHealthCheckStatus] =
          _JNAPActionValue.getHealthCheckStatus.value;
      _betterActionMap[JNAPAction.getNodesHealthCheckResults] =
          _JNAPActionValue.getHealthCheckResults.value;
      _betterActionMap[JNAPAction.runNodesHealthCheck] =
          _JNAPActionValue.runHealthCheck.value;
      _betterActionMap[JNAPAction.stopNodesHealCheck] =
          _JNAPActionValue.stopHealthCheck.value;
      _betterActionMap[JNAPAction.getNodesSupportedHealthCheckModules] =
          _JNAPActionValue.getSupportedHealthCheckModules.value;
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
      _betterActionMap[JNAPAction.getWANSettings] =
          _JNAPActionValue.getWANSettings2.value;
      _betterActionMap[JNAPAction.setWANSettings] =
          _JNAPActionValue.setWANSettings2.value;
      _betterActionMap[JNAPAction.getWANStatus] =
          _JNAPActionValue.getWANStatus2.value;
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
    case JNAPService.storage:
      break;
    case JNAPService.storage2:
      _betterActionMap[JNAPAction.getMountedPartitions] =
          _JNAPActionValue.getPartitions.value;
      break;
    case JNAPService.vlanTagging:
      break;
    case JNAPService.vlanTagging2:
      _betterActionMap[JNAPAction.getVLANTaggingSettings] =
          _JNAPActionValue.getVLANTaggingSettings2.value;
      _betterActionMap[JNAPAction.setVLANTaggingSettings] =
          _JNAPActionValue.setVLANTaggingSettings2.value;
      break;
    case JNAPService.wirelessAP:
      break;
    case JNAPService.wirelessAP2:
      break;
    case JNAPService.wirelessAP3:
      _betterActionMap[JNAPAction.getRadioInfo] =
          _JNAPActionValue.getRadioInfo2.value;
      _betterActionMap[JNAPAction.setRadioSettings] =
          _JNAPActionValue.setRadioSettings2.value;
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
    case JNAPService.nodeHealthCheck:
      // TODO: Handle this case.
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
  _betterActionMap[JNAPAction.isServiceSupported] =
      _JNAPActionValue.isServiceSupported.value;
  _betterActionMap[JNAPAction.reboot] = _JNAPActionValue.reboot.value;
  _betterActionMap[JNAPAction.getDDNSStatus] =
      _JNAPActionValue.getDDNSStatus.value;
  _betterActionMap[JNAPAction.getDevices] = _JNAPActionValue.getDevices.value;
  _betterActionMap[JNAPAction.getLocalDevice] =
      _JNAPActionValue.getLocalDevice.value;
  _betterActionMap[JNAPAction.setDeviceProperties] =
      _JNAPActionValue.setDeviceProperties.value;
  _betterActionMap[JNAPAction.deleteDevice] =
      _JNAPActionValue.deleteDevice.value;
  _betterActionMap[JNAPAction.getPortRangeForwardingRules] =
      _JNAPActionValue.getPortRangeForwardingRules.value;
  _betterActionMap[JNAPAction.getPortRangeTriggeringRules] =
      _JNAPActionValue.getPortRangeTriggeringRules.value;
  _betterActionMap[JNAPAction.getSinglePortForwardingRules] =
      _JNAPActionValue.getSinglePortForwardingRules.value;
  _betterActionMap[JNAPAction.setPortRangeForwardingRules] =
      _JNAPActionValue.setPortRangeForwardingRules.value;
  _betterActionMap[JNAPAction.setPortRangeTriggeringRules] =
      _JNAPActionValue.setPortRangeTriggeringRules.value;
  _betterActionMap[JNAPAction.setSinglePortForwardingRules] =
      _JNAPActionValue.setSinglePortForwardingRules.value;
  _betterActionMap[JNAPAction.getFirmwareUpdateStatus] =
      _JNAPActionValue.getFirmwareUpdateStatus.value;
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
  _betterActionMap[JNAPAction.getLocale] = _JNAPActionValue.getLocale.value;
  _betterActionMap[JNAPAction.setLocale] = _JNAPActionValue.setLocale.value;
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
  _betterActionMap[JNAPAction.setMACAddressCloneSettings] =
      _JNAPActionValue.setMACAddressCloneSettings.value;
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
  _betterActionMap[JNAPAction.getVersionInfo] =
      _JNAPActionValue.getVersionInfo.value;
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
  _betterActionMap[JNAPAction.getMACAddress] =
      _JNAPActionValue.getMACAddress.value;
  _betterActionMap[JNAPAction.renewDHCPWANLease] =
      _JNAPActionValue.renewDHCPWANLease.value;
  _betterActionMap[JNAPAction.renewDHCPIPv6WANLease] =
      _JNAPActionValue.renewDHCPIPv6Lease.value;
  _betterActionMap[JNAPAction.btGetScanUnconfiguredResult] =
      _JNAPActionValue.btGetScanUnconfiguredResult2.value;
  _betterActionMap[JNAPAction.btRequestScanUnconfigured] =
      _JNAPActionValue.btRequestScanUnconfigured2.value;
  _betterActionMap[JNAPAction.getBluetoothAutoOnboardingSettings] =
      _JNAPActionValue.getBluetoothAutoOnboardingSettings.value;
  _betterActionMap[JNAPAction.getBlueboothAutoOnboardingStatus] =
      _JNAPActionValue.getBluetoothAutoOnboardingStatus.value;
  _betterActionMap[JNAPAction.startBlueboothAutoOnboarding] =
      _JNAPActionValue.startBluetoothAutoOnboarding.value;
  _betterActionMap[JNAPAction.getVLANTaggingSettings] =
      _JNAPActionValue.getVLANTaggingSettings.value;
  _betterActionMap[JNAPAction.setVLANTaggingSettings] =
      _JNAPActionValue.setVLANTaggingSettings.value;
  _betterActionMap[JNAPAction.startBlinkNodeLed] =
      _JNAPActionValue.startBlinkingNodeLed.value;
  _betterActionMap[JNAPAction.stopBlinkNodeLed] =
      _JNAPActionValue.stopBlinkingNodeLed.value;
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
