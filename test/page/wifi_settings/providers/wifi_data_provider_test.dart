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
      // ---------------------------------------------------------------------
      // linksys/PrivacyGUI#1615 — does the re-fetch survive WITHOUT a listener?
      //
      // The test below it passes, and passed before the fix too, because it holds
      // `container.listen(wifiDataProvider, …)` for the whole test. The old
      // `invalidateSelf()` only SCHEDULED a rebuild — riverpod runs `build()` again when
      // something READS the provider, and that listener guaranteed something did. So the
      // passing test could not tell "the refresh works" apart from "the refresh works
      // BECAUSE a subscriber was held".
      //
      // On every current dashboard preset something DOES watch this provider —
      // `stats_panel` reads it and appears in all five presets. So this was correct BY
      // COINCIDENCE: the guarantee was five `const` lists in `usp_dashboard_preset.dart`
      // all happening to include one card, not anything this provider controls. And no
      // test would have caught the coincidence breaking, because every test in this file
      // holds a subscriber.
      //
      // Measured before the fix: with a listener 1 fetch → 2; without, 1 → 1.
      //
      // Run for each watched domain, like the test below, so a guard that regressed for
      // only one of the four is still caught.
      // ---------------------------------------------------------------------
      test('#1615: ${domain.name} re-fetches with NO listener held', () {
        fakeAsync((async) {
          final sseController = StreamController<InvalidationEvent>.broadcast();
          final container = createContainer(sseStream: sseController.stream);

          // A one-shot read rather than a listen: what a widget that has since stopped
          // watching looks like. It still constructs the notifier, so build()'s
          // `ref.listen` is registered.
          container.read(wifiDataProvider);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 1));
          async.flushMicrotasks();

          // Asserting on the VALUE, not a verify() count — mocktail's verify CONSUMES
          // the calls it matches, so a count-based guard would eat the evidence the
          // real assertion needs.
          expect(container.read(wifiDataProvider).hasValue, isTrue,
              reason:
                  'build() must have completed, or this test asserts nothing');

          clearInteractions(mockService);

          sseController.add((domain: domain, seq: 0));
          async.flushMicrotasks();
          async.elapse(const Duration(milliseconds: 500));
          async.flushMicrotasks();

          verify(() => mockService.fetch()).called(1);

          sseController.close();
          container.dispose();
        });
      });

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
