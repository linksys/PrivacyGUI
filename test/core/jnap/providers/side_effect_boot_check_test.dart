// Tests for the "is the router usable again" predicate the side-effect poll
// runs after any JNAP call that restarts the router.
//
// A connected WAN is the primary answer. Failing that, a router that has kept
// answering for the grace period also counts, so a reconnect whose WAN never
// returns finishes as a success instead of exhausting its retries and surfacing
// as a save failure. That escape hatch is measured against the current poll's
// start time, so it can only apply inside a poll — which is what these tests
// pin, along with the WAN answers themselves.
//
// The grace boundary itself is not unit-tested: crossing it takes a minute of
// wall clock, and faking the clock here would test the harness rather than the
// predicate. What is pinned is that without an active poll the grace cannot
// fire at all, which is the arm that decides whether a silent WAN reads as
// success.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

import '../../../mocks/router_repository_mocks.dart';

/// GetWANStatus payload. `macAddress`, `detectedWANType` and both status
/// fields are non-nullable on the model and read straight out of the map, so
/// omitting any of them makes `fromMap` throw and the predicate answers from its
/// error path instead of from the statuses under test.
JNAPSuccess _wanStatus({
  String ipv4 = 'Disconnected',
  String ipv6 = 'Disconnected',
}) =>
    JNAPSuccess(
      result: 'OK',
      output: {
        'macAddress': '00:11:22:33:44:55',
        'detectedWANType': 'DHCP',
        'wanStatus': ipv4,
        'wanIPv6Status': ipv6,
        'supportedWANTypes': <String>['DHCP'],
      },
    );

void main() {
  late MockRouterRepository mockRepo;
  late ProviderContainer container;
  late SideEffectNotifier notifier;

  setUp(() {
    mockRepo = MockRouterRepository();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(mockRepo),
    ]);
    notifier = container.read(sideEffectProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  void whenWanStatus(Future<JNAPSuccess> Function() answer) {
    when(mockRepo.send(
      any,
      data: anyNamed('data'),
      extraHeaders: anyNamed('extraHeaders'),
      auth: anyNamed('auth'),
      type: anyNamed('type'),
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((_) => answer());
  }

  test('a connected IPv4 WAN counts as booted', () async {
    whenWanStatus(() async => _wanStatus(ipv4: 'Connected'));

    final (booted, result) = await notifier.testRouterFullyBootedUp();

    expect(booted, isTrue);
    expect(result, isA<JNAPSuccess>());
  });

  test('a connected IPv6 WAN alone counts as booted', () async {
    whenWanStatus(
        () async => _wanStatus(ipv4: 'Disconnected', ipv6: 'Connected'));

    final (booted, _) = await notifier.testRouterFullyBootedUp();

    expect(booted, isTrue);
  });

  test('a disconnected WAN outside a poll is not booted', () async {
    // No poll is running, so there is no start time to measure the grace
    // against and the router answering proves nothing on its own. Before the
    // grace was tied to the poll, this arm read the call's own start time and
    // could never fire; it must not fire here either.
    whenWanStatus(
        () async => _wanStatus(ipv4: 'Disconnected', ipv6: 'Disconnected'));

    final (booted, _) = await notifier.testRouterFullyBootedUp();

    expect(booted, isFalse);
  });

  test('an unreachable router is not booted', () async {
    whenWanStatus(() => Future.error(const JNAPError(result: 'ErrorTimeout')));

    final (booted, result) = await notifier.testRouterFullyBootedUp();

    expect(booted, isFalse);
    expect(result, isNull);
  });
}
