// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class ManagementSettings extends Equatable {
  final bool canManageUsingHTTP;
  final bool canManageUsingHTTPS;
  final bool isManageWirelesslySupported;
  final bool? canManageWirelessly;
  final bool canManageRemotely;
  const ManagementSettings({
    required this.canManageUsingHTTP,
    required this.canManageUsingHTTPS,
    required this.isManageWirelesslySupported,
    this.canManageWirelessly,
    required this.canManageRemotely,
  });

  ManagementSettings copyWith({
    bool? canManageUsingHTTP,
    bool? canManageUsingHTTPS,
    bool? isManageWirelesslySupported,
    bool? canManageWirelessly,
    bool? canManageRemotely,
  }) {
    return ManagementSettings(
      canManageUsingHTTP: canManageUsingHTTP ?? this.canManageUsingHTTP,
      canManageUsingHTTPS: canManageUsingHTTPS ?? this.canManageUsingHTTPS,
      isManageWirelesslySupported: isManageWirelesslySupported ?? this.isManageWirelesslySupported,
      canManageWirelessly: canManageWirelessly ?? this.canManageWirelessly,
      canManageRemotely: canManageRemotely ?? this.canManageRemotely,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'canManageUsingHTTP': canManageUsingHTTP,
      'canManageUsingHTTPS': canManageUsingHTTPS,
      'isManageWirelesslySupported': isManageWirelesslySupported,
      'canManageWirelessly': canManageWirelessly,
      'canManageRemotely': canManageRemotely,
    };
  }

  factory ManagementSettings.fromMap(Map<String, dynamic> map) {
    return ManagementSettings(
      canManageUsingHTTP: map['canManageUsingHTTP'] as bool,
      canManageUsingHTTPS: map['canManageUsingHTTPS'] as bool,
      isManageWirelesslySupported: map['isManageWirelesslySupported'] as bool,
      canManageWirelessly: map['canManageWirelessly'] != null ? map['canManageWirelessly'] as bool : null,
      canManageRemotely: map['canManageRemotely'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory ManagementSettings.fromJson(String source) => ManagementSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      canManageUsingHTTP,
      canManageUsingHTTPS,
      isManageWirelesslySupported,
      canManageWirelessly,
      canManageRemotely,
    ];
  }

    Map<String, dynamic> toSetSettingsMap() {
    return <String, dynamic>{
      'canManageUsingHTTP': canManageUsingHTTP,
      'canManageUsingHTTPS': canManageUsingHTTPS,
      'canManageWirelessly': canManageWirelessly ?? false,
      'canManageRemotely': canManageRemotely,
    };
  }
}
