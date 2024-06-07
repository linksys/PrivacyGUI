// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class RouterEthernetPortConnections extends Equatable {
  final String wanPortConnection;
  final List<String> lanPortConnections;
  const RouterEthernetPortConnections({
    required this.wanPortConnection,
    required this.lanPortConnections,
  });

  RouterEthernetPortConnections copyWith({
    String? wanPortConnection,
    List<String>? lanPortConnections,
  }) {
    return RouterEthernetPortConnections(
      wanPortConnection: wanPortConnection ?? this.wanPortConnection,
      lanPortConnections: lanPortConnections ?? this.lanPortConnections,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'wanPortConnection': wanPortConnection,
      'lanPortConnections': lanPortConnections,
    };
  }

  factory RouterEthernetPortConnections.fromMap(Map<String, dynamic> map) {
    return RouterEthernetPortConnections(
      wanPortConnection: map['wanPortConnection'] as String,
      lanPortConnections: List<String>.from(
        (map['lanPortConnections'] as List<String>),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory RouterEthernetPortConnections.fromJson(String source) =>
      RouterEthernetPortConnections.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [wanPortConnection, lanPortConnections];
}
