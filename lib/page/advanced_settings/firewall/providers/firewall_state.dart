import 'dart:convert';

import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';
import 'package:privacy_gui/providers/empty_status.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class FirewallState extends FeatureState<FirewallSettings, EmptyStatus> {
  const FirewallState({
    required super.settings,
    required super.status,
  });

  @override
  FirewallState copyWith({
    Preservable<FirewallSettings>? settings,
    EmptyStatus? status,
  }) {
    return FirewallState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((s) => s.toMap()),
      'status': {},
    };
  }

  factory FirewallState.fromMap(Map<String, dynamic> map) {
    return FirewallState(
      settings: Preservable.fromMap(
        map['settings'] as Map<String, dynamic>,
        (valueMap) =>
            FirewallSettings.fromMap(valueMap as Map<String, dynamic>),
      ),
      status: const EmptyStatus(),
    );
  }

  factory FirewallState.fromJson(String source) =>
      FirewallState.fromMap(json.decode(source) as Map<String, dynamic>);
}
