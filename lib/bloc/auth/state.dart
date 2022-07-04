import 'package:equatable/equatable.dart';

enum AuthStatus { unknownAuth, unAuthorized, authorized }

enum AuthMethod { none, local, remote }

enum LoginType { otp, password }

enum OtpMethod { sms, email }

class AccountInfo {
  final String username;
  final LoginType loginType;
  final List<OtpInfo> otpInfo;

  const AccountInfo(
      {required this.username, required this.loginType, required this.otpInfo});
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
  final AccountInfo accountInfo;

  // token? cert?

  const AuthState({
    required this.status,
    this.method = AuthMethod.none,
    this.accountInfo =
        const AccountInfo(username: '', loginType: LoginType.otp, otpInfo: []),
  });

  factory AuthState.unknownAuth() {
    return const AuthState(status: AuthStatus.unknownAuth);
  }

  factory AuthState.unAuthorized() {
    return const AuthState(status: AuthStatus.unAuthorized);
  }

  factory AuthState.authorized({required AuthMethod method}) {
    return AuthState(status: AuthStatus.authorized, method: method);
  }

  @override
  List<Object?> get props => [
        status,
        method,
        accountInfo,
      ];

  AuthState copyWith({
    AuthStatus? status,
    AuthMethod? method,
    AccountInfo? accountInfo,
  }) {
    return AuthState(
      status: status ?? this.status,
      method: method ?? this.method,
      accountInfo: accountInfo ?? this.accountInfo,
    );
  }
}
