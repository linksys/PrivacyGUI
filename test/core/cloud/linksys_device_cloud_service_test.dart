import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/constants/cloud_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/cloud/linksys_device_cloud_service.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

import '../../common/cloud_boundary.dart';

/// Answers every request with a device token, and records how many times the
/// cloud was actually hit.
class FakeHttpClient extends LinksysHttpClient {
  FakeHttpClient() : super(getHost: () => 'https://example.test');

  String tokenToReturn = 'token-B';
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
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

  const freshAgeMs = 1;
  const kDay = 60 * 60 * 24 * 1000;

  const master = LinksysDevice(
    connections: [],
    properties: [],
    unit: RawDeviceUnit(serialNumber: 'SN-MASTER'),
    deviceID: 'device-uuid-master',
    maxAllowedProperties: 10,
    model: RawDeviceModel(deviceType: 'Infrastructure'),
    isAuthority: true,
    lastChangeRevision: 1,
    nodeType: 'Master',
    knownInterfaces: [
      RawDeviceKnownInterface(
        macAddress: 'AA:BB:CC:DD:EE:FF',
        interfaceType: 'Wireless',
      ),
    ],
  );

  void seedToken({
    required String token,
    required String serialNumber,
    int ageMs = 0,
  }) {
    storage
      ..[pLinksysToken] = token
      ..[pLinksysTokenSN] = serialNumber
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
      seedToken(token: 'token-A', serialNumber: 'SN-A', ageMs: freshAgeMs);

      final token = await service.fetchDeviceToken(
        serialNumber: 'SN-B',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        deviceUUID: 'uuid-b',
      );

      expect(token, 'token-B');
      expect(httpClient.requests, hasLength(1));
      expect(storage[pLinksysToken], 'token-B');
      expect(storage[pLinksysTokenSN], 'SN-B');
    });

    test('reuses the cached token of the same device', () async {
      seedToken(token: 'token-A', serialNumber: 'SN-A', ageMs: freshAgeMs);

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
      expect(storage[pLinksysTokenSN], 'SN-B');
    });
  });

  group('deleteSession', () {
    test('signs the request with the token of the device it is sent for',
        () async {
      // A session that was created for another device than the current master.
      seedToken(
          token: 'token-master', serialNumber: 'SN-MASTER', ageMs: freshAgeMs);

      await service.deleteSession(
        master: master,
        sessionId: 'session-1',
        serialNumber: 'SN-SESSION',
      );

      expect(httpClient.requests.first.url.queryParameters['serialNumber'],
          'SN-SESSION');
      final deleteRequest = httpClient.requests.last;
      expect(deleteRequest.headers[kHeaderSerialNumber], 'SN-SESSION');
      expect(deleteRequest.headers[kHeaderLinksysToken], 'token-B');
    });

    test('does not store the token it fetched', () async {
      // Logging out clears the store right after, and the token was minted
      // against the master's mac address and uuid, so it must not be filed
      // under the serial number the session belongs to either.
      seedToken(
          token: 'token-master', serialNumber: 'SN-MASTER', ageMs: freshAgeMs);

      await service.deleteSession(
        master: master,
        sessionId: 'session-1',
        serialNumber: 'SN-SESSION',
      );

      expect(storage[pLinksysToken], 'token-master');
      expect(storage[pLinksysTokenSN], 'SN-MASTER');
    });
  });

  group('the Guardian calls, against a cloud that answers by path', () {
    const geolocation = '/cloud/v1/guardians/devices/geolocation';
    const sessions = '/cloud/v1/guardians/remote-assistances/sessions';
    final guardianSession = {
      'id': 'G1',
      'serialNumber': 'SN-MASTER',
      'modelNumber': 'MX6200',
      'status': 'PENDING',
      'expiredIn': -600,
      'createdAt': 1722240538000,
      'statusChangedAt': 1722240574000,
      'currentTime': 1722240580739,
    };

    late CloudBoundary cloud;
    late DeviceCloudService cloudService;

    setUpAll(() {
      // getGeolocation caches through the LinksysCacheManager singleton, which
      // keeps its file in the temp directory.
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => Directory.systemTemp.path,
      );
    });

    setUp(() {
      LinksysCacheManager().clearCache(geolocation);
      seedToken(token: 'device-token', serialNumber: 'SN-MASTER');
      cloud = CloudBoundary();
      cloudService = DeviceCloudService(httpClient: cloud);
    });

    test('getGeolocation asks with the master device token and serial number',
        () async {
      cloud.answers('GET', geolocation, json: {
        'countryCode': 'TW',
        'name': 'Taipei',
      });

      final location = await cloudService.getGeolocation(master);

      expect(location, {'countryCode': 'TW', 'name': 'Taipei'});
      final request = cloud.requests.single;
      expect(request.header('X-Linksys-Token'), 'device-token');
      expect(request.header('X-Linksys-SN'), 'SN-MASTER');
    });

    test('getGeolocation answers from its cache the second time', () async {
      cloud.answers('GET', geolocation, json: {'countryCode': 'TW'});

      await cloudService.getGeolocation(master);
      final again = await cloudService.getGeolocation(master);

      expect(again, {'countryCode': 'TW'});
      expect(cloud.requestsTo(geolocation), hasLength(1));
    });

    test('getGeolocation reports the error the cloud answers with', () async {
      cloud.answersError('GET', geolocation, 'DEVICE_NOT_FOUND');

      await expectLater(
          cloudService.getGeolocation(master), throwsA(isA<ErrorResponse>()));
    });

    test('createPin asks for a PIN for the master and returns it', () async {
      cloud.answers('POST', '$sessions/pin', json: {'pin': '482913'});

      final pin = await cloudService.createPin(master: master, sessionId: 'G1');

      expect(pin, '482913');
      expect(cloud.requests.single.header('X-Linksys-SN'), 'SN-MASTER');
    });

    test('createPin reports a session already in progress', () async {
      cloud.answersError('POST', '$sessions/pin', 'SESSION_IN_PROGRESS');

      await expectLater(
        cloudService.createPin(master: master, sessionId: 'G1'),
        throwsA(isA<ErrorResponse>()
            .having((e) => e.code, 'code', 'SESSION_IN_PROGRESS')),
      );
    });

    test('getSessionInfo reads a session as the device, not the account',
        () async {
      cloud.answers('GET', '$sessions/G1', json: guardianSession);

      final info =
          await cloudService.getSessionInfo(master: master, sessionId: 'G1');

      expect(info.id, 'G1');
      expect(info.status, GRASessionStatus.pending);
      final request = cloud.requests.single;
      expect(request.header('X-Linksys-SN'), 'SN-MASTER');
      expect(request.header('Authorization'), isNull);
    });

    test('getSessionInfo reports a session the cloud does not know', () async {
      cloud.answersError('GET', '$sessions/G1', 'SESSION_NOT_FOUND');

      await expectLater(
          cloudService.getSessionInfo(master: master, sessionId: 'G1'),
          throwsA(isA<ErrorResponse>()));
    });

    test('getSessions lists the sessions of the master', () async {
      cloud.answers('GET', sessions, json: {
        'content': [
          guardianSession,
          {...guardianSession, 'id': 'G2', 'status': 'ACTIVE'},
        ],
      });

      final list = await cloudService.getSessions(master: master);

      expect(list.map((session) => session.id), ['G1', 'G2']);
      expect(list.last.status, GRASessionStatus.active);
      final request = cloud.requests.single;
      expect(request.header('X-Linksys-Token'), 'device-token');
      expect(request.header('X-Linksys-SN'), 'SN-MASTER');
    });

    test('getSessions reports the error the cloud answers with', () async {
      cloud.answersError('GET', sessions, 'DEVICE_NOT_FOUND');

      await expectLater(cloudService.getSessions(master: master),
          throwsA(isA<ErrorResponse>()));
    });

    test('deleteSession reports a session the cloud does not know', () async {
      cloud.answersError('DELETE', '$sessions/G1', 'SESSION_NOT_FOUND');

      await expectLater(
          cloudService.deleteSession(master: master, sessionId: 'G1'),
          throwsA(isA<ErrorResponse>()));
    });
  });
}
