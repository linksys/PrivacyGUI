import 'package:equatable/equatable.dart';
import 'package:linksys_moab/bloc/auth/state.dart';

enum SetupResumePoint {
  none,
  internetCheck,
  location,
  setSSID,
  addChildNode,
  routerPassword,
  createCloudAccount,
  waiting,
  finish,
}

class SetupState extends Equatable {
  final SetupResumePoint resumePoint;
  final String wifiSSID;
  final String wifiPassword;
  final String adminPassword;
  final String passwordHint;
  final AccountInfo? accountInfo;

  const SetupState({
    required this.resumePoint,
    required this.wifiSSID,
    required this.wifiPassword,
    required this.adminPassword,
    this.passwordHint = '',
    required this.accountInfo,
  });

  const SetupState.init()
      : resumePoint = SetupResumePoint.none,
        wifiSSID = '',
        wifiPassword = '',
        adminPassword = '',
        passwordHint = '',
        accountInfo = null;

  SetupState copyWith({
    SetupResumePoint? resumePoint,
    String? wifiSSID,
    String? wifiPassword,
    String? adminPassword,
    String? passwordHint,
    AccountInfo? accountInfo,
  }) {
    return SetupState(
      resumePoint: resumePoint ?? this.resumePoint,
      wifiSSID: wifiSSID ?? this.wifiSSID,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      adminPassword: adminPassword ?? this.adminPassword,
      passwordHint: passwordHint ?? this.passwordHint,
      accountInfo: accountInfo ?? this.accountInfo,
    );
  }

  @override
  List<Object?> get props => [
        resumePoint,
        wifiSSID,
        wifiPassword,
        adminPassword,
        passwordHint,
        accountInfo
      ];
}
