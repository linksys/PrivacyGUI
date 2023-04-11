import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/network/http/linksys_requests/authorization_service.dart';
import 'package:linksys_moab/network/http/model/base_response.dart';

import '../testable_client.dart';

void main() {
  String? verificationToken;

  group('test MFA login - login password and request challenge', () {
    const email = 'austin.chang.chia.hao@gmail.com';
    const password = 'Belkin123!';
    test('POST /oauth/v2/token - Login', () async {
      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');
      // final response =
      //     await client.passwordLogin(username: email, password: password);
      expect(
          () async => await client
                  .passwordLogin(username: email, password: password)
                  .then<void>((_) {})
                  .onError((error, stackTrace) {
                final errorResp = error as ErrorResponse?;

                if (errorResp != null) {
                  print('errors: ${errorResp.parameters}');
                  final verificationTokenObj = errorResp.parameters
                      ?.firstWhereOrNull((element) =>
                          element['parameter']['name'] ==
                          'verification_token')?['parameter'];
                  verificationToken = verificationTokenObj?['value'];
                  print('greb verification token: $verificationToken');
                  throw errorResp;
                }
              }),
          throwsA(isA<ErrorResponse>()));
    });

    test('POST /oauth/challenge - Request MFA', () async {
      assert(verificationToken != null);

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      final response =
          await client.mfaChallenge(verificationToken: verificationToken!);
      //RESPONSE: 200, {"status":"OK","method":"EMAIL"}
    });
  });

  ///
  /// You'll need to get the otp code from target email and paste into test case
  ///
  ///
  group(
      'test MFA login - validate otp code w/o remember user agent and refresh token',
      () {
    String? accessToken;
    String? refreshToken;
    test('POST /oauth/v2/token - MFA Validate', () async {
      const otpCode = '163309'; // Paste OTP code from email here
      const verificationToken =
          'C0A2B5C4-1EF5-4C07-921F-7E42AB095392'; // Paste verification token here

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      final response = await client.mfaValidate(
        otpCode: otpCode,
        verificationToken: verificationToken,
      );

      final statusCode = response.statusCode;
      final result = jsonDecode(response.body);
      accessToken = result['access_token'];
      refreshToken = result['refresh_token'];
      expect(statusCode, HttpStatus.ok);
      expect(accessToken != null, true);
      expect(refreshToken != null, true);
    });

    test('POST /oauth/v2/token - Refresh token', () async {
      assert(refreshToken != null);
      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');
      final response = await client.refreshToken(token: refreshToken!);

      final statusCode = response.statusCode;
      final result = jsonDecode(response.body);
      accessToken = result['access_token'];
      refreshToken = result['refresh_token'];
      expect(statusCode, HttpStatus.ok);
      expect(accessToken != null, true);
      expect(refreshToken != null, true);
    });
  });
}
