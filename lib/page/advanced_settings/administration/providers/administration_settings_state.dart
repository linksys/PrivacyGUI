import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/providers/feature_state.dart';

class AdministrationSettings extends Equatable {
  final ManagementSettings managementSettings;
  final bool enabledALG;
  final bool enabledExpressForwarfing;
  final bool isUPnPEnabled;
  final bool canUsersConfigure;
  final bool canUsersDisableWANAccess;
  final bool canDisAllowLocalMangementWirelessly;

  const AdministrationSettings({
    required this.managementSettings,
    required this.enabledALG,
    required this.enabledExpressForwarfing,
    required this.isUPnPEnabled,
    required this.canUsersConfigure,
    required this.canUsersDisableWANAccess,
    this.canDisAllowLocalMangementWirelessly = true,
  });

  @override
  List<Object> get props => [
        managementSettings,
        enabledALG,
        enabledExpressForwarfing,
        isUPnPEnabled,
        canUsersConfigure,
        canUsersDisableWANAccess,
        canDisAllowLocalMangementWirelessly,
      ];

  AdministrationSettings copyWith({
    ManagementSettings? managementSettings,
    bool? enabledALG,
    bool? enabledExpressForwarfing,
    bool? isUPnPEnabled,
    bool? canUsersConfigure,
    bool? canUsersDisableWANAccess,
    bool? canDisAllowLocalMangementWirelessly,
  }) {
    return AdministrationSettings(
      managementSettings: managementSettings ?? this.managementSettings,
      enabledALG: enabledALG ?? this.enabledALG,
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
    return {
      'managementSettings': managementSettings.toMap(),
      'enabledALG': enabledALG,
      'enabledExpressForwarfing': enabledExpressForwarfing,
      'isUPnPEnabled': isUPnPEnabled,
      'canUsersConfigure': canUsersConfigure,
      'canUsersDisableWANAccess': canUsersDisableWANAccess,
      'canDisAllowLocalMangementWirelessly': canDisAllowLocalMangementWirelessly,
    };
  }
}

class AdministrationStatus extends Equatable {
  final bool isExpressForwardingSupported;

  const AdministrationStatus({required this.isExpressForwardingSupported});

  @override
  List<Object> get props => [isExpressForwardingSupported];

  Map<String, dynamic> toMap() {
    return {
      'isExpressForwardingSupported': isExpressForwardingSupported,
    };
  }
}

class AdministrationSettingsState
    extends FeatureState<AdministrationSettings, AdministrationStatus> {
  const AdministrationSettingsState({
    required super.settings,
    required super.status,
  });

  @override
  AdministrationSettingsState copyWith({
    AdministrationSettings? settings,
    AdministrationStatus? status,
  }) {
    return AdministrationSettingsState(
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
