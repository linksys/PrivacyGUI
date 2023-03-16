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
  const email = 'austin.chang.chia.hao@gmail.com';
  const password = 'Belkin123!';
  group('test MFA login - login password and request challenge', () {
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
                  final verificationTokenObj = errorResp.parameters
                      ?.firstWhereOrNull((element) =>
                          element['parameter']['name'] ==
                          'verification_token')?['parameter'];
                  verificationToken = verificationTokenObj?['value'];
                  throw errorResp;
                }
              }),
          throwsA(isA<ErrorResponse>()));
    });

    test('POST /oauth/challenge - Request MFA', () async {
      assert(verificationToken != null);

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      final response = await client.mfaChallenge(
          target: email, verificationToken: verificationToken!);
      //RESPONSE: 200, {"status":"OK","method":"EMAIL"}
    });
  });

  ///
  /// You'll need to get the otp code from target email and paste into test case
  ///
  ///
  group(
      'test MFA login - validate otp code with remember user agent and refresh token',
      () {
    String? accessToken;
    String? refreshToken;
    String? userAgentId;
    String? secret;
    test('POST /oauth/v2/token - MFA Validate and remember user agent',
        () async {
      const otpCode = '993833'; // Paste OTP code from email here
      const verificationToken =
          '684CEA6F-9A59-47D6-8BD6-1BEF3BCE3A22'; // Paste verification token here

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      final response = await client.mfaValidate(
        otpCode: otpCode,
        verificationToken: verificationToken,
        rememberUserAgent: true,
      );

      final statusCode = response.statusCode;
      final result = jsonDecode(response.body);
      accessToken = result['access_token'];
      refreshToken = result['refresh_token'];
      userAgentId = result['user_agent_id'];
      secret = result['secret'];
      expect(statusCode, HttpStatus.ok);
      expect(accessToken != null, true);
      expect(refreshToken != null, true);
      expect(userAgentId != null, true);
      expect(secret != null, true);
    });

    test('POST /oauth/v2/token - Login with user agent id', () async {
      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');
      final response = await client.passwordLogin(
        username: email,
        password: password,
        userAgentId: userAgentId,
        secret: secret,
      );

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
