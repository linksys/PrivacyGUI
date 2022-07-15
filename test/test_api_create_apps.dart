import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:moab_poc/network/http/extension_requests/extension_requests.dart';
import 'package:moab_poc/network/http/model/cloud_app.dart';
import 'package:moab_poc/network/http/model/cloud_config.dart';
import 'package:moab_poc/network/http/constant.dart';
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/repository/config/config_repository.dart';
import 'package:moab_poc/utils.dart';
import 'package:test/test.dart';

import 'dev_testable_client.dart';

void main() {
  group('test create apps in dev', () {
    test('create apps', () async {
      final client = DevTestableClient();

      final deviceInfo = DeviceInfo(
          mobileManufacturer: 'samsung',
          mobileModel: 'GF855',
          os: 'Android',
          osVersion: '9',
          systemLocale: Intl.systemLocale.replaceFirst('_', '-'));
      final response = await client.createApp(deviceInfo);
      print('Create App: ${response.body}');
      final cloudApp = CloudApp.fromJson(json.decode(response.body));
      expect(cloudApp.id.isNotEmpty, true);
      expect(cloudApp.appSecret.isNotEmpty, true);
      expect(cloudApp.deviceInfo.mobileManufacturer.isNotEmpty, true);
      expect(cloudApp.deviceInfo.mobileModel.isNotEmpty, true);
      expect(cloudApp.deviceInfo.osVersion.isNotEmpty, true);
      expect(cloudApp.deviceInfo.os.isNotEmpty, true);
      expect(cloudApp.deviceInfo.systemLocale.isNotEmpty, true);
    });
  });
}
