import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/ddns/models/ddns_update_status.dart';
import 'package:privacy_gui/page/ddns/services/usp_ddns_status_data_service.dart';

import '../../../mocks/test_data/ddns_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

class MockBridgeRequestThrottler extends Mock
    implements BridgeRequestThrottler {}

void main() {
  late MockUspClient usp;
  late UspDdnsStatusDataService service;

  setUp(() {
    usp = MockUspClient();
    service = UspDdnsStatusDataService(usp);
  });

  void stubGet(Map<String, dynamic> response) {
    when(() => usp.get(any())).thenAnswer((_) async => response);
  }

  group('UspDdnsStatusDataService - fetch', () {
    test('the shipped client reads Disabled', () async {
      stubGet(DdnsTestData.response());

      expect(await service.fetch(), DdnsUpdateStatus.disabled);
    });

    test('an updated client reads success', () async {
      stubGet(DdnsTestData.configuredResponse());

      expect(await service.fetch(), DdnsUpdateStatus.success);
    });

    test(
        'judges the client with its host name: Error_Misconfigured with the '
        'host name in Error is an invalid host name', () async {
      stubGet(DdnsTestData.configuredResponse(
        clientStatus: 'Error_Misconfigured',
        lastError: 'MISCONFIGURATION_ERROR',
        hostnameStatus: 'Error',
      ));

      expect(await service.fetch(), DdnsUpdateStatus.invalidHostname);
    });

    test('a router with no client row reads Disabled', () async {
      stubGet({
        'Device.DynamicDNS.Server.1.Enable': true,
        'Device.DynamicDNS.Server.1.Name': 'DynDNS',
      });

      expect(await service.fetch(), DdnsUpdateStatus.disabled);
    });

    test('maps a thrown USP error to ServiceError', () async {
      when(() => usp.get(any())).thenThrow('Get failed: Transport error');

      expect(service.fetch(), throwsA(isA<ServiceError>()));
    });
  });

  // The throttler answers a repeated GET from its cache for 5 s, and only the
  // app's own writes clear it. An update finishing is not one, so a read
  // after its push could replay the status from before it.
  group('UspDdnsStatusDataService - fresh', () {
    late MockBridgeRequestThrottler throttler;

    setUp(() {
      throttler = MockBridgeRequestThrottler();
      when(() => usp.throttler).thenReturn(throttler);
      stubGet(DdnsTestData.response());
    });

    test('a fresh read drops the cache before it reads', () async {
      await service.fetch(fresh: true);

      verifyInOrder([() => throttler.clearCache(), () => usp.get(any())]);
    });

    test('a plain read keeps the cache', () async {
      await service.fetch();

      verifyNever(() => throttler.clearCache());
    });
  });

  group('UspDdnsStatusDataService - provider', () {
    test('needs a USP client', () {
      final container = ProviderContainer(
          overrides: [uspClientProvider.overrideWithValue(null)]);
      addTearDown(container.dispose);

      expect(() => container.read(uspDdnsStatusDataServiceProvider),
          throwsA(isA<ServiceNotInitializedError>()));
    });

    test('builds the service over the session client', () {
      final container = ProviderContainer(
          overrides: [uspClientProvider.overrideWithValue(usp)]);
      addTearDown(container.dispose);

      expect(container.read(uspDdnsStatusDataServiceProvider),
          isA<UspDdnsStatusDataService>());
    });
  });
}
