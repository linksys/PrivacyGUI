
import 'package:moab_poc/network/http/extension_requests/extension_requests.dart';
import 'package:test/test.dart';

import 'dev_testable_client.dart';

void main() {
  group('test get communication methods in dev', () {
    test('get communication methods', () async {
      final client = DevTestableClient();

      final response = await client.getMaskedCommunicationMethods('82248d9d-50a7-4e35-822c-e07ed02d8063');
      print('get communication methods: ${response.body}');
      // final cloudApp = CloudApp.fromJson(json.decode(response.body));

    });
  });
}
