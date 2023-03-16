import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/network/http/linksys_requests/authorization_service.dart';
import 'package:linksys_moab/network/http/linksys_requests/data/cloud_account.dart';
import 'package:linksys_moab/network/http/linksys_requests/data/create_account_input.dart';
import 'package:linksys_moab/network/http/linksys_requests/device_service.dart';
import 'package:linksys_moab/network/http/linksys_requests/user_service.dart';

import 'testable_client.dart';

void main() {
  group('test device service api', () {
    test('GET /accounts/{username}/networks', () async {
      const email = 'hank.yu@belkin.com';
      const password = 'Belkin123!';

      final host = kCloudEnvironmentConfigQa[kCloudBase] as String;
      final client = TestableHttpClient('https://$host');

      // final token = await client
      //     .passwordLogin(username: email, password: password)
      //     .then((value) => jsonDecode(value.body)['access_token']);

      final token =
          '6E223C641F064337B835488D0D260EBF8EB290B86ABB4BC8925C447A7EB44D71';
      final response = await client.getNetworks(
        token: token,
      );
      print(response.body);
    });
  });
}
