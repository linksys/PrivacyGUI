import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/device_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/storage_service.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

void main() {
  ///
  /// This test is used to test cloud API
  ///
  test('device service ...', () async {
    final client = LinksysHttpClient(
        client: IOClient(),
        getHost: () => 'https://qa.cloud1.linksyssmartwifi.com');
    const serialNumber = '20J2060A839173',
        modelNumber = 'WHW03',
        macAddress = '30:23:03:2E:AF:EE';
    final response = await client.registrations(
      serialNumber: serialNumber,
      modelNumber: modelNumber,
      macAddress: macAddress,
    );
    final token = jsonDecode(response.body)['clientDevice']['linksysToken'];
    final uplodadResponse = await client.deviceUpload(
        deviceToken: token, serialNumber: serialNumber, meta: '{}', log: '456');
  }, skip: true);
}
