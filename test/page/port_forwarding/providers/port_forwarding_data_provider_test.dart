import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_forwarding_data_service.dart';

import '../../../mocks/test_data/port_forwarding_test_data.dart';

class MockUspPortForwardingDataService extends Mock
    implements UspPortForwardingDataService {}

void main() {
  late MockUspPortForwardingDataService mockService;

  setUp(() {
    mockService = MockUspPortForwardingDataService();
    when(() => mockService.fetch())
        .thenAnswer((_) async => PortForwardingTestData.createRules());
  });

  ProviderContainer createContainer({
    Stream<InvalidationEvent>? sseStream,
  }) {
    return ProviderContainer(
      overrides: [
        uspPortForwardingDataServiceProvider.overrideWithValue(mockService),
        if (sseStream != null)
          sseInvalidationProvider.overrideWith((ref) => sseStream),
      ],
    );
  }

  group('PortForwardingDataNotifier', () {
    test('build maps the service fetch result into PortForwardingData',
        () async {
      final container = createContainer();
      final data = await container.read(portForwardingDataProvider.future);

      expect(data.ruleModels, hasLength(2));
      expect(data.ruleModels.first.description, 'Web Server');
      expect(data.ruleModels.first.externalPortEndRange, 0);
      expect(data.ruleModels.last.externalPortEndRange, 27020);
      verify(() => mockService.fetch()).called(1);
      container.dispose();
    });

    test('build propagates a ServiceError from the service', () async {
      when(() => mockService.fetch())
          .thenThrow(const ServiceNotInitializedError(detail: 'no usp'));

      final container = createContainer();

      await expectLater(
        container.read(portForwardingDataProvider.future),
        throwsA(isA<ServiceNotInitializedError>()),
      );
      container.dispose();
    });

    test('PortForwardingData equality is derived from namedProps', () {
      final a = PortForwardingTestData.createPortForwardingData();
      final b = PortForwardingTestData.createPortForwardingData();
      final empty =
          PortForwardingTestData.createPortForwardingData(ruleModels: const []);

      expect(a, equals(b));
      expect(a, isNot(equals(empty)));
      expect(a.props, [a.ruleModels]);
    });

    test('SSE portForwarding domain triggers debounced re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);

        container.listen(portForwardingDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockService);

        sseController.add((domain: InvalidationDomain.portForwarding, seq: 0));
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

    // dmz is the sharpest wrong answer: it is the neighbouring
    // Device.Firewall/NAT domain, and the firewall data provider one page over
    // *does* refresh on it — so a guard that matched the whole family would
    // survive a test that used an obviously unrelated domain instead.
    test('SSE dmz domain does not trigger re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);

        container.listen(portForwardingDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockService);

        sseController.add((domain: InvalidationDomain.dmz, seq: 0));
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
    test('two portForwarding events past the debounce window re-fetch twice',
        () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);

        container.listen(portForwardingDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockService);

        sseController.add((domain: InvalidationDomain.portForwarding, seq: 0));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();
        verify(() => mockService.fetch()).called(1);

        sseController.add((domain: InvalidationDomain.portForwarding, seq: 1));
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
