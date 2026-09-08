import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_data_service.dart';

import '../../../mocks/test_data/wifi_settings_test_data.dart';

class MockUspWifiDataService extends Mock implements UspWifiDataService {}

void main() {
  late MockUspWifiDataService mockService;

  setUp(() {
    mockService = MockUspWifiDataService();
    when(() => mockService.fetch()).thenAnswer(
        (_) async => WifiSettingsTestData.createWifiDataFetchResult());
  });

  ProviderContainer createContainer({
    Stream<InvalidationEvent>? sseStream,
  }) {
    return ProviderContainer(
      overrides: [
        uspWifiDataServiceProvider.overrideWithValue(mockService),
        if (sseStream != null)
          sseInvalidationProvider.overrideWith((ref) => sseStream),
      ],
    );
  }

  group('WifiDataNotifier', () {
    test('build maps the service fetch result into WifiData', () async {
      final container = createContainer();
      final data = await container.read(wifiDataProvider.future);

      expect(data.codegenContext,
          WifiSettingsTestData.createWifiDataFetchResult().codegenContext);
      expect(data.wifiClientMap, isEmpty);
      expect(data.connectionDetailMap, isEmpty);
      expect(data.radioModels, isEmpty);
      verify(() => mockService.fetch()).called(1);
      container.dispose();
    });

    test('build propagates a ServiceError from the service', () async {
      when(() => mockService.fetch())
          .thenThrow(const ServiceNotInitializedError(detail: 'no usp'));

      final container = createContainer();

      await expectLater(
        container.read(wifiDataProvider.future),
        throwsA(isA<ServiceNotInitializedError>()),
      );
      container.dispose();
    });

    test('WifiData equality includes codegenContext', () {
      // props is overridden explicitly rather than derived from namedProps,
      // which omits codegenContext — an SSID rename would otherwise not notify.
      final a = WifiSettingsTestData.createWifiData();
      final b = WifiSettingsTestData.createWifiData();

      expect(a, equals(b));
      expect(a, isNot(equals(const WifiData.empty())));
      expect(a.props, [
        a.codegenContext,
        a.wifiClientMap,
        a.connectionDetailMap,
        a.radioModels,
      ]);
    });

    // All four branches of the OR-gate. The provider is the single L1 cache for
    // radios, SSIDs, access points *and* WiFi clients, so a guard that dropped
    // any one branch would leave that page stale with everything else green.
    for (final domain in const [
      InvalidationDomain.wifiRadios,
      InvalidationDomain.wifiSsids,
      InvalidationDomain.wifiAccessPoints,
      InvalidationDomain.wifiClients,
    ]) {
      test('SSE ${domain.name} domain triggers debounced re-fetch', () {
        fakeAsync((async) {
          final sseController = StreamController<InvalidationEvent>.broadcast();
          final container = createContainer(sseStream: sseController.stream);

          container.listen(wifiDataProvider, (_, __) {});
          async.flushMicrotasks();
          clearInteractions(mockService);

          sseController.add((domain: domain, seq: 0));
          async.flushMicrotasks();

          // Timer pending — no re-fetch yet.
          verifyNever(() => mockService.fetch());

          async.elapse(const Duration(milliseconds: 500));
          async.flushMicrotasks();

          verify(() => mockService.fetch()).called(1);

          sseController.close();
          container.dispose();
        });
      });
    }

    // connectedDevices is the sharpest wrong answer: wifiClients *is* watched,
    // and connectedDevices is the other client-list domain on the same SSE
    // path. A guard that matched "any client list" would survive a test using
    // an obviously unrelated domain instead.
    test('SSE connectedDevices domain does not trigger re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);

        container.listen(wifiDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockService);

        sseController
            .add((domain: InvalidationDomain.connectedDevices, seq: 0));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        verifyNever(() => mockService.fetch());

        sseController.close();
        container.dispose();
      });
    });

    // Spaced past the 500ms debounce window on purpose — inside it the two
    // events are *meant* to merge, so a repeat asserted there could not tell a
    // real collapse from the debouncer doing its job. Same domain both times,
    // so `seq` (#1501 AC-B1) is the only difference between the two events.
    test('two wifiRadios events past the debounce window re-fetch twice', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);

        container.listen(wifiDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockService);

        sseController.add((domain: InvalidationDomain.wifiRadios, seq: 0));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();
        verify(() => mockService.fetch()).called(1);

        sseController.add((domain: InvalidationDomain.wifiRadios, seq: 1));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();
        verify(() => mockService.fetch()).called(1);

        sseController.close();
        container.dispose();
      });
    });
  });
}
