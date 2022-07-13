import 'dart:convert';

import 'package:moab_poc/network/http/constant.dart';
import 'package:moab_poc/network/http/extension_requests.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
import 'package:moab_poc/network/http/model/cloud_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import '../dev_testable_client.dart';

///
///  Before this step, you may need an app id and an app secret from create apps API
///  And a token from account preparation API
///  For example:
///  {"id":"ee7652e0-9a25-4ee5-9974-944179415be0",
///  "appSecret":"laxhR+c4Z61RU0yQhM22zro0Ej4XqKSjjQFY9nOQaWH/TnS91JIaVy7Ckq1eNSH1uHjFE0HthsLF7Bdt4tpTUXbteU4N7M9/RG1LIQ9AD8wAsp2zKR8KZE5RDRiwd6s2pgcL4SPCcEj8W4lecG1ynqS10R5sW8RiPZFjfmLtBSY=",
///  "mobileManufacturer":"samsung","mobileModel":"GF855","os":"Android","osVersion":"9","systemLocale":"en-US"}
///  {"token":"355891F6-8BBC-4018-BAC2-A97713A40DAC"}
void main() {
  group('test auth challenge verify in dev', () {
    test('auth challenge verify', () async {
      String token = '98DBD3BE-2114-43A3-B539-D0857D5B8493';
      String code = '8325';
      final client = DevTestableClient();
      final response =
          await client.authChallengeVerify(token: token, code: code);
    });

    test('account creation', () async {
      String token = '98DBD3BE-2114-43A3-B539-D0857D5B8493';
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
