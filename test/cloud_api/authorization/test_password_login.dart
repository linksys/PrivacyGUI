import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/network/http/linksys_requests/authorization_service.dart';

import '../testable_client.dart';

void main() {
  group('test login without MFA and refresh token', () {
    String? accessToken;
    String? refreshToken;

    test('POST /oauth/v2/token - Login', () async {
      const email = 'hank.yu@belkin.com';
      const password = 'Belkin123!';

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');
      final response =
          await client.passwordLogin(username: email, password: password);

      final statusCode = response.statusCode;
      final result = jsonDecode(response.body);
      accessToken = result['access_token'];
      refreshToken = result['refresh_token'];
      expect(statusCode, HttpStatus.ok);
      expect(accessToken != null, true);
      expect(refreshToken != null, true);
    });

    test('POST /oauth/v2/token - Refresh token', () async {
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
