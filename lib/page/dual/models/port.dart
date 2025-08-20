import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/dual/models/port_type.dart';

class DualWANPort extends Equatable {
  final PortType type;
  final int? portNumber;
  final String speed;

  const DualWANPort({
    required this.type,
    this.portNumber,
    required this.speed,
  });
  factory DualWANPort.fromMap(Map<String, dynamic> map) {
    return DualWANPort(
      type: PortType.fromValue(map['type']),
      portNumber: map['portNumber'],
      speed: map['speed'],
    );
  }

  DualWANPort copyWith({
    PortType? type,
    int? portNumber,
    String? speed,
  }) {
    return DualWANPort(
      type: type ?? this.type,
      portNumber: portNumber ?? this.portNumber,
      speed: speed ?? this.speed,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.toValue(),
      'portNumber': portNumber,
      'speed': speed,
    }..removeWhere((key, value) => value == null);
  }

  String toJson() => json.encode(toMap());

  factory DualWANPort.fromJson(String source) => DualWANPort.fromMap(json.decode(source) as Map<String, dynamic>);
  @override
  List<Object?> get props => [type, portNumber, speed];
}
  