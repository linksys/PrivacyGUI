// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class UPnPSettings extends Equatable {
  final bool isUPnPEnabled;
  final bool canUsersConfigure;
  final bool canUsersDisableWANAccess;
  const UPnPSettings({
    required this.isUPnPEnabled,
    required this.canUsersConfigure,
    required this.canUsersDisableWANAccess,
  });

  UPnPSettings copyWith({
    bool? isUPnPEnabled,
    bool? canUsersConfigure,
    bool? canUsersDisableWANAccess,
  }) {
    return UPnPSettings(
      isUPnPEnabled: isUPnPEnabled ?? this.isUPnPEnabled,
      canUsersConfigure: canUsersConfigure ?? this.canUsersConfigure,
      canUsersDisableWANAccess:
          canUsersDisableWANAccess ?? this.canUsersDisableWANAccess,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isUPnPEnabled': isUPnPEnabled,
      'canUsersConfigure': canUsersConfigure,
      'canUsersDisableWANAccess': canUsersDisableWANAccess,
    };
  }

  factory UPnPSettings.fromMap(Map<String, dynamic> map) {
    return UPnPSettings(
      isUPnPEnabled: map['isUPnPEnabled'] as bool,
      canUsersConfigure: map['canUsersConfigure'] as bool,
      canUsersDisableWANAccess: map['canUsersDisableWANAccess'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory UPnPSettings.fromJson(String source) =>
      UPnPSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props =>
      [isUPnPEnabled, canUsersConfigure, canUsersDisableWANAccess];
}
