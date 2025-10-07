import 'package:equatable/equatable.dart';

// http://linksys.com/jnap/router/GetEthernetPortConnections2
class DualWANEthernetPortConnections extends Equatable {
  /// The current state of the primary WAN Ethernet port.
  final String primaryWANPortConnection;

  /// The current state of the secondary WAN Ethernet port.
  final String secondaryWANPortConnection;

  /// The current state of the LAN Ethernet ports.
  final List<String> lanPortConnections;

  const DualWANEthernetPortConnections({
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

  factory DualWANEthernetPortConnections.fromMap(Map<String, dynamic> map) {
    return DualWANEthernetPortConnections(
      primaryWANPortConnection: map['primaryWANPortConnection'] as String,
      secondaryWANPortConnection: map['secondaryWANPortConnection'] as String,
      lanPortConnections: (map['lanPortConnections'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryWANPortConnection': primaryWANPortConnection,
      'secondaryWANPortConnection': secondaryWANPortConnection,
      'lanPortConnections': 
          lanPortConnections,
    };
  }

  factory DualWANEthernetPortConnections.fromJson(Map<String, dynamic> json) => 
      DualWANEthernetPortConnections.fromMap(json);
  
  Map<String, dynamic> toJson() => toMap();
}