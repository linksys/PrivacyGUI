// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';

class FirewallState extends Equatable {
  const FirewallState({
    required this.settings,
  });

  final FirewallSettings settings;


  FirewallState copyWith({
    FirewallSettings? settings,
  }) {
    return FirewallState(
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap(),
    };
  }

  factory FirewallState.fromMap(Map<String, dynamic> map) {
    return FirewallState(
      settings: FirewallSettings.fromMap(map['settings'] as Map<String,dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory FirewallState.fromJson(String source) => FirewallState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [settings];
}
