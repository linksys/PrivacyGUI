import 'dart:convert';

import 'package:moab_poc/network/http/extension_requests/extension_requests.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
import 'package:moab_poc/network/http/model/cloud_preferences.dart';
import 'package:test/test.dart';

import '../dev_testable_client.dart';

void main() {
  const username = 'austin.chang@linksys.com';
  String token = '';

  const appId = 'ee7652e0-9a25-4ee5-9974-944179415be0';
  const appSecret =
      'laxhR+c4Z61RU0yQhM22zro0Ej4XqKSjjQFY9nOQaWH/TnS91JIaVy7Ckq1eNSH1uHjFE0HthsLF7Bdt4tpTUXbteU4N7M9/RG1LIQ9AD8wAsp2zKR8KZE5RDRiwd6s2pgcL4SPCcEj8W4lecG1ynqS10R5sW8RiPZFjfmLtBSY=';

  group('GROUP 1 - test create account preparation and send auth challenge in dev', () {
    final client = DevTestableClient();
    test('STEP 1 - post account preparation', () async {
      final response = await client.createAccountPreparation(username);
      token = json.decode(response.body)['token'];
    });

    test('STEP 2 - put account preparation with token', () async {
      final response = await client.createAccountVerifyPreparation(
        token,
        const CommunicationMethod(
          method: "EMAIL",
          targetValue: username,
        ),
      );
      print('STEP2: ${response.statusCode}, ${response.body}');
    });

    test('STEP 3 - auth challenge with email', () async {
      final client = DevTestableClient();
      AuthChallengeMethod method =
          AuthChallengeMethod(token: token, method: "EMAIL", target: username);
      final response =
          await client.authChallenge(method, id: appId, secret: appSecret);
    });
  });

  group('GROUP 2 - test auth challenge verify and actually create account in dev', () {
    test('STEP 4 - auth challenge verify', () async {
      String code = '8325'; // PUT received code from email/SMS here
      final client = DevTestableClient();
      final response =
          await client.authChallengeVerify(token: token, code: code);
    });

    test('STEP 5 - account creation', () async {
      final client = DevTestableClient();
      final response = await client.createAccount(CreateAccountVerified(
          token: token,
          authenticationMode: "PASSWORD",
          password: 'Linksys123!',
          preferences: const CloudPreferences(
              isoLanguageCode: 'zh',
              isoCountryCode: 'TW',
              timeZone: 'Asia/Taipei')));
    });
  });
}
