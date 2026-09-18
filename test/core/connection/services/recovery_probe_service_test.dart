// #1323 (phases 4-5 of epic #1474): the recovery probe is one service that asks
// the mode's strategies, not a service hard-coded to the local answers.
//
// WHAT CHANGED, AND WHY THIS FILE WAS RETARGETED RATHER THAN REPLACED. The eight
// cases below are the eight this file already had. They are kept verbatim in
// substance — same stubs, same expectations — and re-run through the *local*
// strategy triple, which is the claim that #1323 moved the mode `if`s without
// changing local behaviour. If a local case here needed its expectation changed,
// the seam was wrong.
//
// The second group is the new half: the same probe with the *remote* triple. It
// is where the bug lived. Before this change the probe's three steps were:
//
//   1. `bridge.health()` — a Guardian endpoint that does not exist.
//      `BridgeEndpoints.remote()` has a `health` path, Guardian serves nothing
//      there, so step 1 could only ever fail remotely.
//   2. `restoreSession(isRecovering: true)` — a refresh of a
//      `temporaryAccessToken`, which cannot be refreshed. Guardian's answer does
//      not change with time.
//   3. `fingerprintService.matches(serial)` — compared against a serial stored at
//      *local* login. A support session never wrote one, and `matches()` returns
//      false for a null stored value, so a recovered RA session reported
//      `serialMismatch` — which the caller turned into a forced logout with the
//      Guardian session still alive. That is acceptances 4 and 5 of #1323.
//
// So the remote assertions are as much about `verifyNever` as about the return
// value: reaching `restoreSession` or `matches` at all is the defect, and a probe
// that reached them and happened to return `recovered` (because a test stubbed
// them generously) would still be broken in production.
//
// WHY A CONTAINER AND NOT THREE CONSTRUCTOR MOCKS. The service no longer holds
// the bridge, the coordinator or the fingerprint store — *which* of those a probe
// touches is the mode's answer, so the strategies resolve them from a [Ref]. The
// pre-#1323 provider resolved all three eagerly and wrote `bridge!`, which threw
// a TypeError when a session ended while a probe loop was still running. Mocking
// at the provider seam is what lets both triples run the same cases.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

class MockUspBridgeClient extends Mock implements UspBridgeClient {}

class MockUspClient extends Mock implements UspClient {}

class MockUspAuthCoordinator extends Mock implements UspAuthCoordinator {}

class MockRouterFingerprintService extends Mock
    implements RouterFingerprintService {}

/// The path `RemoteTransportStrategy.isRouterReachable` reads. Cheapest always
/// present parameter on the object model; reaching it proves the whole chain
/// browser → Guardian → agent → OBUSPA → box is carrying traffic.
const _kReachabilityPath = 'Device.DeviceInfo.SerialNumber';

void main() {
  late MockUspBridgeClient mockBridge;
  late MockUspClient mockUsp;
  late MockUspAuthCoordinator mockAuth;
  late MockRouterFingerprintService mockFingerprint;
  late ProviderContainer container;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    mockUsp = MockUspClient();
    mockAuth = MockUspAuthCoordinator();
    mockFingerprint = MockRouterFingerprintService();
  });

  tearDown(() => container.dispose());

  /// Builds the service for [profile]'s triple.
  ///
  /// Every dependency of both modes is overridden every time, so a probe that
  /// reaches the *other* mode's dependency gets a mock rather than a null — a
  /// null would fail for the wrong reason and hide the `verifyNever` below.
  RecoveryProbeService serviceFor({required bool remote}) {
    container = ProviderContainer(overrides: [
      if (remote)
        appModeProfileProvider.overrideWithValue(const RemoteModeProfile())
      else
        appModeProfileProvider.overrideWithValue(const LocalModeProfile()),
      uspBridgeClientProvider.overrideWithValue(mockBridge),
      uspClientProvider.overrideWithValue(mockUsp),
      uspAuthCoordinatorProvider.overrideWithValue(mockAuth),
      routerFingerprintServiceProvider.overrideWithValue(mockFingerprint),
    ]);
    return container.read(recoveryProbeServiceProvider);
  }

  Map<String, dynamic> healthyResponse() => {
        'status': 'healthy',
        'agent_connected': true,
        'agent_state': 'ready',
      };

  void stubReachableRemotely() {
    when(() => mockUsp.get([_kReachabilityPath]))
        .thenAnswer((_) async => {_kReachabilityPath: 'ABC123'});
  }

  group('local triple — the eight pre-#1323 cases, unchanged', () {
    late RecoveryProbeService service;

    setUp(() => service = serviceFor(remote: false));

    test('returns unreachable when health check fails', () async {
      when(() => mockBridge.health()).thenThrow(Exception('network error'));

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
    });

    test('returns unreachable when agent not connected', () async {
      when(() => mockBridge.health()).thenAnswer((_) async => {
            'status': 'healthy',
            'agent_connected': false,
            'agent_state': 'connecting',
          });

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
    });

    test('returns unreachable when agent_state is not ready', () async {
      when(() => mockBridge.health()).thenAnswer((_) async => {
            'status': 'healthy',
            'agent_connected': true,
            'agent_state': 'connecting',
          });

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
    });

    test('returns unreachable when health response missing agent fields',
        () async {
      when(() => mockBridge.health()).thenAnswer((_) async => {});

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
    });

    test('returns unreachable when health OK but login fails', () async {
      when(() => mockBridge.health())
          .thenAnswer((_) async => healthyResponse());
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenThrow(Exception('login failed'));

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() => mockFingerprint.matches(any()));
    });

    test('returns recovered when health OK, login OK, serial matches',
        () async {
      when(() => mockBridge.health())
          .thenAnswer((_) async => healthyResponse());
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenAnswer((_) async {});
      when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'ABC123');
      when(() => mockFingerprint.matches('ABC123'))
          .thenAnswer((_) async => true);

      final result = await service.probe();

      expect(result, ProbeResult.recovered);
    });

    test('returns serialMismatch when health OK, login OK, serial differs',
        () async {
      when(() => mockBridge.health())
          .thenAnswer((_) async => healthyResponse());
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenAnswer((_) async {});
      when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'XYZ789');
      when(() => mockFingerprint.matches('XYZ789'))
          .thenAnswer((_) async => false);

      final result = await service.probe();

      expect(result, ProbeResult.serialMismatch);
    });

    test('returns unreachable when health OK, login OK, serial read fails',
        () async {
      when(() => mockBridge.health())
          .thenAnswer((_) async => healthyResponse());
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenAnswer((_) async {});
      when(() => mockAuth.getSerialNumber()).thenThrow(Exception('USP error'));

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
    });

    test('healthOnly stops after reachability', () async {
      when(() => mockBridge.health())
          .thenAnswer((_) async => healthyResponse());

      final result = await service.probe(healthOnly: true);

      expect(result, ProbeResult.recovered);
      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
      verifyNever(() => mockFingerprint.matches(any()));
    });

    test('reads reachability from the bridge, not from a USP Get', () async {
      // The negative half of the remote group's first test: the two modes must
      // not both be doing both things. A local probe that also issued the
      // Guardian read would pass every expectation above while doubling the
      // requests a booting router receives.
      when(() => mockBridge.health())
          .thenAnswer((_) async => healthyResponse());
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenAnswer((_) async {});
      when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'ABC123');
      when(() => mockFingerprint.matches('ABC123'))
          .thenAnswer((_) async => true);

      await service.probe();

      verify(() => mockBridge.health()).called(1);
      verifyNever(() => mockUsp.get(any()));
    });
  });

  group('remote triple — acceptances 4 and 5 of #1323', () {
    late RecoveryProbeService service;

    setUp(() => service = serviceFor(remote: true));

    test(
        'a reachable Guardian session recovers without touching the '
        'coordinator or the fingerprint store', () async {
      stubReachableRemotely();

      final result = await service.probe();

      expect(result, ProbeResult.recovered,
          reason: 'this is the red-to-green: before #1323 the same situation '
              'produced serialMismatch and a forced logout, because no '
              'fingerprint was ever stored for a support session and '
              'matches(null) is false');
      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
      verifyNever(() => mockFingerprint.matches(any()));
      verifyNever(() => mockAuth.getSerialNumber());
    });

    test('never calls the fabricated Guardian health endpoint', () async {
      stubReachableRemotely();

      await service.probe();

      verifyNever(() => mockBridge.health());
      verify(() => mockUsp.get([_kReachabilityPath])).called(1);
    });

    test('a failed Guardian read is unreachable, not a mismatch', () async {
      when(() => mockUsp.get([_kReachabilityPath]))
          .thenThrow(Exception('502 from the proxy'));

      final result = await service.probe();

      expect(result, ProbeResult.unreachable,
          reason: 'a transient proxy failure must keep the app waiting. '
              'serialMismatch is terminal — it force-logs-out — and the '
              'Guardian session may well still be alive');
    });

    test('a 200 that omits the parameter is unreachable', () async {
      // Guardian answers 200 with an empty result set while the agent is
      // reconnecting to the router, so "the request succeeded" is not "the box
      // is back".
      when(() => mockUsp.get([_kReachabilityPath]))
          .thenAnswer((_) async => <String, dynamic>{});

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
    });

    test('never returns serialMismatch, whatever the fingerprint store says',
        () async {
      stubReachableRemotely();
      // Stubbed to the value that used to force the logout. Guardian binds a
      // session to one serial server-side, so "a different router answered" is
      // not a reachable state remotely and this store must not get a vote.
      when(() => mockFingerprint.matches(any())).thenAnswer((_) async => false);

      final result = await service.probe();

      expect(result, ProbeResult.recovered);
    });

    test('healthOnly recovers on the Guardian read alone', () async {
      stubReachableRemotely();

      final result = await service.probe(healthOnly: true);

      expect(result, ProbeResult.recovered);
      verifyNever(() => mockBridge.health());
    });

    test('no UspClient yet is unreachable, not a crash', () async {
      // The window `RemoteTransportStrategy.bridgeConfig` documents: the mode is
      // known at build time, the session only when the agent opens its link. The
      // pre-#1323 provider wrote `bridge!` here and threw.
      container.dispose();
      container = ProviderContainer(overrides: [
        appModeProfileProvider.overrideWithValue(const RemoteModeProfile()),
        uspClientProvider.overrideWithValue(null),
      ]);

      final result = await container.read(recoveryProbeServiceProvider).probe();

      expect(result, ProbeResult.unreachable);
    });
  });
}
