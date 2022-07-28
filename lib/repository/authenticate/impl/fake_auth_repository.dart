import 'dart:async';

import 'package:moab_poc/network/http/model/base_response.dart';
import 'package:moab_poc/network/http/model/cloud_account_info.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
import 'package:moab_poc/network/http/model/cloud_login_certs.dart';
import 'package:moab_poc/network/http/model/cloud_login_state.dart';
import 'package:moab_poc/network/http/model/cloud_task_model.dart';
import 'package:moab_poc/repository/authenticate/auth_repository.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepository extends AuthRepository {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Timer? _resendCodeTimer;
  int _resendCountdown = 0;

  final waitDuration = const Duration(seconds: 3);

  @override
  Future<void> forgotPassword() async {
    await Future.delayed(waitDuration);
  }

  @override
  Future<DummyModel> resetPassword(String password) async {
    await Future.delayed(waitDuration);
    if (password == 'Showmeerror123!') {
      throw const ErrorResponse(
          code: 'OLD_PASSWORD',
          errorMessage: "You cannot use an old password.");
    }
    return {};
  }

  @override
  Future<void> authChallenge(AuthChallengeMethod method) async {
    // Send verification code to user

    if (_resendCodeTimer != null && (_resendCodeTimer!.isActive)) {
      throw ErrorResponse(
          code: 'RESEND_CODE_TIMER',
          errorMessage: 'A new code can be sent in 0:$_resendCountdown');
    } else {
      _resendCodeTimer = _createResendCodeTimer();
      return;
    }

    // When error happen
    // throw CloudException('RESOURCE_NOT_FOUND', 'errorMessage');
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
  Future<void> authChallengeVerify(String token, String code) async {
    await Future.delayed(waitDuration);

    if (code == '1111') {
      throw const ErrorResponse(
          code: 'OTP_INVALID_TOO_MANY_TIMES',
          errorMessage:
              "You've enter an incorrect code too many times. Resend a code to continue.");
    }

    // When error happen
    // throw CloudException('RESOURCE_NOT_FOUND', 'errorMessage');
  }

  @override
  Future<String> createAccountPreparation(String email) async {
    await Future.delayed(waitDuration);
    return 'some-token-that-is-unique-to-this-request';
  }

  @override
  Future<void> createAccountPreparationUpdateMethod(
      String token, CommunicationMethod method) async {
    await Future.delayed(waitDuration);
  }

  @override
  Future<CloudAccountInfo> createVerifiedAccount(
      CreateAccountVerified verified) async {
    await Future.delayed(waitDuration);

    return CloudAccountInfo.fromJson(const {
      "id": "82248d9d-50a7-4e35-822c-e07ed02d8063",
      "username": "austin.chang@linksys.com",
      "usernames": ["austin.chang@linksys.com"],
      "status": "ACTIVE",
      "type": "NORMAL",
      "authenticationMode": "PASSWORD",
      "createdAt": "2022-07-13T09:37:01.665063052Z",
      "updatedAt": "2022-07-13T09:37:01.665063052Z"
    });
  }

  @override
  Future<List<CommunicationMethod>> getMaskedCommunicationMethods(
      String username) async {
    await Future.delayed(waitDuration);

    String maskedUsername = username.replaceRange(1, 3, '***');
    List<CommunicationMethod> list = [
      const CommunicationMethod(method: 'SMS', targetValue: '+8869123456'),
      CommunicationMethod(method: 'EMAIL', targetValue: maskedUsername)
    ];

    if (username.endsWith('error.com')) {
      throw ErrorResponse(
          code: 'NOT_FOUND', errorMessage: "Can't find account $username");
    } else {
      return list;
    }
  }

  @override
  Future<CloudLoginAcceptState> login(String token) async {
    await Future.delayed(waitDuration);

    return const CloudLoginAcceptState(
        state: 'ACCEPT',
        data: CloudLoginAcceptData(
            taskId: 'taskId', certSecret: 'certSecret', downloadTime: 1));
  }

  @override
  Future<CloudLoginState> loginPassword(String token, String password) async {
    await Future.delayed(waitDuration);
    if (password == 'Showmeerror123!') {
      throw const ErrorResponse(
          code: 'INCORRECT_PASSWORD', errorMessage: "Incorrect password");
    } else {
      return const CloudLoginState(
          state: 'REQUIRED_2SV',
          data: CloudLoginStateData(
            token: 'token',
            authenticationMode: 'authenticationMode',
          ));
    }
  }

  @override
  Future<CloudLoginState> loginPrepare(String username) async {
    await Future.delayed(waitDuration);

    if (username.endsWith('linksys.com')) {
      return CloudLoginState.fromJson(const {
        'state': 'REQUIRED_2SV',
        'data': {'token': 'vToken123', 'authenticationMode': 'PASSWORDLESS'}
      });
    } else if (username.endsWith('belkin.com')) {
      return CloudLoginState.fromJson(const {
        'state': 'PASSWORD_REQUIRED',
        'data': {'token': 'vToken123', 'authenticationMode': 'PASSWORDLESS'}
      });
    }

    throw const ErrorResponse(
        code: 'RESOURCE_NOT_FOUND', errorMessage: 'errorMessage');
  }

  @override
  Future<void> downloadCloudCert({required taskId, required secret}) async {
    await Future.delayed(waitDuration);
  }
}
