import 'package:equatable/equatable.dart';

// http://linksys.com/jnap/router/EthernetPortConnection
enum EthernetPortConnectionData {
  none('None'),
  tenMbps('10Mbps'),
  hundredMbps('100Mbps'),
  oneGbps('1Gbps'),
  twoPointFiveGbps('2.5Gbps'),
  fiveGbps('5Gbps'),
  tenGbps('10Gbps');

  final String value;
  const EthernetPortConnectionData(this.value);

  static EthernetPortConnectionData fromJson(String json) =>
      values.firstWhere((e) => e.value == json);

  String toJson() => value;
}

// http://linksys.com/jnap/router/GetDualWANEthernetPortConnections
class RouterDualWANEthernetPortConnections extends Equatable {
  /// The current state of the primary WAN Ethernet port
  final EthernetPortConnectionData primaryWANPortConnection;

  /// The current state of the secondary WAN Ethernet port
  final EthernetPortConnectionData secondaryWANPortConnection;

  /// The current state of the LAN Ethernet ports
  final List<EthernetPortConnectionData> lanPortConnections;

  const RouterDualWANEthernetPortConnections({
    required this.primaryWANPortConnection,
    required this.secondaryWANPortConnection,
    required this.lanPortConnections,
  });

  @override
  List<Object?> get props => [
        primaryWANPortConnection,
        secondaryWANPortConnection,
        lanPortConnections,
      ];

  factory RouterDualWANEthernetPortConnections.fromMap(Map<String, dynamic> map) {
    return RouterDualWANEthernetPortConnections(
      primaryWANPortConnection:
          EthernetPortConnectionData.fromJson(map['primaryWANPortConnection'] as String),
      secondaryWANPortConnection:
          EthernetPortConnectionData.fromJson(map['secondaryWANPortConnection'] as String),
      lanPortConnections: (map['lanPortConnections'] as List<dynamic>)
          .map((e) => EthernetPortConnectionData.fromJson(e as String))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryWANPortConnection': primaryWANPortConnection.toJson(),
      'secondaryWANPortConnection': secondaryWANPortConnection.toJson(),
      'lanPortConnections': lanPortConnections.map((e) => e.toJson()).toList(),
    };
  }

  factory RouterDualWANEthernetPortConnections.fromJson(Map<String, dynamic> json) =>
      RouterDualWANEthernetPortConnections.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}
