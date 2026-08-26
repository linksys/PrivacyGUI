import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_device_cloud_service.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

/// Answers every request with a device token, and records how many times the
/// cloud was actually hit.
class FakeHttpClient extends LinksysHttpClient {
  FakeHttpClient() : super(getHost: () => 'https://example.test');

  String tokenToReturn = 'token-B';
  final List<Uri> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request.url);
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode({'linksysToken': tokenToReturn}))),
      200,
    );
  }
}

void main() {
  late FakeHttpClient httpClient;
  late DeviceCloudService service;
  late Map<String, String> storage;

  const freshTs = 1;
  const kDay = 60 * 60 * 24 * 1000;

  void seedToken({
    required String token,
    required String serialNumber,
    int ageMs = 0,
  }) {
    storage
      ..[pLinksysToken] = token
      ..[pLinksysTokenSn] = serialNumber
      ..[pLinksysTokenTs] = '${DateTime.now().millisecondsSinceEpoch - ageMs}';
  }

  setUp(() {
    storage = {};
    FlutterSecureStorage.setMockInitialValues(storage);
    httpClient = FakeHttpClient();
    service = DeviceCloudService(httpClient: httpClient);
  });

  group('fetchDeviceToken', () {
    test('fetches a new token when the cached one belongs to another device',
        () async {
      seedToken(token: 'token-A', serialNumber: 'SN-A', ageMs: freshTs);

      final token = await service.fetchDeviceToken(
        serialNumber: 'SN-B',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        deviceUUID: 'uuid-b',
      );

      expect(token, 'token-B');
      expect(httpClient.requests, hasLength(1));
      expect(storage[pLinksysToken], 'token-B');
      expect(storage[pLinksysTokenSn], 'SN-B');
    });

    test('reuses the cached token of the same device', () async {
      seedToken(token: 'token-A', serialNumber: 'SN-A', ageMs: freshTs);

      final token = await service.fetchDeviceToken(
        serialNumber: 'SN-A',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        deviceUUID: 'uuid-a',
      );

      expect(token, 'token-A');
      expect(httpClient.requests, isEmpty);
    });

    test('fetches a new token when the cached one expired', () async {
      seedToken(token: 'token-A', serialNumber: 'SN-A', ageMs: kDay + 1);
      httpClient.tokenToReturn = 'token-A2';

      final token = await service.fetchDeviceToken(
        serialNumber: 'SN-A',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        deviceUUID: 'uuid-a',
      );

      expect(token, 'token-A2');
      expect(httpClient.requests, hasLength(1));
    });

    test('fetches a new token when nothing is cached', () async {
      final token = await service.fetchDeviceToken(
        serialNumber: 'SN-B',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        deviceUUID: 'uuid-b',
      );

      expect(token, 'token-B');
      expect(httpClient.requests, hasLength(1));
      expect(storage[pLinksysTokenSn], 'SN-B');
    });
  });
}
