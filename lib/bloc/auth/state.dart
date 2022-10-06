import 'package:equatable/equatable.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
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

enum LoginFrom { none, local, remote }

enum AuthenticationType { none, passwordless, password }

enum CommunicationMethodType { sms, email }

class AccountInfo {
  final String username;
  final String password;
  final AuthenticationType authenticationType;
  final List<CommunicationMethod> communicationMethods;
  final bool enableBiometrics;

  const AccountInfo(
      {required this.username,
      required this.authenticationType,
      required this.communicationMethods,
      this.password = '',
      this.enableBiometrics = false});

  factory AccountInfo.empty() {
    return const AccountInfo(
        username: '', authenticationType: AuthenticationType.none, communicationMethods: []);
  }

  AccountInfo copyWith({
    String? username,
    String? password,
    AuthenticationType? authenticationType,
    List<CommunicationMethod>? communicationMethods,
    bool? enableBiometrics,
  }) {
    return AccountInfo(
      username: username ?? this.username,
      password: password ?? this.password,
      authenticationType: authenticationType ?? this.authenticationType,
      communicationMethods: communicationMethods ?? this.communicationMethods,
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

@Deprecated('Please use CommunicationMethod')
class OtpInfo {
  final CommunicationMethodType method;
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
    CommunicationMethodType? method,
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

  factory AuthState.authorized() {
    return const AuthCloudLoginState();
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
      : super(status: AuthStatus.authorized);
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
