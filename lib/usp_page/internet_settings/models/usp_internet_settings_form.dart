import 'package:equatable/equatable.dart';
import 'package:privacy_gui/generated/ipv6settings.g.dart';
import 'package:privacy_gui/generated/wan_settings.g.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_wan_connection_type.dart';

/// Unified editable form model that merges WAN IPv4 + IPv6 settings.
///
/// Created from generated USP models via [fromGenerated] and supports
/// immutable updates via [copyWith]. Dirty checking is performed by
/// comparing two instances (Equatable).
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

  // === PPPoE Fields ===
  final String pppUsername;
  final String pppPassword;
  final String pppoeServiceName;
  final String connectionTrigger; // 'AlwaysOn' | 'OnDemand'
  final int idleDisconnectTime;
  final int lcpEchoInterval;

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

  /// Create form from fetched USP generated models.
  factory UspInternetSettingsForm.fromGenerated(
    WanSettings wan,
    Ipv6Settings ipv6,
  ) {
    return UspInternetSettingsForm(
      connectionType: UspWanConnectionType.fromWanSettings(wan),
      staticIpAddress: wan.staticIpAddress,
      subnetMask: wan.subnetMask,
      defaultGateway: wan.defaultGateway,
      dnsServer1: wan.dnsServer1,
      dnsServer2: wan.dnsServer2,
      dnsServer3: wan.dnsServer3,
      pppUsername: wan.pppUsername,
      pppPassword: wan.pppPassword,
      pppoeServiceName: wan.pppoeServiceName,
      connectionTrigger: wan.connectionTrigger,
      idleDisconnectTime: wan.idleDisconnectTime,
      lcpEchoInterval: wan.lcpEchoInterval,
      vlanEnabled: wan.vlanEnabled,
      vlanId: wan.vlanId,
      mtu: wan.mtu,
      wanMacAddress: wan.wanMacAddress,
      ipv6Enabled: ipv6.ipv6Enabled,
      dhcpv6Enabled: ipv6.dhcpv6Enabled,
      ipv6rdEnabled: ipv6.ipv6rdEnabled,
      ipv6rdPrefix: ipv6.ipv6rdPrefix,
      ipv6rdIpv4MaskLength: ipv6.ipv6rdIpv4MaskLength,
      ipv6rdBorderRelay: ipv6.ipv6rdBorderRelay,
    );
  }

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
