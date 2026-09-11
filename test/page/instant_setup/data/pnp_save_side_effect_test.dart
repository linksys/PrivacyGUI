import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

class _WANStatusRepository extends Fake implements RouterRepository {
  bool reachable = true;
  String wanStatus = 'Disconnected';
  String wanIPv6Status = 'Disconnected';
  int probes = 0;

  @override
  Future<JNAPSuccess> send(
    JNAPAction action, {
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeaders = const {},
    bool auth = false,
    CommandType? type,
    bool fetchRemote = false,
    CacheLevel? cacheLevel,
    int timeoutMs = 10000,
    int retries = 1,
    JNAPSideEffectOverrides? sideEffectOverrides,
  }) async {
    expect(action, JNAPAction.getWANStatus);
    expect(fetchRemote, isTrue);
    expect(cacheLevel, CacheLevel.noCache);
    expect(timeoutMs, 3000);
    expect(retries, 0);
    probes++;
    if (!reachable) {
      throw TimeoutException('Router is not responding');
    }
    return JNAPSuccess(result: 'OK', output: {
      'macAddress': '00:11:22:33:44:55',
      'detectedWANType': 'IPoE',
      'wanStatus': wanStatus,
      'wanIPv6Status': wanIPv6Status,
      'supportedWANTypes': const ['DHCP', 'PPPoE', 'IPoE'],
    });
  }
}

ProviderContainer _container(_WANStatusRepository repository) {
  final container = ProviderContainer(overrides: [
    routerRepositoryProvider.overrideWithValue(repository),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  for (final connectedStack in ['IPv4', 'IPv6']) {
    test('stock recovery returns early when $connectedStack is connected',
        () async {
      final repository = _WANStatusRepository();
      if (connectedStack == 'IPv4') {
        repository.wanStatus = 'Connected';
      } else {
        repository.wanIPv6Status = 'Connected';
      }
      final notifier = _container(repository).read(sideEffectProvider.notifier);

      final result = await notifier.poll(
        pollFunc: notifier.testRouterFullyBootedUp,
        timeDelayStartInSec: 0,
        retryDelayInSec: 0,
        maxRetry: 0,
        maxPollTimeInSec: 1,
      );

      expect(result, isTrue);
      expect(repository.probes, 1);
    });
  }

  test('stock recovery fails when the router remains unreachable', () async {
    final repository = _WANStatusRepository()..reachable = false;
    final notifier = _container(repository).read(sideEffectProvider.notifier);

    await expectLater(
      notifier.poll(
        pollFunc: notifier.testRouterFullyBootedUp,
        timeDelayStartInSec: 0,
        retryDelayInSec: 0,
        maxRetry: 1,
        maxPollTimeInSec: 1,
      ),
      throwsA(isA<JNAPSideEffectError>()),
    );

    expect(repository.probes, 2);
  });

  test(
    'stock recovery shares its elapsed start across probes and resets it after completion',
    () async {
      final repository = _WANStatusRepository();
      final notifier = _container(repository).read(sideEffectProvider.notifier);

      final result = await notifier.poll(
        pollFunc: () async {
          // A responding router with no native WAN connection is not ready
          // immediately. The native fallback is router recovery, not an
          // Internet check; PnP performs its ICC check separately.
          expect((await notifier.testRouterFullyBootedUp()).$1, isFalse);

          // Production intentionally uses DateTime.now(), which FakeAsync
          // does not replace. One real-time boundary test avoids adding a
          // production clock override solely for this regression test.
          await Future<void>.delayed(const Duration(seconds: 61));

          repository.reachable = false;
          expect((await notifier.testRouterFullyBootedUp()).$1, isFalse,
              reason: 'Elapsed time must never bypass a failed JNAP request');

          repository.reachable = true;
          final recovered = await notifier.testRouterFullyBootedUp();
          expect(recovered.$1, isTrue,
              reason: 'Both WAN statuses may remain disconnected for IPoE');
          return recovered;
        },
        timeDelayStartInSec: 0,
        retryDelayInSec: 0,
        maxRetry: 0,
        maxPollTimeInSec: 70,
      );
      expect(result, isTrue);

      // Neither a direct probe nor another save may inherit a completed
      // operation's 60-second recovery allowance.
      expect((await notifier.testRouterFullyBootedUp()).$1, isFalse);
      await expectLater(
        notifier.poll(
          pollFunc: notifier.testRouterFullyBootedUp,
          timeDelayStartInSec: 0,
          retryDelayInSec: 0,
          maxRetry: 0,
          maxPollTimeInSec: 1,
        ),
        throwsA(isA<JNAPSideEffectError>()),
      );
      expect((await notifier.testRouterFullyBootedUp()).$1, isFalse);
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
