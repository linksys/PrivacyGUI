import 'dart:convert';

import 'package:moab_poc/network/http/extension_requests/extension_requests.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:test/test.dart';

import '../dev_testable_client.dart';

void main() {
  group('test account preparation in dev', () {
    test('account preparation', () async {
      final client = DevTestableClient();
      try {
        final response = await client.createAccountPreparation(
            'austin.chang@belkin.com');
        final String token = json.decode(response.body)['token'];
        expect(token.isNotEmpty, true);
      } catch (e) {
        logger.e('In try catch block: ${e.runtimeType}');
      }
    });
  });
}
