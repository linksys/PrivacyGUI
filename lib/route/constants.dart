class RoutePath {
  /// top
  static const home = '/';
  static const prepareDashboard = '/prepareDashboard';
  static const selectNetwork = '/selectNetwork';

  /// login
  static const cloudLoginAccount = 'cloudLoginAccount';
  static const cloudLoginPassword = 'cloudLoginPassword';
  static const cloudForgotPassword = 'cloudForgotPassword';
  static const phoneRegionCode = 'phoneRegionCode';
  static const localLoginPassword = '/localLoginPassword';
  static const localRouterRecovery = 'localRouterRecovery';
  static const localPasswordReset = 'localPasswordReset';

  /// dashboard
  static const dashboardHome = '/dashboardHome';
  static const dashboardMenu = '/dashboardMenu';
  static const dashboardDevices = 'dashboardDevices';
  static const dashboardSettings = 'dashboardSettings';
  static const dashboardAdvancedSettings = 'dashboardAdvancedSettings';
  static const dashboardSupport = '/dashboardSupport';

  /// speed test
  static const dashboardSpeedTest = 'dashboardSpeedTest';
  static const speedTestSelection = 'speedTestSelection';
  static const speedTestExternal = 'speedTestExternal';

  /// settings
  static const settingsNotification = 'notificationSettings';
  static const settingsWifi = 'wifiSettings';
  static const settingsNodes = 'nodes';
  static const settingsNetworkAdmin = 'routerAdmin';
  static const settingsTimeZone = 'timeZone';
  static const settingsInternet = 'internetSettings';
  static const settingsIpDetails = 'ipDetails';
  static const settingsLocalNetwork = 'localNetworkSettings';
  static const settingsMacFiltering = 'macFilteringSettings';
  static const settingsPort = 'portSettings';
  static const settingsFirewall = 'firewall';

  /// otp
  static const otpStart = 'otp';
  static const otpSelectMethods = 'otpSelectMethod';
  static const otpAddPhone = 'optAddPhone';
  static const otpInputCode = 'optInputCode';

  /// wifi
  static const wifiSettingsReview = 'wifiSettingsReview';
  static const wifiShare = 'wifiShare';
  static const wifiShareDetails = 'wifiShareDetails';
  static const wifiAdvancedSettings = 'wifiSettingsAdvanced';

  /// node
  static const nodeDetails = 'nodeDetails';
  static const nodeLight = 'nodeLight';
  static const changeNodeName = 'changeNodeName';
  static const nodeLightSettings = 'nodeLightSettings';
  static const addNodes = '/addNodes';

  /// device
  static const deviceDetails = 'deviceDetails';
  static const changeDeviceName = 'changeDeviceName';
  static const changeDeviceAvatar = 'changeDeviceAvatar';
  static const offlineDevices = 'offlineDevices';

  /// account
  static const accountInfo = 'accountInfo';
  static const twoStepVerification = 'twoStepVerification';

  /// Internet Setting
  static const mtuPicker = 'mtuPicker';
  static const macClone = 'macClone';
  static const connectionType = 'connectionType';
  static const connectionTypeSelection = 'connectionTypeSelection';

  /// Local Network
  static const dhcpReservation = 'dhcpReservation';
  static const dhcpReservationEdit = 'dhcpReservationEdit';
  static const dhcpServer = 'dhcpServer';
  static const localNetworkEdit = 'localNetworkEdit';

  /// mac filtering
  static const macFilteringInput = 'macFilteringInput';

  /// port forwarding
  static const singlePortForwardingList = 'singlePortForwardingList';
  static const singlePortForwardingRule = 'singlePortForwardingRule';
  static const portRangeForwardingList = 'portRangeForwardingList';
  static const portRangeForwardingRule = 'portRangeForwardingRule';
  static const portRangeTriggeringList = 'portRangeTriggeringList';
  static const protRangeTriggeringRule = 'portRangeTriggeringRule';

  /// Ipv6 port service
  static const ipv6PortServiceList = 'ipv6PortServiceList';
  static const ipv6PortServiceRule = 'ipv6PortServiceRule';

  /// linkup
  static const linkup = 'linkup';

  /// PnP
  static const pnp = '/pnp';
  static const pnpConfig = 'pnpConfig';
  static const pnpNoInternetConnection = '/noInternetConnection';
  static const pnpUnplugModem = 'unPlugModem';
  static const pnpMakeSureLightOff = 'makeSureLightOff';
  static const pnpWaitingModem = 'waitingModem';
  static const pnpIspSettings = 'pnpIspSettings';
  static const pnpIspTypeSelection = 'pnpIspTypeSelection';
  static const pnpStaticIp = 'pnpStaticIp';
  static const pnpIspSettingsAuth = 'pnpIspSettingsAuth';

  /// Safe Browsing
  static const safeBrowsing = 'safeBrowsing';

  /// Troubleshooting
  static const troubleshooting = 'troubleshooting';
  static const troubleshootingPing = 'troubleshootingPing';

  /// ContactSupport
  static const contactSupportChoose = 'contactSupportChoose';
  static const contactSupportDetails = 'contactSupportDetails';

  /// DDNS
  static const settingsDDNS = 'ddnsSettings';

  ///Channel Finder
  static const channelFinderOptimize = 'channelFinderOptimize';

  /// Device picker
  static const devicePicker = 'devicePicker';

  /// debug
  static const debug = 'debug';
}

class RouteNamed {
  /// top
  static const home = 'home';
  static const prepareDashboard = 'prepareDashboard';
  static const selectNetwork = 'selectNetwork';

  /// login
  static const cloudLoginAccount = 'cloudLoginAccount';
  static const cloudLoginPassword = 'cloudLoginPassword';
  static const cloudForgotPassword = 'cloudForgotPassword';
  static const phoneRegionCode = 'phoneRegionCode';
  static const localLoginPassword = 'localLoginPassword';
  static const localRouterRecovery = 'localRouterRecovery';
  static const localPasswordReset = 'localPasswordReset';

  /// dashboard
  static const dashboardMenu = 'dashboardMenu';
  static const dashboardHome = 'dashboardHome';
  static const dashboardDevices = 'dashboardDevices';
  static const dashboardSettings = 'dashboardSettings';
  static const dashboardSupport = 'dashboardSupport';
  static const dashboardAdvancedSettings = 'dashboardAdvancedSettings';

  /// speed test
  static const dashboardSpeedTest = 'dashboardSpeedTest';
  static const speedTestSelection = 'speedTestSelection';
  static const speedTestExternal = 'speedTestExternal';

  /// settings
  static const settingsNotification = 'notificationSettings';
  static const settingsWifi = 'wifiSettings';
  static const settingsNodes = 'nodes';
  static const settingsNetworkAdmin = 'networkAdmin';
  static const settingsTimeZone = 'timeZone';
  static const settingsInternet = 'internetSettings';
  static const settingsIpDetails = 'ipDetails';
  static const settingsLocalNetwork = 'localNetworkSettings';
  static const settingsMacFiltering = 'macFilteringSettings';
  static const settingsPort = 'portSettings';
  static const settingsFirewall = 'firewall';

  /// otp
  static const otpStart = 'otp';
  static const otpSelectMethods = 'otpSelectMethod';
  static const otpAddPhone = 'optAddPhone';
  static const otpInputCode = 'optInputCode';

  /// wifi
  static const wifiSettingsReview = 'wifiSettingsReview';
  static const wifiShare = 'wifiShare';
  static const wifiShareDetails = 'wifiShareDetails';
  static const wifiAdvancedSettings = 'wifiSettingsAdvanced';

  /// node
  static const nodeDetails = 'nodeDetails';
  static const nodeLight = 'nodeLight';
  static const changeNodeName = 'changeNodeName';
  static const nodeLightSettings = 'nodeLightSettings';
  static const addNodes = 'addNodes';

  ///device
  static const deviceDetails = 'deviceDetails';
  static const changeDeviceName = 'changeDeviceName';
  static const changeDeviceAvatar = 'changeDeviceAvatar';
  static const offlineDevices = 'offlineDevices';

  /// account
  static const accountInfo = 'accountInfo';
  static const twoStepVerification = 'twoStepVerification';

  /// Internet Setting
  static const mtuPicker = 'mtuPicker';
  static const macClone = 'macClone';
  static const connectionType = 'connectionType';
  static const connectionTypeSelection = 'connectionTypeSelection';

  /// Local Network
  static const dhcpReservation = 'dhcpReservation';
  static const dhcpReservationEdit = 'dhcpReservationEdit';
  static const dhcpServer = 'dhcpServer';
  static const localNetworkEdit = 'localNetworkEdit';

  /// mac filtering
  static const macFilteringInput = 'macFilteringInput';

  /// port forwarding
  static const singlePortForwardingList = 'singlePortForwardingList';
  static const singlePortForwardingRule = 'singlePortForwardingRule';
  static const portRangeForwardingList = 'portRangeForwardingList';
  static const portRangeForwardingRule = 'portRangeForwardingRule';
  static const portRangeTriggeringList = 'portRangeTriggeringList';
  static const protRangeTriggeringRule = 'portRangeTriggeringRule';
  static const selectProtocol = 'selectProtocol';

  /// Ipv6 port service
  static const ipv6PortServiceList = 'ipv6PortServiceList';
  static const ipv6PortServiceRule = 'ipv6PortServiceRule';

  /// linkup
  static const linkup = 'linkup';

  /// PnP
  static const pnp = 'pnp';
  static const pnpConfig = 'pnpConfig';
  static const pnpNoInternetConnection = 'noInternetConnection';
  static const pnpUnplugModem = 'unPlugModem';
  static const pnpMakeSureLightOff = 'makeSureLightOff';
  static const pnpWaitingModem = 'waitingModem';
  static const pnpIspSettings = 'pnpIspSettings';
  static const pnpIspTypeSelection = 'pnpIspTypeSelection';
  static const pnpStaticIp = 'pnpStaticIp';
  static const pnpIspSettingsAuth = 'pnpIspSettingsAuth';

  /// Safe Browsing
  static const safeBrowsing = 'safeBrowsing';

  /// Troubleshooting
  static const troubleshooting = 'troubleshooting';
  static const troubleshootingPing = 'troubleshootingPing';

  /// ContactSupport
  static const contactSupportChoose = 'contactSupportChoose';
  static const contactSupportDetails = 'contactSupportDetails';

  /// DDNS
  static const settingsDDNS = 'ddnsSettings';

  ///Channel Finder
  static const channelFinderOptimize = 'channelFinderOptimize';

  /// Device picker
  static const devicePicker = 'devicePicker';

  /// debug
  static const debug = 'debug';
}