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
  group('test account preparation in dev', () {
    test('account preparation', () async {
      const host = 'https://dev-as1-api.moab.xvelop.com';
      final client = MoabHttpClient();
      final header = {
        moabSiteIdKey: moabRetailSiteId,
        HttpHeaders.contentTypeHeader: ContentType.json.value,
        HttpHeaders.acceptHeader: ContentType.json.value
      };

      const url = '$host$endpointAccountPreparations';
      final response = await client.post(
          Uri.parse(url), headers: header, body: jsonEncode({'username': 'austin.chang@linksys.com'}));

    });
  });
}
