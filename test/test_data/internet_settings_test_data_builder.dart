import 'package:privacy_gui/core/jnap/models/ipv6_automatic_settings.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_settings.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/mac_address_clone_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart' as jnap
    show SupportedWANCombination;
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';

/// Test Data Builder for Internet Settings
///
/// Provides factory methods to create JNAP models and UI models for testing.
/// Usage:
/// ```dart
/// // Create JNAP mock data
/// final wanSettings = InternetSettingsTestDataBuilder.dhcpWanSettings();
///
/// // Create UI models
/// final uiModel = InternetSettingsTestDataBuilder.dhcpUIModel();
/// ```
class InternetSettingsTestDataBuilder {
  // ============================================================================
  // JNAP Models - RouterWANSettings
  // ============================================================================

  static RouterWANSettings dhcpWanSettings({
    int mtu = 0,
    SinglePortVLANTaggingSettings? wanTaggingSettings,
  }) {
    return RouterWANSettings.dhcp(
      mtu: mtu,
      wanTaggingSettings: wanTaggingSettings,
    );
  }

  static RouterWANSettings staticWanSettings({
    int mtu = 1500,
    String ipAddress = '111.222.111.123',
    String gateway = '111.222.111.1',
    String dns1 = '8.8.8.8',
    String? dns2 = '8.8.4.4',
    String? dns3,
    int prefixLength = 24,
    String? domainName = 'linksys.com',
    SinglePortVLANTaggingSettings? wanTaggingSettings,
  }) {
    return RouterWANSettings.static(
      mtu: mtu,
      staticSettings: StaticSettings(
        ipAddress: ipAddress,
        networkPrefixLength: prefixLength,
        gateway: gateway,
        dnsServer1: dns1,
        dnsServer2: dns2,
        dnsServer3: dns3,
        domainName: domainName,
      ),
      wanTaggingSettings: wanTaggingSettings ??
          const SinglePortVLANTaggingSettings(
            isEnabled: false,
          ),
    );
  }

  static RouterWANSettings pppoeWanSettings({
    int mtu = 0,
    String behavior = 'KeepAlive',
    int? maxIdleMinutes = 15,
    int? reconnectAfterSeconds = 30,
    String username = 'testuser',
    String password = 'testpass',
    String serviceName = '',
    bool wanTaggingEnabled = false,
    int vlanId = 0,
  }) {
    return RouterWANSettings.pppoe(
      mtu: mtu,
      pppoeSettings: PPPoESettings(
        username: username,
        password: password,
        serviceName: serviceName,
        behavior: behavior,
        maxIdleMinutes: maxIdleMinutes,
        reconnectAfterSeconds: reconnectAfterSeconds,
      ),
      wanTaggingSettings: SinglePortVLANTaggingSettings(
        isEnabled: wanTaggingEnabled,
        vlanTaggingSettings: wanTaggingEnabled
            ? PortTaggingSettings(
                vlanID: vlanId,
                vlanStatus: 'Tagged',
              )
            : null,
      ),
    );
  }

  static RouterWANSettings pptpWanSettings({
    int mtu = 0,
    String behavior = 'KeepAlive',
    int? maxIdleMinutes = 15,
    int? reconnectAfterSeconds = 30,
    String username = 'testuser',
    String password = 'testpass',
    String serverIp = '111.222.111.1',
    bool useStaticSettings = false,
    String? staticIpAddress,
    String? staticGateway,
    String? staticDns1,
    String? staticDns2,
    String? staticDns3,
    int? networkPrefixLength,
    String? domainName,
    bool wanTaggingEnabled = false,
    int vlanId = 0,
  }) {
    return RouterWANSettings.pptp(
      mtu: mtu,
      tpSettings: TPSettings(
        useStaticSettings: useStaticSettings,
        staticSettings: useStaticSettings
            ? StaticSettings(
                ipAddress: staticIpAddress!,
                networkPrefixLength: networkPrefixLength!,
                gateway: staticGateway!,
                dnsServer1: staticDns1!,
                dnsServer2: staticDns2,
                dnsServer3: staticDns3,
                domainName: domainName,
              )
            : null,
        server: serverIp,
        username: username,
        password: password,
        behavior: behavior,
        maxIdleMinutes: maxIdleMinutes,
        reconnectAfterSeconds: reconnectAfterSeconds,
      ),
      wanTaggingSettings: SinglePortVLANTaggingSettings(
        isEnabled: wanTaggingEnabled,
        vlanTaggingSettings: wanTaggingEnabled
            ? PortTaggingSettings(
                vlanID: vlanId,
                vlanStatus: 'Tagged',
              )
            : null,
      ),
    );
  }

  static RouterWANSettings l2tpWanSettings({
    int mtu = 0,
    String behavior = 'KeepAlive',
    int? maxIdleMinutes = 15,
    int? reconnectAfterSeconds = 30,
    String username = 'testuser',
    String password = 'testpass',
    String serverIp = '111.222.111.1',
    bool useStaticSettings = false,
    String? staticIpAddress,
    String? staticGateway,
    String? staticDns1,
    String? staticDns2,
    String? staticDns3,
    int? networkPrefixLength,
    String? domainName,
    bool wanTaggingEnabled = false,
    int vlanId = 0,
  }) {
    return RouterWANSettings.l2tp(
      mtu: mtu,
      tpSettings: TPSettings(
        useStaticSettings: useStaticSettings,
        staticSettings: useStaticSettings
            ? StaticSettings(
                ipAddress: staticIpAddress!,
                networkPrefixLength: networkPrefixLength!,
                gateway: staticGateway!,
                dnsServer1: staticDns1!,
                dnsServer2: staticDns2,
                dnsServer3: staticDns3,
                domainName: domainName,
              )
            : null,
        server: serverIp,
        username: username,
        password: password,
        behavior: behavior,
        maxIdleMinutes: maxIdleMinutes,
        reconnectAfterSeconds: reconnectAfterSeconds,
      ),
      wanTaggingSettings: wanTaggingEnabled
          ? SinglePortVLANTaggingSettings(
              isEnabled: true,
              vlanTaggingSettings: PortTaggingSettings(
                vlanID: vlanId,
                vlanStatus: 'Tagged',
              ),
            )
          : null,
    );
  }

  static RouterWANSettings bridgeWanSettings({
    int mtu = 0,
    bool useStaticSettings = false,
    StaticSettings? staticSettings,
  }) {
    return RouterWANSettings.bridge(
      mtu: mtu,
      bridgeSettings: BridgeSettings(
        useStaticSettings: useStaticSettings,
        staticSettings: staticSettings,
      ),
    );
  }

  // ============================================================================
  // JNAP Models - GetIPv6Settings
  // ============================================================================

  static GetIPv6Settings automaticIPv6Settings({
    bool isAutomatic = true,
    String? ipv6rdTunnelMode,
    String? prefix,
    int? prefixLength,
    String? borderRelay,
    int? borderRelayPrefixLength,
    String duid = '00:02:03:09:05:05:80:69:1A:13:16:0E',
  }) {
    return GetIPv6Settings(
      wanType: 'Automatic',
      duid: duid,
      ipv6AutomaticSettings: IPv6AutomaticSettings(
        isIPv6AutomaticEnabled: isAutomatic,
        ipv6rdTunnelMode: ipv6rdTunnelMode,
        ipv6rdTunnelSettings: ipv6rdTunnelMode == 'Manual'
            ? IPv6rdTunnelSettings(
                prefix: prefix ?? '',
                prefixLength: prefixLength ?? 0,
                borderRelay: borderRelay ?? '',
                borderRelayPrefixLength: borderRelayPrefixLength ?? 0,
              )
            : null,
      ),
    );
  }

  static GetIPv6Settings defaultIPv6Settings({
    required String wanType,
    bool isAutomatic = false,
    String duid = '00:02:03:09:05:05:80:69:1A:13:16:0E',
  }) {
    return GetIPv6Settings(
      wanType: wanType,
      duid: duid,
      ipv6AutomaticSettings: IPv6AutomaticSettings(
        isIPv6AutomaticEnabled: isAutomatic,
      ),
    );
  }

  // ============================================================================
  // JNAP Models - RouterWANStatus
  // ============================================================================

  static RouterWANStatus wanStatus({
    String macAddress = 'AA:BB:CC:DD:EE:FF',
    String detectedWANType = 'DHCP',
    String wanStatus = 'Connected',
    String wanIPv6Status = 'Disabled',
    WANConnectionInfo? wanConnection,
    WANIPv6ConnectionInfo? wanIPv6Connection,
    List<String>? supportedWANTypes,
    List<String>? supportedIPv6WANTypes,
    List<jnap.SupportedWANCombination>? supportedWANCombinations,
  }) {
    return RouterWANStatus(
      macAddress: macAddress,
      detectedWANType: detectedWANType,
      wanStatus: wanStatus,
      wanIPv6Status: wanIPv6Status,
      wanConnection: wanConnection,
      wanIPv6Connection: wanIPv6Connection,
      supportedWANTypes: supportedWANTypes ??
          ['DHCP', 'Static', 'PPPoE', 'PPTP', 'L2TP', 'Bridge'],
      supportedIPv6WANTypes:
          supportedIPv6WANTypes ?? ['Automatic', 'PPPoE', 'Pass-through'],
      supportedWANCombinations: supportedWANCombinations ??
          [
            const jnap.SupportedWANCombination(
              wanType: 'DHCP',
              wanIPv6Type: 'Automatic',
            ),
            const jnap.SupportedWANCombination(
              wanType: 'Static',
              wanIPv6Type: 'Automatic',
            ),
            const jnap.SupportedWANCombination(
              wanType: 'PPPoE',
              wanIPv6Type: 'Automatic',
            ),
            const jnap.SupportedWANCombination(
              wanType: 'L2TP',
              wanIPv6Type: 'Automatic',
            ),
            const jnap.SupportedWANCombination(
              wanType: 'PPTP',
              wanIPv6Type: 'Automatic',
            ),
            const jnap.SupportedWANCombination(
              wanType: 'Bridge',
              wanIPv6Type: 'Automatic',
            ),
            const jnap.SupportedWANCombination(
              wanType: 'DHCP',
              wanIPv6Type: 'Pass-through',
            ),
            const jnap.SupportedWANCombination(
              wanType: 'PPPoE',
              wanIPv6Type: 'PPPoE',
            ),
          ],
    );
  }

  // ============================================================================
  // JNAP Models - MACAddressCloneSettings
  // ============================================================================

  static MACAddressCloneSettings macAddressCloneSettings({
    bool enabled = false,
    String? macAddress,
  }) {
    return MACAddressCloneSettings(
      isMACAddressCloneEnabled: enabled,
      macAddress: enabled ? (macAddress ?? 'AA:BB:CC:DD:EE:FF') : null,
    );
  }

  // ============================================================================
  // JNAP Models - RouterLANSettings
  // ============================================================================

  static RouterLANSettings lanSettings({
    String? hostName = 'myrouter',
    int minNetworkPrefixLength = 16,
    int maxNetworkPrefixLength = 30,
    int minAllowedDHCPLeaseMinutes = 1,
    int? maxAllowedDHCPLeaseMinutes = 525600,
    int maxDHCPReservationDescriptionLength = 63,
    bool isDHCPEnabled = true,
    int networkPrefixLength = 24,
    String ipAddress = '192.168.1.1',
    String firstClientIPAddress = '192.168.1.10',
    String lastClientIPAddress = '192.168.1.254',
    int leaseMinutes = 1440,
    List<DHCPReservation> reservations = const [],
  }) {
    return RouterLANSettings(
      hostName: hostName ?? 'myrouter',
      minNetworkPrefixLength: minNetworkPrefixLength,
      maxNetworkPrefixLength: maxNetworkPrefixLength,
      minAllowedDHCPLeaseMinutes: minAllowedDHCPLeaseMinutes,
      maxAllowedDHCPLeaseMinutes: maxAllowedDHCPLeaseMinutes,
      maxDHCPReservationDescriptionLength: maxDHCPReservationDescriptionLength,
      isDHCPEnabled: isDHCPEnabled,
      networkPrefixLength: networkPrefixLength,
      ipAddress: ipAddress,
      dhcpSettings: DHCPSettings(
        firstClientIPAddress: firstClientIPAddress,
        lastClientIPAddress: lastClientIPAddress,
        leaseMinutes: leaseMinutes,
        reservations: reservations,
      ),
    );
  }

  // ============================================================================
  // UI Models - Ipv4SettingsUIModel
  // ============================================================================

  static Ipv4SettingsUIModel dhcpUIModel({
    int mtu = 0,
  }) {
    return Ipv4SettingsUIModel(
      ipv4ConnectionType: 'DHCP',
      mtu: mtu,
    );
  }

  static Ipv4SettingsUIModel staticUIModel({
    int mtu = 1500,
    String ipAddress = '111.222.111.123',
    String gateway = '111.222.111.1',
    String dns1 = '8.8.8.8',
    String dns2 = '8.8.4.4',
    int prefixLength = 24,
    String? domainName = 'linksys.com',
  }) {
    return Ipv4SettingsUIModel(
      ipv4ConnectionType: 'Static',
      mtu: mtu,
      staticIpAddress: ipAddress,
      staticGateway: gateway,
      staticDns1: dns1,
      staticDns2: dns2,
      networkPrefixLength: prefixLength,
      domainName: domainName,
    );
  }

  static Ipv4SettingsUIModel pppoeUIModel({
    int mtu = 0,
    PPPConnectionBehavior behavior = PPPConnectionBehavior.keepAlive,
    int maxIdleMinutes = 15,
    int reconnectAfterSeconds = 30,
    String username = 'testuser',
    String password = 'testpass',
    String serviceName = '',
    bool wanTaggingEnabled = false,
    int vlanId = 0,
  }) {
    return Ipv4SettingsUIModel(
      ipv4ConnectionType: 'PPPoE',
      mtu: mtu,
      behavior: behavior,
      maxIdleMinutes: maxIdleMinutes,
      reconnectAfterSeconds: reconnectAfterSeconds,
      username: username,
      password: password,
      serviceName: serviceName,
      wanTaggingSettingsEnable: wanTaggingEnabled,
      vlanId: vlanId,
    );
  }

  // ============================================================================
  // UI Models - Ipv6SettingsUIModel
  // ============================================================================

  static Ipv6SettingsUIModel automaticIPv6UIModel({
    bool isAutomatic = true,
    IPv6rdTunnelMode? tunnelMode,
    String? prefix,
    int? prefixLength,
    String? borderRelay,
    int? borderRelayPrefixLength,
  }) {
    return Ipv6SettingsUIModel(
      ipv6ConnectionType: 'Automatic',
      isIPv6AutomaticEnabled: isAutomatic,
      ipv6rdTunnelMode: tunnelMode,
      ipv6Prefix: prefix,
      ipv6PrefixLength: prefixLength,
      ipv6BorderRelay: borderRelay,
      ipv6BorderRelayPrefixLength: borderRelayPrefixLength,
    );
  }

  static Ipv6SettingsUIModel defaultIPv6UIModel({
    required String connectionType,
    bool isAutomatic = false,
  }) {
    return Ipv6SettingsUIModel(
      ipv6ConnectionType: connectionType,
      isIPv6AutomaticEnabled: isAutomatic,
    );
  }

  // ============================================================================
  // UI Models - InternetSettingsUIModel
  // ============================================================================

  static InternetSettingsUIModel internetSettingsUIModel({
    Ipv4SettingsUIModel? ipv4Setting,
    Ipv6SettingsUIModel? ipv6Setting,
    bool macClone = false,
    String? macCloneAddress,
  }) {
    return InternetSettingsUIModel(
      ipv4Setting: ipv4Setting ?? dhcpUIModel(),
      ipv6Setting: ipv6Setting ?? automaticIPv6UIModel(),
      macClone: macClone,
      macCloneAddress: macCloneAddress,
    );
  }

  // ============================================================================
  // UI Models - InternetSettingsStatusUIModel
  // ============================================================================

  static InternetSettingsStatusUIModel internetSettingsStatusUIModel({
    List<String>? supportedIPv4ConnectionType,
    List<SupportedWANCombinationUIModel>? supportedWANCombinations,
    List<String>? supportedIPv6ConnectionType,
    String duid = '00:02:03:09:05:05:80:69:1A:13:16:0E',
    String? redirection,
    String? hostname,
  }) {
    return InternetSettingsStatusUIModel(
      supportedIPv4ConnectionType: supportedIPv4ConnectionType ??
          ['DHCP', 'Static', 'PPPoE', 'PPTP', 'L2TP', 'Bridge'],
      supportedWANCombinations: supportedWANCombinations ??
          [
            const SupportedWANCombinationUIModel(
              wanType: 'DHCP',
              wanIPv6Type: 'Automatic',
            ),
            const SupportedWANCombinationUIModel(
              wanType: 'Static',
              wanIPv6Type: 'Automatic',
            ),
            const SupportedWANCombinationUIModel(
              wanType: 'PPPoE',
              wanIPv6Type: 'Automatic',
            ),
          ],
      supportedIPv6ConnectionType:
          supportedIPv6ConnectionType ?? ['Automatic', 'PPPoE', 'Pass-through'],
      duid: duid,
      redirection: redirection,
      hostname: hostname,
    );
  }
}
