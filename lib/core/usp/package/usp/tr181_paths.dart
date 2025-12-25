/// TR-181 Path Constants
///
/// Standard TR-181 data model paths used for USP communication.
/// These paths are protocol-agnostic and represent the Device:2 data model.
library;

/// TR-181 path constants for device data model.
///
/// Paths follow the TR-181 Issue 2 Device:2 naming convention.
/// Use with [UspPath.parse] to create path objects for USP requests.
class Tr181Paths {
  Tr181Paths._();

  // ===========================================================================
  // Device Info
  // ===========================================================================

  /// Device information root path.
  /// Contains: Manufacturer, ModelName, SerialNumber, HardwareVersion,
  /// SoftwareVersion, Description, UpTime, etc.
  static const deviceInfo = 'Device.DeviceInfo.';

  /// Process status for CPU usage.
  static const processStatus = 'Device.DeviceInfo.ProcessStatus.';

  /// Memory status for memory usage.
  static const memoryStatus = 'Device.DeviceInfo.MemoryStatus.';

  // ===========================================================================
  // WiFi
  // ===========================================================================

  /// WiFi root path (for RadioNumberOfEntries, AccessPointNumberOfEntries).
  static const wifi = 'Device.WiFi.';

  /// WiFi Radio configuration.
  /// Contains: Enable, Status, Channel, PossibleChannels, OperatingFrequencyBand,
  /// SupportedStandards, OperatingStandards, OperatingChannelBandwidth, etc.
  static const wifiRadio = 'Device.WiFi.Radio.';

  /// WiFi SSID configuration.
  /// Contains: Enable, Status, SSID, MACAddress, etc.
  static const wifiSsid = 'Device.WiFi.SSID.';

  /// WiFi Access Point configuration.
  /// Contains: Enable, SSIDAdvertisementEnabled, Security.*, AssociatedDevice.*, etc.
  static const wifiAccessPoint = 'Device.WiFi.AccessPoint.';

  /// WiFi MultiAP for mesh networks.
  /// Contains: APDeviceNumberOfEntries, APDevice.* (mesh nodes).
  static const wifiMultiAp = 'Device.WiFi.MultiAP.';

  /// WiFi MultiAP APDevice (mesh node).
  /// Contains: MACAddress, BackhaulLinkType, BackhaulMACAddress, SerialNumber, etc.
  static const wifiMultiApDevice = 'Device.WiFi.MultiAP.APDevice.';

  // ===========================================================================
  // Network - Hosts
  // ===========================================================================

  /// Hosts root path (for HostNumberOfEntries).
  static const hosts = 'Device.Hosts.';

  /// Host entries (connected devices).
  /// Contains: PhysAddress, IPAddress, HostName, Active, InterfaceType, etc.
  static const hostsHost = 'Device.Hosts.Host.';

  // ===========================================================================
  // Network - IP Interface
  // ===========================================================================

  /// IP Interface for WAN (typically Interface.1).
  /// Contains: Enable, Status, IPv4Address.*, etc.
  static const ipInterfaceWan = 'Device.IP.Interface.1.';

  /// IP Interface for LAN (typically Interface.2).
  /// Contains: Enable, Status, IPv4Address.*, etc.
  static const ipInterfaceLan = 'Device.IP.Interface.2.';

  // ===========================================================================
  // Network - Ethernet
  // ===========================================================================

  /// Ethernet interfaces.
  /// Contains: Enable, Status, MACAddress, MaxBitRate, etc.
  static const ethernet = 'Device.Ethernet.Interface.';

  // ===========================================================================
  // Network - DHCP
  // ===========================================================================

  /// DHCPv4 configuration.
  /// Contains: Server.Pool.*, Client.*, etc.
  static const dhcpv4 = 'Device.DHCPv4.';

  /// DHCPv4 client.
  static const dhcpv4Client = 'Device.DHCPv4.Client.';

  // ===========================================================================
  // Network - Routing
  // ===========================================================================

  /// IPv4 routing table.
  static const routing = 'Device.Routing.Router.1.';

  // ===========================================================================
  // Time
  // ===========================================================================

  /// Time settings.
  /// Contains: CurrentLocalTime, LocalTimeZone, NTPServer, etc.
  static const time = 'Device.Time.';

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  /// Returns all paths needed for GetDeviceInfo.
  static List<String> get deviceInfoPaths => [deviceInfo];

  /// Returns all paths needed for GetRadioInfo.
  static List<String> get radioInfoPaths => [
        wifi,
        wifiRadio,
        wifiSsid,
        wifiAccessPoint,
      ];

  /// Returns all paths needed for GetDevices.
  static List<String> get devicesPaths => [
        hosts,
        hostsHost,
        wifiMultiAp,
        wifiMultiApDevice,
      ];

  /// Returns all paths needed for GetBackhaulInfo.
  static List<String> get backhaulInfoPaths => [
        wifiMultiAp,
        wifiMultiApDevice,
      ];

  /// Returns all paths needed for GetWANStatus.
  static List<String> get wanStatusPaths => [
        ipInterfaceWan,
        ethernet,
        dhcpv4Client,
        routing,
      ];

  /// Returns all paths needed for GetLANSettings.
  static List<String> get lanSettingsPaths => [
        ipInterfaceLan,
        dhcpv4,
      ];

  /// Returns all paths needed for GetGuestRadioSettings.
  static List<String> get guestRadioSettingsPaths => [
        wifi,
        wifiAccessPoint,
        wifiSsid,
        wifiRadio,
      ];

  /// Returns all paths needed for GetMACFilterSettings.
  static List<String> get macFilterSettingsPaths => [
        wifiAccessPoint,
      ];

  /// Returns all paths needed for GetNetworkConnections.
  static List<String> get networkConnectionsPaths => [
        hostsHost,
        wifiRadio,
        wifiAccessPoint,
        wifiSsid,
      ];

  /// Returns all paths needed for GetNodesWirelessNetworkConnections.
  static List<String> get nodesWirelessConnectionsPaths => [
        wifiMultiApDevice,
        wifiAccessPoint,
        wifiSsid,
      ];

  /// Returns all paths needed for GetTimeSettings.
  static List<String> get timeSettingsPaths => [time];

  /// Returns all paths needed for GetSystemStats.
  static List<String> get systemStatsPaths => [deviceInfo];

  /// Returns all paths needed for GetInternetConnectionStatus.
  static List<String> get internetConnectionStatusPaths => [ipInterfaceWan];

  /// Returns all paths needed for GetEthernetPortConnections.
  static List<String> get ethernetPortConnectionsPaths => [ethernet];
}
