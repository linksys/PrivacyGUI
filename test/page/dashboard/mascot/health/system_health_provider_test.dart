import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/system_health_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';

import '../../../../mocks/test_data/system_health_test_data.dart';

/// Lets riverpod commit an `AsyncNotifier` build/`_reEvaluate` result.
///
/// `flushMicrotasks()` is *not* enough here: the notifier's future resolves in
/// a microtask (the `[Mascot][Health]` log even prints), but the container only
/// publishes the resulting `AsyncData` on a later event-loop turn — reading
/// straight after a flush still returns `AsyncLoading`. 1 ms keeps every elapse
/// in these tests well clear of the 500 ms debounce window.
void settle(FakeAsync async) => async.elapse(const Duration(milliseconds: 1));

void main() {
  /// Mutable stand-in for the aggregate of six L1 providers. Overriding the
  /// context provider instead of the six providers keeps these tests about the
  /// SSE listener: the notifier reads the context with `ref.read` at evaluation
  /// time, so changing the holder between events is exactly how a real domain
  /// refresh becomes visible to the next evaluation.
  late StateProvider<HealthEvaluationContext> contextHolder;

  setUp(() {
    contextHolder = StateProvider<HealthEvaluationContext>(
      (ref) => SystemHealthTestData.createHealthyContext(),
    );
  });

  ProviderContainer createContainer({
    Stream<InvalidationEvent>? sseStream,
    bool dashboardReady = true,
  }) {
    return ProviderContainer(
      overrides: [
        // Pinned rather than inherited from kHealthDebounceDelay, so a config
        // change cannot silently turn these elapses into no-ops.
        systemHealthConfigProvider.overrideWithValue(
          const SystemHealthConfig(
            debounceDelay: Duration(milliseconds: 500),
            evaluationInterval: Duration(minutes: 5),
          ),
        ),
        healthEvaluationContextProvider
            .overrideWith((ref) => ref.watch(contextHolder)),
        dashboardDomainReadyProvider.overrideWith((ref) async {
          if (!dashboardReady) {
            // Never completes — stays AsyncLoading for the whole test.
            await Completer<void>().future;
          }
        }),
        if (sseStream != null)
          sseInvalidationProvider.overrideWith((ref) => sseStream),
      ],
    );
  }

  int? internetScore(ProviderContainer container) => container
      .read(systemHealthProvider)
      .valueOrNull
      ?.scores[HealthDimensionType.internet]
      ?.score;

  group('SystemHealthNotifier', () {
    test('build evaluates every registered dimension once dashboard is ready',
        () {
      fakeAsync((async) {
        final container = createContainer();
        container.listen(systemHealthProvider, (_, __) {});
        settle(async);

        final state = container.read(systemHealthProvider).valueOrNull!;
        expect(state.scores, isNotEmpty);
        expect(state.lastEvaluated, isNotNull);
        expect(state.isEvaluating, isFalse);
        // WAN up in the healthy context.
        expect(state.scores[HealthDimensionType.internet]?.score, 100);

        container.dispose();
      });
    });

    test('build holds the initial state while dashboard is not ready', () {
      fakeAsync((async) {
        final container = createContainer(dashboardReady: false);
        container.listen(systemHealthProvider, (_, __) {});
        settle(async);

        final state = container.read(systemHealthProvider).valueOrNull!;
        expect(state.scores, isEmpty);
        expect(state.lastEvaluated, isNull);
        expect(state.isEvaluating, isTrue);

        container.dispose();
      });
    });

    test('SSE wanStatus domain triggers a debounced re-evaluation', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);
        container.listen(systemHealthProvider, (_, __) {});
        settle(async);
        expect(internetScore(container), 100);

        // The WAN dropped; the next evaluation must see it.
        container.read(contextHolder.notifier).state =
            SystemHealthTestData.createWanDownContext();
        sseController.add((domain: InvalidationDomain.wanStatus, seq: 0));
        settle(async);

        // Timer pending — still the previous score.
        expect(internetScore(container), 100);

        async.elapse(const Duration(milliseconds: 500));
        settle(async);

        expect(internetScore(container), 0);

        sseController.close();
        container.dispose();
      });
    });

    test('SSE firewallRules domain also triggers a re-evaluation', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);
        container.listen(systemHealthProvider, (_, __) {});
        settle(async);
        expect(internetScore(container), 100);

        // firewallRules comes from the security dimension's watched set, not the
        // internet one — the guard is the union across all six dimensions, so
        // any member of it must re-evaluate *every* dimension.
        container.read(contextHolder.notifier).state =
            SystemHealthTestData.createWanDownContext();
        sseController.add((domain: InvalidationDomain.firewallRules, seq: 0));
        settle(async);
        async.elapse(const Duration(milliseconds: 500));
        settle(async);

        expect(internetScore(container), 0);

        sseController.close();
        container.dispose();
      });
    });

    // portForwarding is the sharpest wrong answer: it is an SSE domain the
    // dashboard genuinely emits and the neighbouring L1 provider watches, but
    // no health dimension does. The context is changed first, so a guard that
    // let anything through would flip the score and turn this red.
    test('SSE portForwarding domain does not trigger a re-evaluation', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);
        container.listen(systemHealthProvider, (_, __) {});
        settle(async);
        expect(internetScore(container), 100);

        container.read(contextHolder.notifier).state =
            SystemHealthTestData.createWanDownContext();
        sseController.add((domain: InvalidationDomain.portForwarding, seq: 0));
        settle(async);
        async.elapse(const Duration(milliseconds: 600));
        settle(async);

        expect(internetScore(container), 100);

        sseController.close();
        container.dispose();
      });
    });

    // Spaced past the 500ms debounce window on purpose — inside it the two
    // events are *meant* to merge, so a repeat asserted there could not tell a
    // real collapse from the debouncer doing its job. Same domain both times,
    // so `seq` (#1501 AC-B1) is the only difference between the two events, and
    // the score has to track the context across both.
    test('two wanStatus events past the debounce window each re-evaluate', () {
      fakeAsync((async) {
        final sseController = StreamController<InvalidationEvent>.broadcast();
        final container = createContainer(sseStream: sseController.stream);
        container.listen(systemHealthProvider, (_, __) {});
        settle(async);
        expect(internetScore(container), 100);

        // WAN goes down.
        container.read(contextHolder.notifier).state =
            SystemHealthTestData.createWanDownContext();
        sseController.add((domain: InvalidationDomain.wanStatus, seq: 0));
        settle(async);
        async.elapse(const Duration(milliseconds: 600));
        settle(async);
        expect(internetScore(container), 0);

        // WAN comes back. Second event, same domain.
        container.read(contextHolder.notifier).state =
            SystemHealthTestData.createHealthyContext();
        sseController.add((domain: InvalidationDomain.wanStatus, seq: 1));
        settle(async);
        async.elapse(const Duration(milliseconds: 600));
        settle(async);
        expect(internetScore(container), 100);

        sseController.close();
        container.dispose();
      });
    });
  });
}
