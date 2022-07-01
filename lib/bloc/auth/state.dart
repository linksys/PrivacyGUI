import 'package:equatable/equatable.dart';

enum AuthStatus { unknownAuth, unAuthorized, authorized }

enum AuthMethod { none, local, remote }

enum RemoteLoginMethod { none, password, passwordLess }

enum LoginType { otp, password}

enum OtpMethod {
  sms, email
}

class AccountInfo {
  final LoginType loginType;
  final List<OtpInfo> otpInfo;

  const AccountInfo({required this.loginType, required this.otpInfo});
}

class OtpInfo {
  final OtpMethod method;
  final String data;
  const OtpInfo({required this.method, required this.data});

}

class AdminPasswordInfo {
  final bool hasAdminPassword;
  final String hint;
  const AdminPasswordInfo({required this.hasAdminPassword, required this.hint});
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthMethod method;
  final RemoteLoginMethod remoteLoginMethod;
  final String username;
  final String password;
  final List<OtpInfo>? otpSupported;
  final String otpCode;
  final OtpMethod otpMethod;
  final String otpTarget;

  // token? cert?

  const AuthState({
    required this.status,
    this.method = AuthMethod.none,
    this.remoteLoginMethod = RemoteLoginMethod.none,
    this.username = '',
    this.password = '',
    this.otpCode = '',
    this.otpMethod = OtpMethod.email,
    this.otpTarget = '',
    this.otpSupported,
  });

  factory AuthState.unknownAuth() {
    return const AuthState(status: AuthStatus.unknownAuth);
  }

  factory AuthState.unAuthorized() {
    return const AuthState(status: AuthStatus.unAuthorized);
  }

  factory AuthState.authorized(
      {required AuthMethod method,
      RemoteLoginMethod remoteLoginMethod = RemoteLoginMethod.none}) {
    return AuthState(
        status: AuthStatus.authorized,
        method: method,
        remoteLoginMethod: remoteLoginMethod);
  }

  @override
  List<Object?> get props => [status, method, remoteLoginMethod, username, password, otpCode, otpMethod, otpTarget, otpSupported];

  AuthState copyWith({
    AuthStatus? status,
    AuthMethod? method,
    RemoteLoginMethod? remoteLoginMethod,
    String? username,
    String? password,
    String? otpCode,
    OtpMethod? otpMethod,
    String? otpTarget,
    List<OtpInfo>? otpSupported,
  }) {
    return AuthState(
      status: status ?? this.status,
      method: method ?? this.method,
      remoteLoginMethod: remoteLoginMethod ?? this.remoteLoginMethod,
      username: username ?? this.username,
      password: password ?? this.password,
      otpCode: otpCode ?? this.otpCode,
      otpMethod: otpMethod ?? this.otpMethod,
      otpTarget: otpTarget ?? this.otpTarget,
      otpSupported:  otpSupported ?? this.otpSupported,
    );
  }
}
