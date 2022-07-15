import 'dart:convert';

import 'package:moab_poc/network/http/extension_requests/extension_requests.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:test/test.dart';

import '../dev_testable_client.dart';

void main() {
  group('test account preparation in dev', () {
    String token = '';
    final client = DevTestableClient();
    test('STEP1: post account preparation', () async {
      final response =
          await client.createAccountPreparation('austin.chang@linksys.com');
      token = json.decode(response.body)['token'];
      print('account preparation: $token');
    });

    test('STEP2: put account preparation with token', () async {
      final response = await client.createAccountVerifyPreparation(
        token,
        const CommunicationMethod(
          method: "EMAIL",
          targetValue: 'austin.chang@linksys.com',
        ),
      );
      print('STEP2: ${response.statusCode}, ${response.body}');
    });
  });
}
