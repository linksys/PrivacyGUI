// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/firewall_settings.dart' as model;
import 'package:privacy_gui/providers/feature_state.dart';

class FirewallSettings extends Equatable {
  final model.FirewallSettings settings;

  const FirewallSettings({required this.settings});

  @override
  List<Object> get props => [settings];

  FirewallSettings copyWith({
    model.FirewallSettings? settings,
  }) {
    return FirewallSettings(
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap(),
    };
  }
}

class FirewallStatus extends Equatable {
  const FirewallStatus();

  @override
  List<Object> get props => [];

  Map<String, dynamic> toMap() {
    return {};
  }
}

class FirewallState extends FeatureState<FirewallSettings, FirewallStatus> {
  const FirewallState({
    required super.settings,
    required super.status,
  });

  @override
  FirewallState copyWith({
    FirewallSettings? settings,
    FirewallStatus? status,
  }) {
    return FirewallState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'settings': settings.toMap(),
      'status': status.toMap(),
    };
  }
}
