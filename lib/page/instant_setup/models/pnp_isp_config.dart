import 'package:equatable/equatable.dart';

enum IspConnectionType { dhcp, pppoe, pppoeVlan, staticIp }

/// ISP/WAN configuration for the PnP troubleshooter flow.
class PnpIspConfig extends Equatable {
  final IspConnectionType type;

  // PPPoE
  final String pppUsername;
  final String pppPassword;

  // VLAN
  final bool vlanEnabled;
  final int vlanId;

  // Static IP
  final String staticIpAddress;
  final String subnetMask;
  final String defaultGateway;
  final String dnsServer1;
  final String dnsServer2;

  const PnpIspConfig({
    this.type = IspConnectionType.dhcp,
    this.pppUsername = '',
    this.pppPassword = '',
    this.vlanEnabled = false,
    this.vlanId = 0,
    this.staticIpAddress = '',
    this.subnetMask = '',
    this.defaultGateway = '',
    this.dnsServer1 = '',
    this.dnsServer2 = '',
  });

  PnpIspConfig copyWith({
    IspConnectionType? type,
    String? pppUsername,
    String? pppPassword,
    bool? vlanEnabled,
    int? vlanId,
    String? staticIpAddress,
    String? subnetMask,
    String? defaultGateway,
    String? dnsServer1,
    String? dnsServer2,
  }) {
    return PnpIspConfig(
      type: type ?? this.type,
      pppUsername: pppUsername ?? this.pppUsername,
      pppPassword: pppPassword ?? this.pppPassword,
      vlanEnabled: vlanEnabled ?? this.vlanEnabled,
      vlanId: vlanId ?? this.vlanId,
      staticIpAddress: staticIpAddress ?? this.staticIpAddress,
      subnetMask: subnetMask ?? this.subnetMask,
      defaultGateway: defaultGateway ?? this.defaultGateway,
      dnsServer1: dnsServer1 ?? this.dnsServer1,
      dnsServer2: dnsServer2 ?? this.dnsServer2,
    );
  }

  @override
  List<Object?> get props => [
        type,
        pppUsername,
        pppPassword,
        vlanEnabled,
        vlanId,
        staticIpAddress,
        subnetMask,
        defaultGateway,
        dnsServer1,
        dnsServer2,
      ];
}
