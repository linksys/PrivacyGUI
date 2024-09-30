// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class WanExternal extends Equatable {
  final String? publicWanIPv4;
  final String? publicWanIPv6;
  final String? privateWanIPv4;
  final String? privateWanIPv6;

  const WanExternal({
    this.publicWanIPv4,
    this.publicWanIPv6,
    this.privateWanIPv4,
    this.privateWanIPv6,
  });

  WanExternal copyWith({
    String? publicWanIPv4,
    String? publicWanIPv6,
    String? privateWanIPv4,
    String? privateWanIPv6,
  }) {
    return WanExternal(
      publicWanIPv4: publicWanIPv4 ?? this.publicWanIPv4,
      publicWanIPv6: publicWanIPv6 ?? this.publicWanIPv6,
      privateWanIPv4: privateWanIPv4 ?? this.privateWanIPv4,
      privateWanIPv6: privateWanIPv6 ?? this.privateWanIPv6,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'PublicWanIPv4': publicWanIPv4,
      'PublicWanIPv6': publicWanIPv6,
      'PrivateWanIPv4': privateWanIPv4,
      'PrivateWanIPv6': privateWanIPv6,
    };
  }

  factory WanExternal.fromMap(Map<String, dynamic> map) {
    return WanExternal(
      publicWanIPv4:
          map['PublicWanIPv4'] != null ? map['PublicWanIPv4'] as String : null,
      publicWanIPv6:
          map['PublicWanIPv6'] != null ? map['PublicWanIPv6'] as String : null,
      privateWanIPv4: map['PrivateWanIPv4'] != null
          ? map['PrivateWanIPv4'] as String
          : null,
      privateWanIPv6: map['PrivateWanIPv6'] != null
          ? map['PrivateWanIPv6'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WanExternal.fromJson(String source) =>
      WanExternal.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
        publicWanIPv4,
        publicWanIPv6,
        privateWanIPv4,
        privateWanIPv6,
      ];
}
