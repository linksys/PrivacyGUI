import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

/// Unified editable form model that merges WAN IPv4 + IPv6 settings.
///
/// Supports immutable updates via [copyWith]. Dirty checking is performed by
/// comparing two instances (Equatable). Constructed by the service layer via
/// [UspInternetSettingsService.buildForm].
class UspInternetSettingsForm extends Equatable {
  // === Core ===
  final UspWanConnectionType connectionType;

  // === IPv4 Static Fields ===
  final String staticIpAddress;
  final String subnetMask;
  final String defaultGateway;
  final String dnsServer1;
  final String dnsServer2;
  final String dnsServer3;

  // === PPPoE / PPTP / L2TP Fields ===
  final String pppUsername;
  final String pppPassword;
  final String pppoeServiceName;
  final String connectionTrigger; // 'AlwaysOn' | 'OnDemand'
  final int idleDisconnectTime;
  final int lcpEchoInterval;
  final String serverAddress; // PPTP/L2TP VPN server hostname or IP

  // === VLAN ===
  final bool vlanEnabled;
  final int vlanId;

  // === MTU ===
  final int mtu; // 0 = auto

  // === MAC Clone ===
  final String wanMacAddress;

  // === IPv6 ===
  final bool ipv6Enabled;
  final bool dhcpv6Enabled;
  final bool ipv6rdEnabled;
  final String ipv6rdPrefix;
  final int ipv6rdIpv4MaskLength;
  final String ipv6rdBorderRelay;

  const UspInternetSettingsForm({
    required this.connectionType,
    this.staticIpAddress = '',
    this.subnetMask = '',
    this.defaultGateway = '',
    this.dnsServer1 = '',
    this.dnsServer2 = '',
    this.dnsServer3 = '',
    this.pppUsername = '',
    this.pppPassword = '',
    this.pppoeServiceName = '',
    this.connectionTrigger = 'AlwaysOn',
    this.idleDisconnectTime = 0,
    this.lcpEchoInterval = 0,
    this.serverAddress = '',
    this.vlanEnabled = false,
    this.vlanId = 0,
    this.mtu = 0,
    this.wanMacAddress = '',
    this.ipv6Enabled = false,
    this.dhcpv6Enabled = false,
    this.ipv6rdEnabled = false,
    this.ipv6rdPrefix = '',
    this.ipv6rdIpv4MaskLength = 0,
    this.ipv6rdBorderRelay = '',
  });

  UspInternetSettingsForm copyWith({
    UspWanConnectionType? connectionType,
    String? staticIpAddress,
    String? subnetMask,
    String? defaultGateway,
    String? dnsServer1,
    String? dnsServer2,
    String? dnsServer3,
    String? pppUsername,
    String? pppPassword,
    String? pppoeServiceName,
    String? connectionTrigger,
    int? idleDisconnectTime,
    int? lcpEchoInterval,
    String? serverAddress,
    bool? vlanEnabled,
    int? vlanId,
    int? mtu,
    String? wanMacAddress,
    bool? ipv6Enabled,
    bool? dhcpv6Enabled,
    bool? ipv6rdEnabled,
    String? ipv6rdPrefix,
    int? ipv6rdIpv4MaskLength,
    String? ipv6rdBorderRelay,
  }) {
    return UspInternetSettingsForm(
      connectionType: connectionType ?? this.connectionType,
      staticIpAddress: staticIpAddress ?? this.staticIpAddress,
      subnetMask: subnetMask ?? this.subnetMask,
      defaultGateway: defaultGateway ?? this.defaultGateway,
      dnsServer1: dnsServer1 ?? this.dnsServer1,
      dnsServer2: dnsServer2 ?? this.dnsServer2,
      dnsServer3: dnsServer3 ?? this.dnsServer3,
      pppUsername: pppUsername ?? this.pppUsername,
      pppPassword: pppPassword ?? this.pppPassword,
      pppoeServiceName: pppoeServiceName ?? this.pppoeServiceName,
      connectionTrigger: connectionTrigger ?? this.connectionTrigger,
      idleDisconnectTime: idleDisconnectTime ?? this.idleDisconnectTime,
      lcpEchoInterval: lcpEchoInterval ?? this.lcpEchoInterval,
      serverAddress: serverAddress ?? this.serverAddress,
      vlanEnabled: vlanEnabled ?? this.vlanEnabled,
      vlanId: vlanId ?? this.vlanId,
      mtu: mtu ?? this.mtu,
      wanMacAddress: wanMacAddress ?? this.wanMacAddress,
      ipv6Enabled: ipv6Enabled ?? this.ipv6Enabled,
      dhcpv6Enabled: dhcpv6Enabled ?? this.dhcpv6Enabled,
      ipv6rdEnabled: ipv6rdEnabled ?? this.ipv6rdEnabled,
      ipv6rdPrefix: ipv6rdPrefix ?? this.ipv6rdPrefix,
      ipv6rdIpv4MaskLength: ipv6rdIpv4MaskLength ?? this.ipv6rdIpv4MaskLength,
      ipv6rdBorderRelay: ipv6rdBorderRelay ?? this.ipv6rdBorderRelay,
    );
  }

  @override
  List<Object?> get props => [
        connectionType,
        staticIpAddress,
        subnetMask,
        defaultGateway,
        dnsServer1,
        dnsServer2,
        dnsServer3,
        pppUsername,
        pppPassword,
        pppoeServiceName,
        connectionTrigger,
        idleDisconnectTime,
        lcpEchoInterval,
        serverAddress,
        vlanEnabled,
        vlanId,
        mtu,
        wanMacAddress,
        ipv6Enabled,
        dhcpv6Enabled,
        ipv6rdEnabled,
        ipv6rdPrefix,
        ipv6rdIpv4MaskLength,
        ipv6rdBorderRelay,
      ];
}
