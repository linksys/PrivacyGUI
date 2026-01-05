import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/wan_external.dart';

/// UI model for WAN external IP information.
///
/// Isolates the presentation layer from JNAP data models.
/// Contains public and private WAN IPv4/IPv6 addresses.
class WanExternalUIModel extends Equatable {
  final String? publicWanIPv4;
  final String? publicWanIPv6;
  final String? privateWanIPv4;
  final String? privateWanIPv6;

  const WanExternalUIModel({
    this.publicWanIPv4,
    this.publicWanIPv6,
    this.privateWanIPv4,
    this.privateWanIPv6,
  });

  /// Creates a UI model from JNAP WanExternal model.
  factory WanExternalUIModel.fromJnap(WanExternal jnap) {
    return WanExternalUIModel(
      publicWanIPv4: jnap.publicWanIPv4,
      publicWanIPv6: jnap.publicWanIPv6,
      privateWanIPv4: jnap.privateWanIPv4,
      privateWanIPv6: jnap.privateWanIPv6,
    );
  }

  WanExternalUIModel copyWith({
    String? publicWanIPv4,
    String? publicWanIPv6,
    String? privateWanIPv4,
    String? privateWanIPv6,
  }) {
    return WanExternalUIModel(
      publicWanIPv4: publicWanIPv4 ?? this.publicWanIPv4,
      publicWanIPv6: publicWanIPv6 ?? this.publicWanIPv6,
      privateWanIPv4: privateWanIPv4 ?? this.privateWanIPv4,
      privateWanIPv6: privateWanIPv6 ?? this.privateWanIPv6,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'publicWanIPv4': publicWanIPv4,
      'publicWanIPv6': publicWanIPv6,
      'privateWanIPv4': privateWanIPv4,
      'privateWanIPv6': privateWanIPv6,
    };
  }

  factory WanExternalUIModel.fromMap(Map<String, dynamic> map) {
    return WanExternalUIModel(
      publicWanIPv4: map['publicWanIPv4'] as String?,
      publicWanIPv6: map['publicWanIPv6'] as String?,
      privateWanIPv4: map['privateWanIPv4'] as String?,
      privateWanIPv6: map['privateWanIPv6'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory WanExternalUIModel.fromJson(String source) =>
      WanExternalUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        publicWanIPv4,
        publicWanIPv6,
        privateWanIPv4,
        privateWanIPv6,
      ];
}
