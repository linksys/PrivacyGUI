import 'dart:async';

import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // Basic functionality
  // -----------------------------------------------------------------------
  group('basic', () {
    test('executes a single request', () async {
      final throttler = BridgeRequestThrottler();
      final result = await throttler.enqueue(
        cacheKey: 'test:1',
        action: () async => 42,
      );
      expect(result, 42);
    });

    test('executes multiple requests sequentially when maxConcurrent=1',
        () async {
      final throttler = BridgeRequestThrottler(
        maxConcurrent: 1,
        staggerDelay: Duration.zero,
      );
      final order = <int>[];

      final f1 = throttler.enqueue(
        cacheKey: 'a',
        action: () async {
          order.add(1);
          await Future.delayed(Duration(milliseconds: 50));
          return 'a';
        },
      );
      final f2 = throttler.enqueue(
        cacheKey: 'b',
        action: () async {
          order.add(2);
          return 'b';
        },
      );

      await Future.wait([f1, f2]);
      expect(order, [1, 2]);
    });

    test('propagates errors from action', () async {
      final throttler = BridgeRequestThrottler();
      expect(
        () => throttler.enqueue(
          cacheKey: 'err',
          action: () async => throw StateError('boom'),
        ),
        throwsStateError,
      );
    });
  });

  // -----------------------------------------------------------------------
  // Concurrency limiting
  // -----------------------------------------------------------------------
  group('concurrency limit', () {
    test('respects maxConcurrent', () async {
      final throttler = BridgeRequestThrottler(
        maxConcurrent: 2,
        staggerDelay: Duration.zero,
      );

      var peakConcurrent = 0;
      var currentConcurrent = 0;
      final completers = List.generate(5, (_) => Completer<void>());

      final futures = <Future>[];
      for (var i = 0; i < 5; i++) {
        final idx = i;
        futures.add(throttler.enqueue(
          cacheKey: 'c$i',
          action: () async {
            currentConcurrent++;
            if (currentConcurrent > peakConcurrent) {
              peakConcurrent = currentConcurrent;
            }
            await completers[idx].future;
            currentConcurrent--;
          },
        ));
      }

      // Let first batch start
      await Future.delayed(Duration(milliseconds: 20));
      expect(throttler.activeCount, 2);
      expect(peakConcurrent, 2);

      // Complete first two
      completers[0].complete();
      completers[1].complete();
      await Future.delayed(Duration(milliseconds: 20));

      // Next batch should start
      expect(peakConcurrent, 2); // Never exceeded 2

      // Complete remaining
      for (var i = 2; i < 5; i++) {
        completers[i].complete();
      }
      await Future.wait(futures);
    });

    test('activeCount and queueLength are accurate', () async {
      final throttler = BridgeRequestThrottler(
        maxConcurrent: 1,
        staggerDelay: Duration.zero,
      );
      final blocker = Completer<void>();

      final f1 = throttler.enqueue(
        cacheKey: 'x1',
        action: () => blocker.future,
      );

      await Future.delayed(Duration(milliseconds: 10));
      expect(throttler.activeCount, 1);

      // Queue a second one
      final f2 = throttler.enqueue(
        cacheKey: 'x2',
        action: () async => 'done',
      );
      expect(throttler.queueLength, 1);

      blocker.complete();
      await Future.wait([f1, f2]);
      expect(throttler.activeCount, 0);
      expect(throttler.queueLength, 0);
    });
  });

  // -----------------------------------------------------------------------
  // Cache dedup
  // -----------------------------------------------------------------------
  group('cache dedup', () {
    test('same cacheKey returns cached result within TTL', () async {
      final throttler = BridgeRequestThrottler(
        defaultCacheTtl: Duration(seconds: 10),
      );
      var callCount = 0;

      final r1 = await throttler.enqueue(
        cacheKey: 'dup',
        action: () async {
          callCount++;
          return 'result';
        },
      );
      final r2 = await throttler.enqueue(
        cacheKey: 'dup',
        action: () async {
          callCount++;
          return 'should not run';
        },
      );

      expect(r1, 'result');
      expect(r2, 'result');
      expect(callCount, 1);
    });

    test('expired cache triggers new action', () async {
      final throttler = BridgeRequestThrottler(
        defaultCacheTtl: Duration(milliseconds: 50),
      );
      var callCount = 0;

      await throttler.enqueue(
        cacheKey: 'expire',
        action: () async {
          callCount++;
          return 'first';
        },
      );

      // Wait for cache to expire
      await Future.delayed(Duration(milliseconds: 80));

      final r2 = await throttler.enqueue(
        cacheKey: 'expire',
        action: () async {
          callCount++;
          return 'second';
        },
      );

      expect(r2, 'second');
      expect(callCount, 2);
    });

    test('concurrent identical cacheKeys share one in-flight Future', () async {
      final throttler = BridgeRequestThrottler(
        maxConcurrent: 1,
        staggerDelay: Duration.zero,
      );
      var callCount = 0;

      // First request starts executing (occupies the slot)
      final f0 = throttler.enqueue(
        cacheKey: 'blocker',
        action: () async {
          await Future.delayed(Duration(milliseconds: 50));
          return 'block';
        },
      );

      // Two requests with same cacheKey queued
      final f1 = throttler.enqueue(
        cacheKey: 'same',
        action: () async {
          callCount++;
          return 'shared';
        },
      );
      final f2 = throttler.enqueue(
        cacheKey: 'same',
        action: () async {
          callCount++;
          return 'should not run';
        },
      );

      await f0;
      final results = await Future.wait([f1, f2]);
      expect(results, ['shared', 'shared']);
      expect(callCount, 1);
    });

    test('clearCache forces new execution', () async {
      final throttler = BridgeRequestThrottler(
        defaultCacheTtl: Duration(seconds: 60),
      );
      var callCount = 0;

      await throttler.enqueue(
        cacheKey: 'clear',
        action: () async {
          callCount++;
          return 'v1';
        },
      );

      throttler.clearCache();

      final r2 = await throttler.enqueue(
        cacheKey: 'clear',
        action: () async {
          callCount++;
          return 'v2';
        },
      );

      expect(r2, 'v2');
      expect(callCount, 2);
    });
  });

  // -----------------------------------------------------------------------
  // Priority ordering
  // -----------------------------------------------------------------------
  group('priority', () {
    test('high priority dispatched before low', () async {
      final throttler = BridgeRequestThrottler(
        maxConcurrent: 1,
        staggerDelay: Duration.zero,
      );
      final order = <String>[];
      final blocker = Completer<void>();

      // Occupy the only slot
      final f0 = throttler.enqueue(
        cacheKey: 'block',
        action: () => blocker.future,
      );

      // Queue low, then high — high should run first after blocker
      final fLow = throttler.enqueue(
        cacheKey: 'low',
        priority: RequestPriority.low,
        action: () async {
          order.add('low');
        },
      );
      final fHigh = throttler.enqueue(
        cacheKey: 'high',
        priority: RequestPriority.high,
        action: () async {
          order.add('high');
        },
      );

      blocker.complete();
      await Future.wait([f0, fLow, fHigh]);
      expect(order, ['high', 'low']);
    });

    test('same priority maintains FIFO order', () async {
      final throttler = BridgeRequestThrottler(
        maxConcurrent: 1,
        staggerDelay: Duration.zero,
      );
      final order = <int>[];
      final blocker = Completer<void>();

      final f0 = throttler.enqueue(
        cacheKey: 'block',
        action: () => blocker.future,
      );

      final futures = <Future>[];
      for (var i = 0; i < 4; i++) {
        final idx = i;
        futures.add(throttler.enqueue(
          cacheKey: 'fifo$i',
          action: () async {
            order.add(idx);
          },
        ));
      }

      blocker.complete();
      await f0;
      await Future.wait(futures);
      expect(order, [0, 1, 2, 3]);
    });
  });

  // -----------------------------------------------------------------------
  // In-flight dedup
  // -----------------------------------------------------------------------
  group('in-flight dedup', () {
    test('same cacheKey during in-flight shares the Future', () async {
      final throttler = BridgeRequestThrottler(
        maxConcurrent: 2,
        staggerDelay: Duration.zero,
      );
      var callCount = 0;
      final blocker = Completer<String>();

      // Request A starts executing (in-flight)
      final fA = throttler.enqueue(
        cacheKey: 'inflight',
        action: () {
          callCount++;
          return blocker.future;
        },
      );

      // Let A get dispatched
      await Future.delayed(Duration(milliseconds: 10));
      expect(throttler.activeCount, 1);

      // Request B with same cacheKey — should dedup against in-flight A
      final fB = throttler.enqueue(
        cacheKey: 'inflight',
        action: () async {
          callCount++;
          return 'should not run';
        },
      );

      blocker.complete('shared-result');
      final results = await Future.wait([fA, fB]);
      expect(results, ['shared-result', 'shared-result']);
      expect(callCount, 1, reason: 'Action should run only once');
    });

    test('in-flight dedup cleared after completion', () async {
      final throttler = BridgeRequestThrottler(
        staggerDelay: Duration.zero,
        defaultCacheTtl: Duration.zero,
      );

      await throttler.enqueue(
        cacheKey: 'once',
        action: () async => 'first',
      );

      // Cache expired (TTL=0), in-flight cleared → new action should run
      await Future.delayed(Duration(milliseconds: 5));
      final r2 = await throttler.enqueue(
        cacheKey: 'once',
        action: () async => 'second',
      );
      expect(r2, 'second');
    });
  });

  // -----------------------------------------------------------------------
  // Per-request timeout
  // -----------------------------------------------------------------------
  group('request timeout', () {
    test('slow action is timed out and slot freed', () async {
      final throttler = BridgeRequestThrottler(
        maxConcurrent: 1,
        staggerDelay: Duration.zero,
        requestTimeout: Duration(milliseconds: 100),
      );

      // Slow action that would take forever
      final slow = throttler.enqueue(
        cacheKey: 'slow',
        action: () => Completer<String>().future, // never completes
      );

      // Fast action queued behind
      final fast = throttler.enqueue(
        cacheKey: 'fast',
        action: () async => 'done',
      );

      // slow should timeout, then fast should execute
      expect(slow, throwsA(isA<TimeoutException>()));
      final fastResult = await fast;
      expect(fastResult, 'done');
      expect(throttler.activeCount, 0);
    });

    test('fast action completes before timeout', () async {
      final throttler = BridgeRequestThrottler(
        requestTimeout: Duration(seconds: 5),
      );

      final result = await throttler.enqueue(
        cacheKey: 'quick',
        action: () async => 42,
      );
      expect(result, 42);
    });
  });

  // -----------------------------------------------------------------------
  // Edge cases
  // -----------------------------------------------------------------------
  group('edge cases', () {
    test('zero cacheTtl always re-executes', () async {
      final throttler = BridgeRequestThrottler();
      var callCount = 0;

      await throttler.enqueue(
        cacheKey: 'zero',
        cacheTtl: Duration.zero,
        action: () async {
          callCount++;
          return 'a';
        },
      );

      // Tiny delay to ensure cache expires
      await Future.delayed(Duration(milliseconds: 1));

      await throttler.enqueue(
        cacheKey: 'zero',
        cacheTtl: Duration.zero,
        action: () async {
          callCount++;
          return 'b';
        },
      );

      expect(callCount, 2);
    });

    test('different cacheKeys run independently', () async {
      final throttler = BridgeRequestThrottler();
      var count = 0;

      await Future.wait([
        throttler.enqueue(cacheKey: 'k1', action: () async => count++),
        throttler.enqueue(cacheKey: 'k2', action: () async => count++),
        throttler.enqueue(cacheKey: 'k3', action: () async => count++),
      ]);

      expect(count, 3);
    });

    test('typed results preserve type', () async {
      final throttler = BridgeRequestThrottler();

      final intResult = await throttler.enqueue<int>(
        cacheKey: 'int',
        action: () async => 42,
      );
      final mapResult = await throttler.enqueue<Map<String, dynamic>>(
        cacheKey: 'map',
        action: () async => {'key': 'value'},
      );

      expect(intResult, isA<int>());
      expect(mapResult, isA<Map<String, dynamic>>());
      expect(mapResult['key'], 'value');
    });
  });
}
