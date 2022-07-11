import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:moab_poc/network/http/model/cloud_app.dart';
import 'package:moab_poc/network/http/model/cloud_config.dart';
import 'package:moab_poc/network/http/constant.dart';
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/repository/config/config_repository.dart';
import 'package:moab_poc/utils.dart';
import 'package:test/test.dart';

void main() {
  group('test login prepare in dev', () {
    test('login prepare', () async {
      const host = 'https://dev-as1-api.moab.xvelop.com';
      final client = MoabHttpClient();
      final header = {
        moabSiteIdKey: moabRetailSiteId,
        HttpHeaders.contentTypeHeader: ContentType.json.value,
        HttpHeaders.acceptHeader: ContentType.json.value
      };
      final mockDeviceInfo =
      {
        'mobileManufacturer': 'samsung',
        'mobileModel': 'GF855',
        'os': 'Android',
        'osVersion': '9',
        'systemLocale': Intl.systemLocale.replaceFirst('_', '-')
      };
      const url = '$host$endpointCreateApps';
      final response = await client.post(Uri.parse(url),
          headers: header, body: jsonEncode(mockDeviceInfo));
      final cloudApp = CloudApp.fromJson(json.decode(response.body));
      expect(cloudApp.id.isNotEmpty, true);
      expect(cloudApp.appSecret.isNotEmpty, true);
      expect(cloudApp.deviceInfo.mobileManufacturer.isNotEmpty, true);
      expect(cloudApp.deviceInfo.mobileModel.isNotEmpty, true);
      expect(cloudApp.deviceInfo.osVersion.isNotEmpty, true);
      expect(cloudApp.deviceInfo.os.isNotEmpty, true);
      expect(cloudApp.deviceInfo.systemLocale.isNotEmpty, true);

      const loginPrepareUrl = '$host$endpointAuthLoginPrepare';
      final loginPrepareHeaders = header..addAll(
          {moabAppIdKey: cloudApp.id, moabAppSecretKey: cloudApp.appSecret});
      final loginPrepareResponse = await client.post(
          Uri.parse(loginPrepareUrl), headers: loginPrepareHeaders, body: jsonEncode({'username': 'austin.chang@linksys.com'}));

    });
  });
}
