import 'package:equatable/equatable.dart';
import 'package:linksys_moab/network/http/model/cloud_phone.dart';

enum AuthStatus {
  unknownAuth,
  unAuthorized,
  cloudAuthorized,
  localAuthorized,
  pending,
  onCloudLogin,
  onLocalLogin,
  onCreateAccount,
}

enum AuthMethod { none, local, remote }

enum LoginType { none, passwordless, password }

enum OtpMethod { sms, email }

class AccountInfo {
  final String username;
  final String password;
  final LoginType loginType;
  final List<OtpInfo> otpInfo;
  final bool enableBiometrics;

  const AccountInfo(
      {required this.username,
      required this.loginType,
      required this.otpInfo,
      this.password = '',
      this.enableBiometrics = false});

  factory AccountInfo.empty() {
    return const AccountInfo(
        username: '', loginType: LoginType.none, otpInfo: []);
  }

  AccountInfo copyWith({
    String? username,
    String? password,
    LoginType? loginType,
    List<OtpInfo>? otpInfo,
    bool? enableBiometrics,
  }) {
    return AccountInfo(
      username: username ?? this.username,
      password: password ?? this.password,
      loginType: loginType ?? this.loginType,
      otpInfo: otpInfo ?? this.otpInfo,
      enableBiometrics: enableBiometrics ?? this.enableBiometrics,
    );
  }
}

class LocalLoginInfo {
  final String routerPassword;
  final String routerPasswordHint;
  final bool enableBiometrics;

  const LocalLoginInfo({
    required this.routerPassword,
    this.routerPasswordHint = '',
    this.enableBiometrics = false,
  });

  LocalLoginInfo copyWith({
    String? routerPassword,
    String? routerPasswordHint,
    bool? enableBiometrics,
  }) {
    return LocalLoginInfo(
      routerPassword: routerPassword ?? this.routerPassword,
      routerPasswordHint: routerPasswordHint ?? this.routerPasswordHint,
      enableBiometrics: enableBiometrics ?? this.enableBiometrics,
    );
  }
}

class OtpInfo {
  final OtpMethod method;
  final String methodId;
  final String data;
  final String maskedData;
  final CloudPhoneModel? phoneNumber;

  const OtpInfo({
    required this.method,
    this.methodId = '',
    this.data = '',
    this.maskedData = '',
    this.phoneNumber,
  });

  OtpInfo copyWith({
    OtpMethod? method,
    String? data,
    String? methodId,
    String? maskedData,
    CloudPhoneModel? phoneNumber,
  }) {
    return OtpInfo(
      method: method ?? this.method,
      data: data ?? this.data,
      methodId: methodId ?? this.methodId,
      maskedData: maskedData ?? this.maskedData,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class AdminPasswordInfo {
  final bool hasAdminPassword;
  final String hint;

  const AdminPasswordInfo({required this.hasAdminPassword, required this.hint});
}

class AuthState extends Equatable {
  final AuthStatus status;

  const AuthState({
    required this.status,
  });

  factory AuthState.unknownAuth() {
    return const AuthState(status: AuthStatus.unknownAuth);
  }

  factory AuthState.unAuthorized() {
    return const AuthState(status: AuthStatus.unAuthorized);
  }

  factory AuthState.cloudAuthorized() {
    return const AuthCloudLoginState();
  }

  factory AuthState.localAuthorized() {
    return const AuthLocalLoginState();
  }

  factory AuthState.onCloudLogin(
      {required AccountInfo accountInfo, required String vToken}) {
    return AuthOnCloudLoginState(accountInfo: accountInfo, vToken: vToken);
  }

  factory AuthState.onLocalLogin({required LocalLoginInfo localLoginInfo}) {
    return AuthOnLocalLoginState(localLoginInfo: localLoginInfo);
  }

  factory AuthState.onCreateAccount(
      {required AccountInfo accountInfo, required String vToken}) {
    return AuthOnCreateAccountState(accountInfo: accountInfo, vToken: vToken);
  }

  @override
  List<Object?> get props => [
        status,
      ];
}

class AuthCloudLoginState extends AuthState {
  const AuthCloudLoginState()
      : super(status: AuthStatus.cloudAuthorized);
}

class AuthLocalLoginState extends AuthState {
  const AuthLocalLoginState()
      : super(status: AuthStatus.localAuthorized);

}

class AuthOnCloudLoginState extends AuthState {
  const AuthOnCloudLoginState({required this.accountInfo, required this.vToken})
      : super(status: AuthStatus.onCloudLogin);

  final AccountInfo accountInfo;
  final String vToken;

  @override
  List<Object?> get props => [
        status,
        accountInfo,
        vToken,
      ];

  AuthOnCloudLoginState copyWith({
    AccountInfo? accountInfo,
    String? vToken,
  }) {
    return AuthOnCloudLoginState(
      accountInfo: accountInfo ?? this.accountInfo,
      vToken: vToken ?? this.vToken,
    );
  }
}

class AuthOnLocalLoginState extends AuthState {
  const AuthOnLocalLoginState({
    required this.localLoginInfo,
  }) : super(status: AuthStatus.onLocalLogin);

  final LocalLoginInfo localLoginInfo;

  @override
  List<Object?> get props => [
        status,
        localLoginInfo,
      ];

  AuthOnLocalLoginState copyWith({
    LocalLoginInfo? localLoginInfo,
  }) {
    return AuthOnLocalLoginState(
      localLoginInfo: localLoginInfo ?? this.localLoginInfo,
    );
  }
}

class AuthOnCreateAccountState extends AuthState {
  const AuthOnCreateAccountState(
      {required this.accountInfo, required this.vToken})
      : super(status: AuthStatus.onCreateAccount);

  final AccountInfo accountInfo;
  final String vToken;

  @override
  List<Object?> get props => [
        status,
        accountInfo,
        vToken,
      ];

  AuthOnCreateAccountState copyWith({
    AccountInfo? accountInfo,
    String? vToken,
  }) {
    return AuthOnCreateAccountState(
      accountInfo: accountInfo ?? this.accountInfo,
      vToken: vToken ?? this.vToken,
    );
  }
}
