import 'package:equatable/equatable.dart';
import 'package:linksys_moab/bloc/auth/state.dart';

enum SetupResumePoint {
  NONE,
  INTERNETCHECK,
  LOCATION,
  SETSSID,
  ADDCHILDNODE,
  ROUTERPASSWORD,
  CREATECLOUDACCOUNT,
}

class SetupState extends Equatable {
  final SetupResumePoint resumePoint;
  final String wifiSSID;
  final String wifiPassword;
  final String adminPassword;
  final AccountInfo? accountInfo;

  const SetupState(
      {required this.resumePoint,
      required this.wifiSSID,
      required this.wifiPassword,
      required this.adminPassword,
      required this.accountInfo});

  const SetupState.init()
      : resumePoint = SetupResumePoint.NONE,
        wifiSSID = '',
        wifiPassword = '',
        adminPassword = '',
        accountInfo = null;

  SetupState copyWith({
    SetupResumePoint? resumePoint,
    String? wifiSSID,
    String? wifiPassword,
    String? adminPassword,
    AccountInfo? accountInfo,
  }) {
    return SetupState(
      resumePoint: resumePoint ?? this.resumePoint,
      wifiSSID: wifiSSID ?? this.wifiSSID,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      adminPassword: adminPassword ?? this.adminPassword,
      accountInfo: accountInfo ?? this.accountInfo,
    );
  }

  @override
  List<Object?> get props =>
      [resumePoint, wifiSSID, wifiPassword, adminPassword, accountInfo];
}
