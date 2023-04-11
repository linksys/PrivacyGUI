import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/network/http/linksys_requests/authorization_service.dart';
import 'package:linksys_moab/network/http/linksys_requests/data/cloud_account.dart';
import 'package:linksys_moab/network/http/linksys_requests/data/create_account_input.dart';
import 'package:linksys_moab/network/http/linksys_requests/user_service.dart';

import 'testable_client.dart';

void main() {
  group('test user service api', () {
    test('POST v2/accounts/u', () async {
      // const email = 'hank.yu@belkin.com';
      // const password = 'Belkin123!';

      const email = 'austin.chang.chia.hao+1399@gmail.com';
      const password = 'Belkin123!';

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      const input = CreateAccountInput(
          username: email,
          password: password,
          preferences:
              CAPreferences(locale: CALocale(language: 'en', country: 'US')));

      final response = await client.createAccount(input: input);
    });

    test('GET /phonecallingcodes', () async {
      const email = 'hank.yu@belkin.com';
      const password = 'Belkin123!';

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      final token = await client
          .passwordLogin(username: email, password: password)
          .then((value) => jsonDecode(value.body)['access_token']);

      final response = await client.getPhoneCallingCodes(token: token!);
    });

    test('GET /accounts/self/preferences', () async {
      const email = 'hank.yu@belkin.com';
      const password = 'Belkin123!';

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      final token = await client
          .passwordLogin(username: email, password: password)
          .then((value) => jsonDecode(value.body)['access_token']);

      final response = await client.getPreferences(
        token: token!,
      );
    });

    test('PUT /accounts/self/preferences', () async {
      const email = 'hank.yu@belkin.com';
      const password = 'Belkin123!';

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      final token = await client
          .passwordLogin(username: email, password: password)
          .then((value) => jsonDecode(value.body)['access_token']);

      const newPreferences = CAPreferences(
          mobile: CAMobile(countryCode: '+886', phoneNumber: '908720012'));

      final response = await client.setPreferences(
          token: token!, preferences: newPreferences);
    });

    test('POST /phonenumbercheck', () async {
      const email = 'hank.yu@belkin.com';
      const password = 'Belkin123!';

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      final token = await client
          .passwordLogin(username: email, password: password)
          .then((value) => jsonDecode(value.body)['access_token']);

      final response = await client.checkPhoneNumber(
          token: token!, countryCode: '+886', phoneNumber: '908720012');
    });

    test('POST /getMaskedMethods', () async {
      const email = 'austin.chang.chia.hao@gmail.com';
      const password = 'Belkin123!';

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      final token = await client.getMaskedMfaMethods(username: email);
      //     .then((value) => jsonDecode(value.body)['access_token']);
      //
      // final response = await client.checkPhoneNumber(
      //     token: token!, countryCode: '+886', phoneNumber: '908720012');
    });

    test('GET /accounts/self/', () async {
      const email = 'hank.yu@belkin.com';
      const password = 'Belkin123!';

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      final token = await client
          .passwordLogin(username: email, password: password)
          .then((value) => jsonDecode(value.body)['access_token']);

      final response = await client.getAccount(
        token: token!,
      ).then((response) => CAUserAccount.fromJson(jsonDecode(response.body)['account']));

      print(response);
    });
  });
}
