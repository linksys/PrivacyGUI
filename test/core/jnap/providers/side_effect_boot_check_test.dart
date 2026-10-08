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
// The reference time is now a parameter rather than a field shared by every
// poll, which is what makes the grace boundary testable at all: a caller can
// hand in a start time already past it instead of waiting a minute. Both sides
// of that boundary are pinned below.

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

  /// A poll that started just now, so the grace has not elapsed.
  int justStarted() => DateTime.now().millisecondsSinceEpoch;

  /// A poll that started long enough ago for the grace to have elapsed.
  int startedBeforeGrace() =>
      DateTime.now().millisecondsSinceEpoch -
      SideEffectNotifier.routerRespondingGrace.inMilliseconds -
      1000;

  test('a connected IPv4 WAN counts as booted', () async {
    whenWanStatus(() async => _wanStatus(ipv4: 'Connected'));

    final (booted, result) = await notifier.testRouterFullyBootedUp(
      justStarted(),
    );

    expect(booted, isTrue);
    expect(result, isA<JNAPSuccess>());
  });

  test('a connected IPv6 WAN alone counts as booted', () async {
    whenWanStatus(
        () async => _wanStatus(ipv4: 'Disconnected', ipv6: 'Connected'));

    final (booted, _) = await notifier.testRouterFullyBootedUp(justStarted());

    expect(booted, isTrue);
  });

  test('a disconnected WAN inside the grace is not booted', () async {
    whenWanStatus(
        () async => _wanStatus(ipv4: 'Disconnected', ipv6: 'Disconnected'));

    final (booted, _) = await notifier.testRouterFullyBootedUp(justStarted());

    expect(booted, isFalse);
  });

  test('a router answering past the grace counts as booted with the WAN down',
      () async {
    // The arm that turns a never-connecting WAN into a reported success. It was
    // unreachable from a test while the reference time lived on the notifier,
    // because only a real poll set it.
    whenWanStatus(
        () async => _wanStatus(ipv4: 'Disconnected', ipv6: 'Disconnected'));

    final (booted, _) =
        await notifier.testRouterFullyBootedUp(startedBeforeGrace());

    expect(booted, isTrue);
  });

  test('an unreachable router is not booted even past the grace', () async {
    // The grace needs the router to be answering; a failed read is not an
    // answer, so it cannot satisfy it.
    whenWanStatus(() => Future.error(const JNAPError(result: 'ErrorTimeout')));

    final (booted, _) =
        await notifier.testRouterFullyBootedUp(startedBeforeGrace());

    expect(booted, isFalse);
  });

  test('an unreachable router is not booted', () async {
    whenWanStatus(() => Future.error(const JNAPError(result: 'ErrorTimeout')));

    final (booted, result) = await notifier.testRouterFullyBootedUp(
      justStarted(),
    );

    expect(booted, isFalse);
    expect(result, isNull);
  });
}
