// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class AdministrationSettings extends Equatable {
  final ManagementSettings managementSettings;
  final bool enabledALG;
  final bool isExpressForwardingSupported;
  final bool enabledExpressForwarfing;
  final bool isUPnPEnabled;
  final bool canUsersConfigure;
  final bool canUsersDisableWANAccess;
  final bool canDisAllowLocalMangementWirelessly;

  const AdministrationSettings({
    required this.managementSettings,
    required this.enabledALG,
    required this.isExpressForwardingSupported,
    required this.enabledExpressForwarfing,
    required this.isUPnPEnabled,
    required this.canUsersConfigure,
    required this.canUsersDisableWANAccess,
    this.canDisAllowLocalMangementWirelessly = true,
  });

  @override
  List<Object?> get props => [
        managementSettings,
        enabledALG,
        isExpressForwardingSupported,
        enabledExpressForwarfing,
        isUPnPEnabled,
        canUsersConfigure,
        canUsersDisableWANAccess,
        canDisAllowLocalMangementWirelessly,
      ];

  AdministrationSettings copyWith({
    ManagementSettings? managementSettings,
    bool? enabledALG,
    bool? isExpressForwardingSupported,
    bool? enabledExpressForwarfing,
    bool? isUPnPEnabled,
    bool? canUsersConfigure,
    bool? canUsersDisableWANAccess,
    bool? canDisAllowLocalMangementWirelessly,
  }) {
    return AdministrationSettings(
      managementSettings: managementSettings ?? this.managementSettings,
      enabledALG: enabledALG ?? this.enabledALG,
      isExpressForwardingSupported:
          isExpressForwardingSupported ?? this.isExpressForwardingSupported,
      enabledExpressForwarfing:
          enabledExpressForwarfing ?? this.enabledExpressForwarfing,
      isUPnPEnabled: isUPnPEnabled ?? this.isUPnPEnabled,
      canUsersConfigure: canUsersConfigure ?? this.canUsersConfigure,
      canUsersDisableWANAccess:
          canUsersDisableWANAccess ?? this.canUsersDisableWANAccess,
      canDisAllowLocalMangementWirelessly:
          canDisAllowLocalMangementWirelessly ??
              this.canDisAllowLocalMangementWirelessly,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'managementSettings': managementSettings.toMap(),
      'enabledALG': enabledALG,
      'isExpressForwardingSupported': isExpressForwardingSupported,
      'enabledExpressForwarfing': enabledExpressForwarfing,
      'isUPnPEnabled': isUPnPEnabled,
      'canUsersConfigure': canUsersConfigure,
      'canUsersDisableWANAccess': canUsersDisableWANAccess,
      'canDisAllowLocalMangementWirelessly': canDisAllowLocalMangementWirelessly,
    };
  }

  factory AdministrationSettings.fromMap(Map<String, dynamic> map) {
    return AdministrationSettings(
      managementSettings: ManagementSettings.fromMap(
          map['managementSettings'] as Map<String, dynamic>),
      enabledALG: map['enabledALG'] as bool,
      isExpressForwardingSupported: map['isExpressForwardingSupported'] as bool,
      enabledExpressForwarfing: map['enabledExpressForwarfing'] as bool,
      isUPnPEnabled: map['isUPnPEnabled'] as bool,
      canUsersConfigure: map['canUsersConfigure'] as bool,
      canUsersDisableWANAccess: map['canUsersDisableWANAccess'] as bool,
      canDisAllowLocalMangementWirelessly:
          map['canDisAllowLocalMangementWirelessly'] as bool? ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory AdministrationSettings.fromJson(String source) =>
      AdministrationSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}

class AdministrationStatus extends Equatable {
  const AdministrationStatus();

  @override
  List<Object?> get props => [];

  AdministrationStatus copyWith() {
    return const AdministrationStatus();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{};
  }

  factory AdministrationStatus.fromMap(Map<String, dynamic> map) {
    return const AdministrationStatus();
  }

  String toJson() => json.encode(toMap());

  factory AdministrationStatus.fromJson(String source) =>
      AdministrationStatus.fromMap(json.decode(source) as Map<String, dynamic>);
}

class AdministrationSettingsState extends FeatureState<
    AdministrationSettings,
    AdministrationStatus> {
  const AdministrationSettingsState({
    required super.settings,
    required super.status,
  });

  @override
  AdministrationSettingsState copyWith({
    Preservable<AdministrationSettings>? settings,
    AdministrationStatus? status,
  }) {
    return AdministrationSettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((s) => s.toMap()),
      'status': status.toMap(),
    };
  }

  factory AdministrationSettingsState.fromMap(Map<String, dynamic> map) {
    return AdministrationSettingsState(
      settings: Preservable.fromMap(
          map['settings'] as Map<String, dynamic>,
          (valueMap) => AdministrationSettings.fromMap(
              valueMap as Map<String, dynamic>)),
      status: AdministrationStatus.fromMap(
          map['status'] as Map<String, dynamic>),
    );
  }

  factory AdministrationSettingsState.fromJson(String source) =>
      AdministrationSettingsState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [settings, status];
  }
}

