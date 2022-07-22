import 'dart:async';

import 'package:moab_poc/network/http/model/cloud_account_info.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
import 'package:moab_poc/network/http/model/cloud_login_certs.dart';
import 'package:moab_poc/network/http/model/cloud_login_state.dart';
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
    if (password == 'Showmeerror123!') {
      throw CloudException('INCORRECT_PASSWORD', "Incorrect password");
    } else {
      return {
        'method': [
          {'sms': '+8869123456'},
          {'email': username},
        ]
      };
    }
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
    if (password == 'Showmeerror123!') {
      throw CloudException('OLD_PASSWORD', "You cannot use an old password.");
    }
    return {};
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

  @override
  Future<void> authChallenge(AuthChallengeMethod method) {
    // TODO: implement authChallenge
    throw UnimplementedError();
  }

  @override
  Future<void> authChallengeVerify(String token, String code) {
    // TODO: implement authChallengeVerify
    throw UnimplementedError();
  }

  @override
  Future<String> createAccountPreparation(String email) {
    // TODO: implement createAccountPreparation
    throw UnimplementedError();
  }

  @override
  Future<void> createAccountPreparationUpdateMethod(String token, CommunicationMethod method) {
    // TODO: implement createAccountPreparationUpdateMethod
    throw UnimplementedError();
  }

  @override
  Future<CloudAccountInfo> createVerifiedAccount(CreateAccountVerified verified) {
    // TODO: implement createVerifiedAccount
    throw UnimplementedError();
  }

  @override
  Future<List<CommunicationMethod>> getMaskedCommunicationMethods(String username) {
    // TODO: implement getMaskedCommunicationMethods
    throw UnimplementedError();
  }

  @override
  Future<CloudLoginState> login2(String token) {
    // TODO: implement login2
    throw UnimplementedError();
  }

  @override
  Future<CloudLoginState> loginPassword(String token, String password) {
    // TODO: implement loginPassword
    throw UnimplementedError();
  }

  @override
  Future<CloudLoginState> loginPrepare(String username) {
    // TODO: implement loginPrepare
    throw UnimplementedError();
  }

  @override
  Future<void> downloadCloudCert(String taskId, {required token, required secret}) {
    // TODO: implement downloadCloudCert
    throw UnimplementedError();
  }
}
