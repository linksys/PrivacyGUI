import 'dart:async';

import 'package:moab_poc/repository/authenticate/auth_repository.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepository extends AuthRepository {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Timer? _resendCodeTimer;
  int _resendCountdown = 0;

  final waitDuration = const Duration(seconds: 3);

  @override
  Future<void> addPhoneNumber(String phone) async {
    await Future.delayed(waitDuration);
  }

  @override
  Future<DummyModel> createAccount(String username) async {
    await Future.delayed(waitDuration);
    return {};
  }

  @override
  Future<void> forgotPassword() async {
    await Future.delayed(waitDuration);
  }

  @override
  Future<DummyModel> login(String username, String password) async {
    await Future.delayed(waitDuration);
    if (password == 'email') {
      return {
        'method': [
          {'email': username},
        ]
      };
    } else if (password == 'emailandphone') {
      return {
        'method': [
          {'sms': '+8869123456'},
          {'email': username},
        ]
      };
    }
    throw CloudException('INCORRECT_PASSWORD', "Incorrect password");
  }

  @override
  Future<void> loginChallenge(int method) async {
    await Future.delayed(waitDuration);
  }

  @override
  Future<DummyModel> passwordLessLogin(String username, String method) async {
    await Future.delayed(waitDuration);
    return {'token': 'DUMMY_PASSWORDLESS_TOKEN'};
  }

  @override
  Future<void> resendPasswordLessCode(String token, String method) async {
    await Future.delayed(waitDuration);
    if (_resendCodeTimer != null && (_resendCodeTimer!.isActive)) {
      throw CloudException(
          'RESEND_CODE_TIMER', 'A new code can be sent in 0:$_resendCountdown');
    } else {
      _resendCodeTimer = _createResendCodeTimer();
      return;
    }
  }

  @override
  Future<DummyModel> resetPassword(String password) async {
    await Future.delayed(waitDuration);
    if (password == 'Linksys123!') {
      return {};
    }
    throw CloudException('OLD_PASSWORD', "You cannot use an old password.");
  }

  @override
  Future<DummyModel> testUsername(String username) async {
    await Future.delayed(waitDuration);
    if (username.endsWith('linksys.com')) {
      return {
        'type': 'otp',
        'method': [
          {'sms': '+8869123456'},
          {'email': username}
        ]
      };
    } else if(username.endsWith('belkin.com')) {
      return {
        'type': 'password',
        'method': [
          {'sms': '+8869123456'},
          {'email': username}
        ]
      };
    }
    throw CloudException('NOT_FOUND', "Can't find account $username");
  }

  @override
  Future<DummyModel> validateChallenge(String code) async {
    await Future.delayed(waitDuration);
    return {};
  }

  @override
  Future<DummyModel> validatePasswordLessCode(String token, String code) async {
    await Future.delayed(waitDuration);
    if (code == '1111') {
      throw CloudException('OTP_INVALID_TOO_MANY_TIMES',
          "You've enter an incorrect code too many times. Resend a code to continue.");
    }
    return {};
  }

  Timer _createResendCodeTimer() {
    _resendCountdown = 60;
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      _resendCountdown--;
      if (_resendCountdown == 0 && (_resendCodeTimer?.isActive ?? false)) {
        _resendCodeTimer?.cancel();
        _resendCodeTimer = null;
      }
    });
  }
}
