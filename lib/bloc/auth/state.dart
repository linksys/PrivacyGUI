import 'package:equatable/equatable.dart';
import 'package:linksys_moab/network/http/model/cloud_phone.dart';

enum AuthStatus {
  unknownAuth,
  unAuthorized,
  authorized,
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

  const AccountInfo(
      {required this.username,
      required this.loginType,
      required this.otpInfo,
      this.password = ''});

  factory AccountInfo.empty() {
    return const AccountInfo(
        username: '', loginType: LoginType.none, otpInfo: []);
  }

  AccountInfo copyWith({
    String? username,
    String? password,
    LoginType? loginType,
    List<OtpInfo>? otpInfo,
  }) {
    return AccountInfo(
      username: username ?? this.username,
      password: password ?? this.password,
      loginType: loginType ?? this.loginType,
      otpInfo: otpInfo ?? this.otpInfo,
    );
  }
}

class LocalLoginInfo {
  final String routerPassword;
  final String routerPasswordHint;

  const LocalLoginInfo({
    required this.routerPassword,
    this.routerPasswordHint = '',
  });

  LocalLoginInfo copyWith({
    String? routerPassword,
    String? routerPasswordHint,
  }) {
    return LocalLoginInfo(
      routerPassword: routerPassword ?? this.routerPassword,
      routerPasswordHint: routerPasswordHint ?? this.routerPasswordHint,
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

  factory AuthState.authorized(
      {required AccountInfo accountInfo,
      required String publicKey,
      required String privateKey,
      }) {
    return AuthCloudLoginState(
        accountInfo: accountInfo, publicKey: publicKey, privateKey: privateKey);
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
  const AuthCloudLoginState(
      {required this.accountInfo,
      required this.publicKey,
      required this.privateKey})
      : super(status: AuthStatus.authorized);

  final AccountInfo accountInfo;
  final String publicKey;
  final String privateKey;
}

class AuthLocalLoginState extends AuthState {
  const AuthLocalLoginState({required this.localLoginInfo})
      : super(status: AuthStatus.authorized);

  final LocalLoginInfo localLoginInfo;
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
  const AuthOnLocalLoginState({required this.localLoginInfo})
      : super(status: AuthStatus.onLocalLogin);

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
