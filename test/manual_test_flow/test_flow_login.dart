import 'dart:convert';

import 'package:moab_poc/network/http/extension_requests/extension_requests.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_login_certs.dart';
import 'package:moab_poc/network/http/model/cloud_login_state.dart';
import 'package:moab_poc/network/http/model/cloud_task_model.dart';
import 'package:test/test.dart';

import '../dev_testable_client.dart';

void main() {
  const username = 'austin.chang.chia.hao@gmail.com';
  const id = 'ee7652e0-9a25-4ee5-9974-944179415be0';
  const secret =
      'laxhR+c4Z61RU0yQhM22zro0Ej4XqKSjjQFY9nOQaWH/TnS91JIaVy7Ckq1eNSH1uHjFE0HthsLF7Bdt4tpTUXbteU4N7M9/RG1LIQ9AD8wAsp2zKR8KZE5RDRiwd6s2pgcL4SPCcEj8W4lecG1ynqS10R5sW8RiPZFjfmLtBSY=';

  String token = '2C0D7DAA-F7BF-4CAB-9A47-94F57E3C9278';
  CommunicationMethod? method;

  ///
  /// GROUP 1 -
  /// - login prepare,
  /// - login password,
  /// - get masked communication methods
  /// - auth challenge with id
  ///
  /// Need bring token from STEP 1 - login prepare to STEP 2 - login password
  /// Get methodId of EMAIL type communication method
  /// Request auth challenge for this method
  ///
  group('GROUP 1 - test login prepare and login password in dev', () {
    ///  Before this step, you may need an app id and an app secret from create apps API
    ///  And a token from account preparation API
    ///  For example:
    ///  {"id":"ee7652e0-9a25-4ee5-9974-944179415be0",
    ///  "appSecret":"laxhR+c4Z61RU0yQhM22zro0Ej4XqKSjjQFY9nOQaWH/TnS91JIaVy7Ckq1eNSH1uHjFE0HthsLF7Bdt4tpTUXbteU4N7M9/RG1LIQ9AD8wAsp2zKR8KZE5RDRiwd6s2pgcL4SPCcEj8W4lecG1ynqS10R5sW8RiPZFjfmLtBSY=",
    ///  "mobileManufacturer":"samsung","mobileModel":"GF855","os":"Android","osVersion":"9","systemLocale":"en-US"}
    ///  {"token":"355891F6-8BBC-4018-BAC2-A97713A40DAC"}
    test('STEP 1 - login prepare', () async {
      final client = DevTestableClient();
      final response =
          await client.loginPrepare(username, id: id, secret: secret);
      final loginState = CloudLoginState.fromJson(json.decode(response.body));
      token = loginState.data!.token;
    });

    test('STEP 2 - login password', () async {
      final client = DevTestableClient();
      final response = await client.loginPassword(token, 'Linksys123!',
          id: id, secret: secret);
    });

    test('STEP 3 - get communication methods', () async {
      final client = DevTestableClient();

      final response = await client.getMaskedCommunicationMethods(username);
      final jsonResp = json.decode(response.body) as List<dynamic>;
      final methods = List<CommunicationMethod>.from(
          jsonResp.map((e) => CommunicationMethod.fromJson(e)));
      method = methods.firstWhere((element) => element.method == 'EMAIL');
    });

    test('STEP 4 - auth challenge with id', () async {
      final client = DevTestableClient();
      final response = await client.authChallenge(
          AuthChallengeMethodId(token: token, commMethodId: method?.id ?? ''),
          id: id,
          secret: secret);
    });
  });

  ///
  /// GROUP 2 -
  ///  - auth challenge verify
  ///  - login actually
  ///
  ///  Get the code from email
  ///  Input the code for verification
  ///  Login actually
  ///
  group('GROUP 2 - test auth challenge verification and login part in dev', () {
    const token = '3D8D2F5F-5AB9-43AC-9DCC-FBB925BDDED4';
    CloudLoginAcceptState? acceptState;
    test('STEP 5 - auth challenge verify', () async {
      const code = '6674'; // PUT received code here.
      final client = DevTestableClient();
      final response =
          await client.authChallengeVerify(token: token, code: code);
    });

    test('STEP 6 - login actually', () async {
      final client = DevTestableClient();
      final response = await client.login(token, id: id, secret: secret);
      acceptState = CloudLoginAcceptState.fromJson(json.decode(response.body));
    });

    test('STEP 7 - download cert', () async {
      await Future.delayed(Duration(seconds: 3));
      final client = DevTestableClient();
      final response = await client.downloadCloudCerts(
          acceptState?.data.taskId ?? '',
          token: acceptState?.data.certToken ?? '',
          secret: acceptState?.data.certSecret ?? '');
      final taskData =
          CloudDownloadCertTask.fromJson(json.decode(response.body));
    });
  });
}
