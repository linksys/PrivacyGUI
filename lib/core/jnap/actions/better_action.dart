import 'package:collection/collection.dart';

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
    case JNAPService.autoOnboarding2:
      _betterActionMap[JNAPAction.getBluetoothAutoOnboardingStatus] =
          _JNAPActionValue.getBluetoothAutoOnboardingStatus2.value;
    case JNAPService.autoOnboarding3:
      _betterActionMap[JNAPAction.startBlueboothAutoOnboarding] =
          _JNAPActionValue.startBluetoothAutoOnboarding2.value;
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
    case JNAPService.core8:
      break;
    case JNAPService.core9:
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
      break;
    case JNAPService.locale:
      break;
    case JNAPService.locale2:
      break;
    case JNAPService.locale3:
      break;
    case JNAPService.macFilter:
      break;
    case JNAPService.macFilter2:
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
    case JNAPService.nodesDiagnostics6:
      _betterActionMap[JNAPAction.getBackhaulInfo] =
          _JNAPActionValue.getBackhaulInfo2.value;
      break;
    case JNAPService.nodesNetworkConnections:
      _betterActionMap[JNAPAction.getNodesWirelessNetworkConnections] =
          _JNAPActionValue.getNodesWirelessNetworkConnections.value;
      break;
    case JNAPService.nodesNetworkConnections2:
      _betterActionMap[JNAPAction.getNodesWirelessNetworkConnections] =
          _JNAPActionValue.getNodesWirelessNetworkConnections2.value;
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
    case JNAPService.product:
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
      _betterActionMap[JNAPAction.getExpressForwardingSettings] =
          _JNAPActionValue.getExpressForwardingSettings.value;
      _betterActionMap[JNAPAction.setExpressForwardingSettings] =
          _JNAPActionValue.setExpressForwardingSettings.value;

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
    case JNAPService.router12:
      break;
    case JNAPService.router13:
      _betterActionMap[JNAPAction.getWANExternal] =
          _JNAPActionValue.getWANExternal.value;
      break;
    case JNAPService.router14:
      _betterActionMap[JNAPAction.setWANSettings] =
          _JNAPActionValue.setWANSettings5.value;
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
    case JNAPService.routerUPnP:
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
    case JNAPService.setup9:
      break;
    case JNAPService.setup10:
      break;
    case JNAPService.setup11:
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
    case JNAPService.wirelessAP5:
      _betterActionMap[JNAPAction.clientDeauth] =
          _JNAPActionValue.clientDeuth.value;
      break;
    case JNAPService.wirelessScheduler:
      break;
    case JNAPService.wirelessScheduler2:
      break;
    case JNAPService.routerLEDs:
      break;
    case JNAPService.routerLEDs2:
      break;
    case JNAPService.routerLEDs3:
      break;
    case JNAPService.routerLEDs4:
      _betterActionMap[JNAPAction.setLedNightModeSetting] =
          _JNAPActionValue.setLedNightModeSetting2.value;
      break;
    case JNAPService.nodesFirmwareUpdate:
      break;
    case JNAPService.nodesTopologyOptimization:
      _betterActionMap[JNAPAction.getTopologyOptimizationSettings] =
          _JNAPActionValue.getTopologyOptimizationSettings.value;
      _betterActionMap[JNAPAction.setTopologyOptimizationSettings] =
          _JNAPActionValue.setTopologyOptimizationSettings.value;
      break;
    case JNAPService.nodesTopologyOptimization2:
      _betterActionMap[JNAPAction.getTopologyOptimizationSettings] =
          _JNAPActionValue.getTopologyOptimizationSettings2.value;
      _betterActionMap[JNAPAction.setTopologyOptimizationSettings] =
          _JNAPActionValue.setTopologyOptimizationSettings2.value;
      break;
    case JNAPService.iptv:
      break;
    case JNAPService.mlo:
      break;
    case JNAPService.dfs:
      break;
    case JNAPService.airtimeFairness:
      break;
    case JNAPService.diagnostics:
      break;
    case JNAPService.diagnostics2:
      break;
    case JNAPService.diagnostics3:
      break;
    case JNAPService.diagnostics7:
      break;
    case JNAPService.diagnostics8:
      break;
    case JNAPService.diagnostics9:
      break;
    case JNAPService.diagnostics10:
      _betterActionMap[JNAPAction.getSystemStats] =
          _JNAPActionValue.getSystemStats2.value;
      break;
    case JNAPService.settings:
      break;
    case JNAPService.settings2:
      // _betterActionMap[JNAPAction.getCloudServerStatus] =
      //     _JNAPActionValue.getCloudServerStatus.value;
      break;
    case JNAPService.settings3:
      break;
    case JNAPService.vpn:
      break;
  }
}

// Set an initial value (lowest version) to each JNAP action
void initBetterActions() {
  _betterActionMap[JNAPAction.transaction] = _JNAPActionValue.transaction.value;
  _betterActionMap[JNAPAction.checkAdminPassword] =
      _JNAPActionValue.checkAdminPassword.value;
  _betterActionMap[JNAPAction.pnpCheckAdminPassword] =
      _JNAPActionValue.checkAdminPassword2.value;
  _betterActionMap[JNAPAction.pnpSetAdminPassword] =
      _JNAPActionValue.coreSetAdminPassword2.value;
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
  _betterActionMap[JNAPAction.reboot2] = _JNAPActionValue.reboot2.value;
  _betterActionMap[JNAPAction.factoryReset] =
      _JNAPActionValue.factoryReset.value;
  _betterActionMap[JNAPAction.factoryReset2] =
      _JNAPActionValue.factoryReset2.value;
  _betterActionMap[JNAPAction.getDDNSSettings] =
      _JNAPActionValue.getDDNSSettings.value;
  _betterActionMap[JNAPAction.getDDNSStatus] =
      _JNAPActionValue.getDDNSStatus.value;
  _betterActionMap[JNAPAction.getSupportedDDNSProviders] =
      _JNAPActionValue.getSupportedDDNSProviders.value;
  _betterActionMap[JNAPAction.setDDNSSetting] =
      _JNAPActionValue.setDDNSSetting.value;
  _betterActionMap[JNAPAction.getDevices] = _JNAPActionValue.getDevices.value;
  _betterActionMap[JNAPAction.getLocalDevice] =
      _JNAPActionValue.getLocalDevice.value;
  _betterActionMap[JNAPAction.setDeviceProperties] =
      _JNAPActionValue.setDeviceProperties.value;
  _betterActionMap[JNAPAction.deleteDevice] =
      _JNAPActionValue.deleteDevice.value;
  _betterActionMap[JNAPAction.execSysCommand] =
      _JNAPActionValue.execSysCommand.value;
  _betterActionMap[JNAPAction.getPingStatus] =
      _JNAPActionValue.getPingStatus.value;
  _betterActionMap[JNAPAction.getSysInfoData] =
      _JNAPActionValue.getSysInfoData.value;
  _betterActionMap[JNAPAction.getSystemStats] =
      _JNAPActionValue.getSystemStats.value;
  _betterActionMap[JNAPAction.getTracerouteStatus] =
      _JNAPActionValue.getTracerouteStatus.value;
  _betterActionMap[JNAPAction.restorePreviousFirmware] =
      _JNAPActionValue.restorePreviousFirmware.value;
  _betterActionMap[JNAPAction.sendSysinfoEmail] =
      _JNAPActionValue.sendSysinfoEmail.value;
  _betterActionMap[JNAPAction.startPing] = _JNAPActionValue.startPing.value;
  _betterActionMap[JNAPAction.startTracroute] =
      _JNAPActionValue.startTracroute.value;
  _betterActionMap[JNAPAction.stopPing] = _JNAPActionValue.stopPing.value;
  _betterActionMap[JNAPAction.stopTracroute] =
      _JNAPActionValue.stopTracroute.value;
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
  _betterActionMap[JNAPAction.getIPv6FirewallRules] =
      _JNAPActionValue.getIPv6FirewallRules.value;
  _betterActionMap[JNAPAction.setIPv6FirewallRules] =
      _JNAPActionValue.setIPv6FirewallRules.value;
  _betterActionMap[JNAPAction.getFirewallSettings] =
      _JNAPActionValue.getFirewallSettings.value;
  _betterActionMap[JNAPAction.setFirewallSettings] =
      _JNAPActionValue.setFirewallSettings.value;
  _betterActionMap[JNAPAction.getDMZSettings] =
      _JNAPActionValue.getDMZSettings.value;
  _betterActionMap[JNAPAction.setDMZSettings] =
      _JNAPActionValue.setDMZSettings.value;
  _betterActionMap[JNAPAction.getALGSettings] =
      _JNAPActionValue.getALGSettings.value;
  _betterActionMap[JNAPAction.setALGSettings] =
      _JNAPActionValue.setALGSettings.value;
  _betterActionMap[JNAPAction.getFirmwareUpdateStatus] =
      _JNAPActionValue.getFirmwareUpdateStatus.value;
  _betterActionMap[JNAPAction.getNodesFirmwareUpdateStatus] =
      _JNAPActionValue.getNodesFirmwareUpdateStatus.value;
  _betterActionMap[JNAPAction.getFirmwareUpdateSettings] =
      _JNAPActionValue.getFirmwareUpdateSettings.value;
  _betterActionMap[JNAPAction.setFirmwareUpdateSettings] =
      _JNAPActionValue.setFirmwareUpdateSettings.value;
  _betterActionMap[JNAPAction.updateFirmwareNow] =
      _JNAPActionValue.updateFirmwareNow.value;
  _betterActionMap[JNAPAction.nodesUpdateFirmwareNow] =
      _JNAPActionValue.nodesUpdateFirmwareNow.value;
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
  _betterActionMap[JNAPAction.setMACFilterSettings] =
      _JNAPActionValue.setMACFilterSettings.value;
  _betterActionMap[JNAPAction.getSTABSSIDs] =
      _JNAPActionValue.getSTABSSIDs.value;
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
  _betterActionMap[JNAPAction.setPowerTableSettings] =
      _JNAPActionValue.setPowerTableSettings.value;
  _betterActionMap[JNAPAction.getSoftSKUSettings] =
      _JNAPActionValue.getSoftSKUSettings.value;
  _betterActionMap[JNAPAction.getQoSSettings] =
      _JNAPActionValue.getQoSSettings.value;
  _betterActionMap[JNAPAction.getDHCPClientLeases] =
      _JNAPActionValue.getDHCPClientLeases.value;
  _betterActionMap[JNAPAction.getIPv6Settings] =
      _JNAPActionValue.getIPv6Settings.value;
  _betterActionMap[JNAPAction.getLANSettings] =
      _JNAPActionValue.getLANSettings.value;
  _betterActionMap[JNAPAction.getRoutingSettings] =
      _JNAPActionValue.getRoutingSettings.value;
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
  _betterActionMap[JNAPAction.setLANSettings] =
      _JNAPActionValue.setLANSettings.value;
  _betterActionMap[JNAPAction.setRoutingSettings] =
      _JNAPActionValue.setRoutingSettings.value;
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
  _betterActionMap[JNAPAction.getSimpleWiFiSettings] =
      _JNAPActionValue.getSimpleWiFiSettings.value;
  _betterActionMap[JNAPAction.setSimpleWiFiSettings] =
      _JNAPActionValue.setSimpleWiFiSettings.value;
  _betterActionMap[JNAPAction.getMACAddress] =
      _JNAPActionValue.getMACAddress.value;
  _betterActionMap[JNAPAction.releaseDHCPWANLease] =
      _JNAPActionValue.releaseDHCPWANLease.value;
  _betterActionMap[JNAPAction.releaseDHCPIPv6WANLease] =
      _JNAPActionValue.releaseDHCPIPv6WANLease.value;
  _betterActionMap[JNAPAction.renewDHCPWANLease] =
      _JNAPActionValue.renewDHCPWANLease.value;
  _betterActionMap[JNAPAction.renewDHCPIPv6WANLease] =
      _JNAPActionValue.renewDHCPIPv6WANLease.value;
  _betterActionMap[JNAPAction.getEthernetPortConnections] =
      _JNAPActionValue.getEthernetPortConnections.value;
  _betterActionMap[JNAPAction.btGetScanUnconfiguredResult] =
      _JNAPActionValue.btGetScanUnconfiguredResult2.value;
  _betterActionMap[JNAPAction.btRequestScanUnconfigured] =
      _JNAPActionValue.btRequestScanUnconfigured2.value;
  _betterActionMap[JNAPAction.getBluetoothAutoOnboardingSettings] =
      _JNAPActionValue.getBluetoothAutoOnboardingSettings.value;
  _betterActionMap[JNAPAction.setBluetoothAutoOnboardingSettings] =
      _JNAPActionValue.setBluetoothAutoOnboardingSettings.value;
  _betterActionMap[JNAPAction.getBluetoothAutoOnboardingStatus] =
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
  _betterActionMap[JNAPAction.getLedNightModeSetting] =
      _JNAPActionValue.getLedNightModeSetting.value;
  _betterActionMap[JNAPAction.setLedNightModeSetting] =
      _JNAPActionValue.setLedNightModeSetting.value;
  _betterActionMap[JNAPAction.startBlinkingNodeLed] =
      _JNAPActionValue.startBlinkingNodeLed.value;
  _betterActionMap[JNAPAction.stopBlinkingNodeLed] =
      _JNAPActionValue.stopBlinkingNodeLed.value;
  _betterActionMap[JNAPAction.getTopologyOptimizationSettings] =
      _JNAPActionValue.getTopologyOptimizationSettings.value;
  _betterActionMap[JNAPAction.setTopologyOptimizationSettings] =
      _JNAPActionValue.setTopologyOptimizationSettings.value;
  _betterActionMap[JNAPAction.getIptvSettings] =
      _JNAPActionValue.getIptvSettings.value;
  _betterActionMap[JNAPAction.setIptvSettings] =
      _JNAPActionValue.setIptvSettings.value;
  _betterActionMap[JNAPAction.getMLOSettings] =
      _JNAPActionValue.getMLOSettings.value;
  _betterActionMap[JNAPAction.setMLOSettings] =
      _JNAPActionValue.setMLOSettings.value;
  _betterActionMap[JNAPAction.getDFSSettings] =
      _JNAPActionValue.getDFSSettings.value;
  _betterActionMap[JNAPAction.setDFSSettings] =
      _JNAPActionValue.setDFSSettings.value;
  _betterActionMap[JNAPAction.getAirtimeFairnessSettings] =
      _JNAPActionValue.getAirtimeFairnessSettings.value;
  _betterActionMap[JNAPAction.setAirtimeFairnessSettings] =
      _JNAPActionValue.setAirtimeFairnessSettings.value;
  _betterActionMap[JNAPAction.getSelectedChannels] =
      _JNAPActionValue.getSelectedChannels.value;
  _betterActionMap[JNAPAction.startAutoChannelSelection] =
      _JNAPActionValue.startAutoChannelSelection.value;
  _betterActionMap[JNAPAction.getRemoteSetting] =
      _JNAPActionValue.getRemoteSetting.value;
  _betterActionMap[JNAPAction.setRemoteSetting] =
      _JNAPActionValue.setRemoteSetting.value;
  _betterActionMap[JNAPAction.getGamingPrioritizationSettings] =
      _JNAPActionValue.getGamingPrioritizationSettings.value;
  _betterActionMap[JNAPAction.setGamingPrioritizationSettings] =
      _JNAPActionValue.setGamingPrioritizationSettings.value;
  _betterActionMap[JNAPAction.getAutoConfigurationSettings] =
      _JNAPActionValue.getAutoConfigurationSettings.value;
  _betterActionMap[JNAPAction.setUserAcknowledgedAutoConfiguration] =
      _JNAPActionValue.setUserAcknowledgedAutoConfiguration.value;
  _betterActionMap[JNAPAction.getUPnPSettings] =
      _JNAPActionValue.getUPnPSettings.value;
  _betterActionMap[JNAPAction.setUPnPSettings] =
      _JNAPActionValue.setUPnPSettings.value;
  // vpn
  _betterActionMap[JNAPAction.getVPNUser] = _JNAPActionValue.getVPNUser.value;
  _betterActionMap[JNAPAction.setVPNUser] = _JNAPActionValue.setVPNUser.value;
  _betterActionMap[JNAPAction.getVPNGateway] =
      _JNAPActionValue.getVPNGateway.value;
  _betterActionMap[JNAPAction.setVPNGateway] =
      _JNAPActionValue.setVPNGateway.value;
  _betterActionMap[JNAPAction.getVPNService] =
      _JNAPActionValue.getVPNService.value;
  _betterActionMap[JNAPAction.setVPNService] =
      _JNAPActionValue.setVPNService.value;
  _betterActionMap[JNAPAction.testVPNConnection] =
      _JNAPActionValue.testVPNConnection.value;
  _betterActionMap[JNAPAction.getTunneledUser] =
      _JNAPActionValue.getTunneledUser.value;
  _betterActionMap[JNAPAction.setTunneledUser] =
      _JNAPActionValue.setTunneledUser.value;
  _betterActionMap[JNAPAction.setVPNApply] = _JNAPActionValue.setVPNApply.value;
}

void buildBetterActions(List<String> routerServices) {
  initBetterActions();
  final List<JNAPService> supportedServices = routerServices
      .where((routerService) => JNAPService.appSupportedServices
          .any((supportedService) => routerService == supportedService.value))
      .map((service) => JNAPService.appSupportedServices
          .firstWhere((supportedService) => supportedService.value == service))
      .toList();
  final serviceMap = groupAndSortJNAPServices(supportedServices);
  final sortedServiceList =
      serviceMap.values.reduce((all, value) => all..addAll(value));
  for (final service in sortedServiceList) {
    _updateBetterActions(service);
  }
}

Map<String, List<JNAPService>> groupAndSortJNAPServices(
    List<JNAPService> services) {
  final groupedServices = groupBy<JNAPService, String>(services, (service) {
    final name = service.name;
    final match = RegExp(r'(\d+)').firstMatch(name);
    if (match != null) {
      return name.substring(0, name.indexOf(match.group(0)!));
    }
    return name;
  });

  final sortedGroupedServices = <String, List<JNAPService>>{};

  groupedServices.forEach((key, value) {
    sortedGroupedServices[key] = value.sorted((a, b) {
      final aMatch = RegExp(r'(\d+)').firstMatch(a.name);
      final bMatch = RegExp(r'(\d+)').firstMatch(b.name);

      if (aMatch != null && bMatch != null) {
        return int.parse(aMatch.group(1)!)
            .compareTo(int.parse(bMatch.group(1)!));
      } else if (aMatch != null) {
        return 1;
      } else if (bMatch != null) {
        return -1;
      } else {
        return a.name.compareTo(b.name);
      }
    }).toList();
  });

  return sortedGroupedServices;
}
