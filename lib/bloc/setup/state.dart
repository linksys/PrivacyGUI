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
  wifiInterrupted,
  wifiConnectionBackFailed,
  wifiConnectionBackSuccess,
  finish,
}

class SetupState extends Equatable {
  final SetupResumePoint resumePoint;
  final String wifiSSID;
  final String wifiPassword;
  final String adminPassword;
  final String passwordHint;
  final String networkId;
  final AccountInfo? accountInfo;

  const SetupState({
    required this.resumePoint,
    required this.wifiSSID,
    required this.wifiPassword,
    required this.adminPassword,
    required this.networkId,
    this.passwordHint = '',
    required this.accountInfo,
  });

  const SetupState.init()
      : resumePoint = SetupResumePoint.none,
        wifiSSID = '',
        wifiPassword = '',
        adminPassword = '',
        networkId = '',
        passwordHint = '',
        accountInfo = null;

  SetupState copyWith({
    SetupResumePoint? resumePoint,
    String? wifiSSID,
    String? wifiPassword,
    String? adminPassword,
    String? networkId,
    String? passwordHint,
    AccountInfo? accountInfo,
  }) {
    return SetupState(
      resumePoint: resumePoint ?? this.resumePoint,
      wifiSSID: wifiSSID ?? this.wifiSSID,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      adminPassword: adminPassword ?? this.adminPassword,
      networkId: networkId ?? this.networkId,
      passwordHint: passwordHint ?? this.passwordHint,
      accountInfo: accountInfo ?? this.accountInfo,
    );
  }

  @override
  List<Object?> get props => [
        resumePoint,
        networkId,
        wifiSSID,
        wifiPassword,
        adminPassword,
        passwordHint,
        accountInfo,
      ];
}
