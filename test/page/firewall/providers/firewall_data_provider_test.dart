import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_data_service.dart';

import '../../../mocks/test_data/firewall_test_data.dart';

class MockUspFirewallDataService extends Mock
    implements UspFirewallDataService {}

void main() {
  late MockUspFirewallDataService mockService;

  setUp(() {
    mockService = MockUspFirewallDataService();
    when(() => mockService.fetch())
        .thenAnswer((_) async => FirewallTestData.createFetchResult());
  });

  ProviderContainer createContainer({
    Stream<InvalidationEvent>? sseStream,
  }) {
    return ProviderContainer(
      overrides: [
        uspFirewallDataServiceProvider.overrideWithValue(mockService),
        if (sseStream != null)
          sseInvalidationProvider.overrideWith((ref) => sseStream),
      ],
    );
  }

  group('FirewallDataNotifier', () {
    test('build maps the service fetch result into FirewallData', () async {
      final container = createContainer();
      final data = await container.read(firewallDataProvider.future);

      expect(data.firewallModel.isIPv4FirewallEnabled, isTrue);
      expect(data.ruleSummaries, hasLength(2));
      expect(data.ruleSummaries.first.target, 'Drop');
      expect(data.dmzModel.isEnabled, isFalse);
      expect(data.dmzSummaries, isEmpty);
      verify(() => mockService.fetch()).called(1);
      container.dispose();
    });

    test('build propagates a ServiceError from the service', () async {
      when(() => mockService.fetch())
          .thenThrow(const ServiceNotInitializedError(detail: 'no usp'));

      final container = createContainer();

      await expectLater(
        container.read(firewallDataProvider.future),
        throwsA(isA<ServiceNotInitializedError>()),
      );
      container.dispose();
    });

    test('FirewallData equality covers ruleContext and both summary lists', () {
      // props is overridden explicitly rather than derived from namedProps,
      // because namedProps only carries ruleSummaries.length — a rule whose
      // content changed without changing the count must still notify.
      final a = FirewallTestData.createFirewallData();
      final b = FirewallTestData.createFirewallData();
      final differentRules = FirewallTestData.createFirewallData(
        ruleSummaries: [
          FirewallTestData.createRuleSummary(target: 'Reject', enabled: true),
          FirewallTestData.createRuleSummary(target: 'Accept', enabled: false),
        ],
      );

      expect(a, equals(b));
      expect(a, isNot(equals(differentRules)));
      expect(a.props, [
        a.firewallModel,
        a.ruleContext,
        a.ruleSummaries,
        a.dmzModel,
        a.dmzSummaries,
      ]);
    });

    test('SSE firewallRules domain triggers debounced re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);

        container.listen(firewallDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockService);

        sseController.add((domain: InvalidationDomain.firewallRules, seq: 0));
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

    test('SSE dmz domain also triggers re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);

        container.listen(firewallDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockService);

        // Second branch of the OR-gate: DMZ lives under Device.Firewall.DMZ.
        sseController.add((domain: InvalidationDomain.dmz, seq: 0));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        verify(() => mockService.fetch()).called(1);

        sseController.close();
        container.dispose();
      });
    });

    // portForwarding is the sharpest wrong answer here: it is the other
    // NAT/firewall-adjacent domain, it is emitted by the same SSE path, and the
    // page next door listens to it — so a guard that matched "anything
    // firewall-ish" would pass a test using an obviously unrelated domain.
    test('SSE portForwarding domain does not trigger re-fetch', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);

        container.listen(firewallDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockService);

        sseController.add((domain: InvalidationDomain.portForwarding, seq: 0));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        verifyNever(() => mockService.fetch());

        sseController.close();
        container.dispose();
      });
    });

    // The two events are spaced past the 500ms debounce window on purpose:
    // inside it they are *meant* to merge into one refresh, so a repeat
    // asserted there could not tell a real collapse from the debouncer doing
    // its job. Same domain both times, so `seq` (#1501 AC-B1) is the only thing
    // that differs between the two events.
    test('two firewallRules events past the debounce window re-fetch twice',
        () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);

        container.listen(firewallDataProvider, (_, __) {});
        async.flushMicrotasks();
        clearInteractions(mockService);

        sseController.add((domain: InvalidationDomain.firewallRules, seq: 0));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();
        verify(() => mockService.fetch()).called(1);

        sseController.add((domain: InvalidationDomain.firewallRules, seq: 1));
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
