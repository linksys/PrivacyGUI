// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/management_settings.dart';

class AdministrationSettingsState extends Equatable {
  final ManagementSettings managementSettings;
  final bool enabledALG;
  final bool isExpressForwardingSupported;
  final bool enabledExpressForwarfing;
  final bool isUPnPEnabled;
  final bool canUsersConfigure;
  final bool canUsersDisableWANAccess;
  const AdministrationSettingsState({
    required this.managementSettings,
    required this.enabledALG,
    required this.isExpressForwardingSupported,
    required this.enabledExpressForwarfing,
    required this.isUPnPEnabled,
    required this.canUsersConfigure,
    required this.canUsersDisableWANAccess,
  });
  

  AdministrationSettingsState copyWith({
    ManagementSettings? managementSettings,
    bool? enabledALG,
    bool? isExpressForwardingSupported,
    bool? enabledExpressForwarfing,
    bool? isUPnPEnabled,
    bool? canUsersConfigure,
    bool? canUsersDisableWANAccess,
  }) {
    return AdministrationSettingsState(
      managementSettings: managementSettings ?? this.managementSettings,
      enabledALG: enabledALG ?? this.enabledALG,
      isExpressForwardingSupported: isExpressForwardingSupported ?? this.isExpressForwardingSupported,
      enabledExpressForwarfing: enabledExpressForwarfing ?? this.enabledExpressForwarfing,
      isUPnPEnabled: isUPnPEnabled ?? this.isUPnPEnabled,
      canUsersConfigure: canUsersConfigure ?? this.canUsersConfigure,
      canUsersDisableWANAccess: canUsersDisableWANAccess ?? this.canUsersDisableWANAccess,
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
    };
  }

  factory AdministrationSettingsState.fromMap(Map<String, dynamic> map) {
    return AdministrationSettingsState(
      managementSettings: ManagementSettings.fromMap(map['managementSettings'] as Map<String,dynamic>),
      enabledALG: map['enabledALG'] as bool,
      isExpressForwardingSupported: map['isExpressForwardingSupported'] as bool,
      enabledExpressForwarfing: map['enabledExpressForwarfing'] as bool,
      isUPnPEnabled: map['isUPnPEnabled'] as bool,
      canUsersConfigure: map['canUsersConfigure'] as bool,
      canUsersDisableWANAccess: map['canUsersDisableWANAccess'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory AdministrationSettingsState.fromJson(String source) => AdministrationSettingsState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      managementSettings,
      enabledALG,
      isExpressForwardingSupported,
      enabledExpressForwarfing,
      isUPnPEnabled,
      canUsersConfigure,
      canUsersDisableWANAccess,
    ];
  }
}
