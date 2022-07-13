import 'dart:convert';

import 'package:moab_poc/network/http/extension_requests.dart';
import 'package:test/test.dart';

import '../dev_testable_client.dart';

void main() {
  group('test account preparation in dev', () {
    test('account preparation', () async {
      final client = DevTestableClient();
      final response = await client.createAccountPreparation('austin.chang@linksys.com');
      final String token = json.decode(response.body)['token'];
      expect(token.isNotEmpty, true);
    });
  });
}
