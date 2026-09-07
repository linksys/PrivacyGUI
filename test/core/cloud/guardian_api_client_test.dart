import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/cloud_host_resolver.dart';
import 'package:privacy_gui/core/cloud/guardian_api_client.dart';
import 'package:privacy_gui/core/cloud/http/linksys_http_client.dart';

import '../../mocks/test_data/remote_assistance_test_data.dart';

class MockLinksysHttpClient extends Mock implements LinksysHttpClient {}

class FakeUri extends Fake implements Uri {}

/// Verifies that [GuardianApiClient] assembles request URLs against the correct
/// host base: client-side requests go through the router proxy on a local
/// build, while CA-side requests always target the cloud host directly.
void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  const routerOrigin = 'https://192.168.1.1';
  final cloudBase = 'https://${cloudEnvironmentConfig[kCloudBase]}';

  late MockLinksysHttpClient mockHttp;
  late GuardianApiClient client;

  setUp(() {
    mockHttp = MockLinksysHttpClient();
    // Simulate a local (router-hosted) build so client-side requests proxy.
    client = GuardianApiClient(
      httpClient: mockHttp,
      hostResolver: CloudHostResolver(
        isLocal: () => true,
        originGetter: () => routerOrigin,
      ),
    );
  });

  /// Captures the [Uri] passed to a mocked verb without hitting the network.
  Uri capturedGetUri() =>
      verify(() => mockHttp.get(captureAny(), headers: any(named: 'headers')))
          .captured
          .single as Uri;

  Uri capturedPostUri() =>
      verify(() => mockHttp.post(captureAny(), headers: any(named: 'headers')))
          .captured
          .single as Uri;

  Uri capturedDeleteUri() => verify(
          () => mockHttp.delete(captureAny(), headers: any(named: 'headers')))
      .captured
      .single as Uri;

  group('client-side requests → router proxy', () {
    test('getSessions targets proxy base', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"content":[]}', 200));

      await client.getSessions(
        linksysToken: RemoteAssistanceTestData.testDeviceToken,
        serialNumber: RemoteAssistanceTestData.testSerialNumber,
      );

      expect(
          capturedGetUri().toString(), '$routerOrigin$kProxyPrefix$kSessions');
    });

    test('getSessionInfo targets proxy base with session id substituted',
        () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      await client.getSessionInfo(
        linksysToken: RemoteAssistanceTestData.testDeviceToken,
        sessionId: RemoteAssistanceTestData.testSessionId,
        serialNumber: RemoteAssistanceTestData.testSerialNumber,
      );

      final expected = '$routerOrigin$kProxyPrefix'
          '${kSessionInfo.replaceFirst(kVarRASessionId, RemoteAssistanceTestData.testSessionId)}';
      expect(capturedGetUri().toString(), expected);
    });

    test('createPin targets proxy base', () async {
      when(() => mockHttp.post(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response('{"id":"s1","pin":"1234"}', 200));

      await client.createPin(
        linksysToken: RemoteAssistanceTestData.testDeviceToken,
        serialNumber: RemoteAssistanceTestData.testSerialNumber,
      );

      expect(capturedPostUri().toString(),
          '$routerOrigin$kProxyPrefix$kCreatePin');
    });

    test('deleteSession targets proxy base with session id substituted',
        () async {
      when(() => mockHttp.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 200));

      await client.deleteSession(
        linksysToken: RemoteAssistanceTestData.testDeviceToken,
        sessionId: RemoteAssistanceTestData.testSessionId,
        serialNumber: RemoteAssistanceTestData.testSerialNumber,
      );

      final expected = '$routerOrigin$kProxyPrefix'
          '${kSessionInfo.replaceFirst(kVarRASessionId, RemoteAssistanceTestData.testSessionId)}';
      expect(capturedDeleteUri().toString(), expected);
    });
  });

  group('CA-side requests → cloud (bypass proxy even on local build)', () {
    test('getSessionInfoForCA targets cloud base', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      await client.getSessionInfoForCA(
        sessionToken: RemoteAssistanceTestData.testSessionToken,
        sessionId: RemoteAssistanceTestData.testSessionId,
      );

      final expected = '$cloudBase'
          '${kSessionInfo.replaceFirst(kVarRASessionId, RemoteAssistanceTestData.testSessionId)}';
      expect(capturedGetUri().toString(), expected);
    });

    test('deleteSessionForCA targets cloud base', () async {
      when(() => mockHttp.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 200));

      await client.deleteSessionForCA(
        sessionToken: RemoteAssistanceTestData.testSessionToken,
        sessionId: RemoteAssistanceTestData.testSessionId,
      );

      final expected = '$cloudBase'
          '${kSessionInfo.replaceFirst(kVarRASessionId, RemoteAssistanceTestData.testSessionId)}';
      expect(capturedDeleteUri().toString(), expected);
    });
  });
}
