// #1323 phase 4: the three contract members recovery now asks the mode for —
// `ProximityStrategy.planFor`, `CredentialStrategy.reestablishAfterOutage` and
// `CredentialStrategy.onCredentialRebound`.
//
// One file, not three, because the point of every test below is a *difference*
// between the two modes' answers to the same question. Split across
// `local_proximity_strategy_test.dart` and `remote_proximity_strategy_test.dart`
// each half reads as an arbitrary table of constants; side by side the tables are
// the specification. Article XVII's discipline — "a member needs a measured
// difference" — is only checkable in this shape.
//
// `test/core/connection/services/recovery_probe_service_test.dart` covers the
// *composition* of these answers, and the transport member from the probe's point
// of view. This file covers each member alone.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/mode/impl/local_credential_strategy.dart';
import 'package:privacy_gui/core/mode/impl/local_proximity_strategy.dart';
import 'package:privacy_gui/core/mode/impl/remote_credential_strategy.dart';
import 'package:privacy_gui/core/mode/impl/remote_proximity_strategy.dart';
import 'package:privacy_gui/core/mode/impl/remote_transport_strategy.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
import 'package:privacy_gui/framework/mode/recovery_plan.dart';

class MockUspClient extends Mock implements UspClient {}

class MockUspAuthCoordinator extends Mock implements UspAuthCoordinator {}

class MockRouterFingerprintService extends Mock
    implements RouterFingerprintService {}

void main() {
  group('ProximityStrategy.planFor', () {
    test('locally every trigger needs recovery, at the pre-#1323 10s cadence',
        () {
      const strategy = LocalProximityStrategy();

      // The full enum, spelled out rather than iterated: iterating would assert
      // "whatever the implementation does, it does uniformly", which is the one
      // thing already guaranteed by the `switch` having no `default:`. The
      // interesting claim is the *values*, and 10 seconds is the interval
      // `_startProbeLoop` hard-coded before the plan existed.
      for (final trigger in RecoveryTrigger.values) {
        expect(
            strategy.planFor(trigger),
            const RecoveryPlan(
                needsRecovery: true, probeInterval: Duration(seconds: 10)),
            reason: '$trigger changed locally — #1323 must not do that');
      }
    });

    test('remotely a Wi-Fi change alone needs no recovery', () {
      const strategy = RemoteProximityStrategy();

      // The measured difference the whole member exists for. The Guardian path
      // runs browser → cloud → WAN uplink → agent; the radios a Wi-Fi change
      // restarts are not on it. Locally the same mutation drops the operator's
      // own association and is the single most common recovery trigger there is.
      expect(strategy.planFor(RecoveryTrigger.operationalWifiChange),
          const RecoveryPlan.notNeeded());
    });

    test('remotely everything that restarts the box does need recovery, at 30s',
        () {
      const strategy = RemoteProximityStrategy();

      for (final trigger in const [
        RecoveryTrigger.natural,
        RecoveryTrigger.operationalReboot,
        RecoveryTrigger.operationalFactoryReset,
        RecoveryTrigger.operationalFirmwareUpgrade,
      ]) {
        expect(
            strategy.planFor(trigger),
            const RecoveryPlan(
                needsRecovery: true, probeInterval: Duration(seconds: 30)),
            reason: '$trigger takes the agent down with the box, so the '
                'Guardian path breaks too');
      }
    });

    test('the two modes disagree on exactly one trigger', () {
      // Stated as a count so that adding a second divergence has to be a
      // deliberate edit here. A member whose two implementations agree
      // everywhere is a member that should not be on the contract; a member
      // whose implementations diverge in a place nobody wrote down is the shape
      // the 15 scattered `if (isRemote)` reads had.
      const local = LocalProximityStrategy();
      const remote = RemoteProximityStrategy();

      final differing = RecoveryTrigger.values
          .where((t) => local.planFor(t) != remote.planFor(t))
          .toList();

      expect(differing.length, RecoveryTrigger.values.length,
          reason: 'the cadence differs for every trigger — only '
              'operationalWifiChange also differs in *whether* to recover');
      expect(
        RecoveryTrigger.values
            .where((t) =>
                local.planFor(t).needsRecovery !=
                remote.planFor(t).needsRecovery)
            .toList(),
        [RecoveryTrigger.operationalWifiChange],
      );
    });
  });

  // #1496 phase 6. The second member of the same contract, and the **one place**
  // the operation policy is written as literal expectations. `OperationGuard` is a
  // delegation and its own test asserts only that; acceptance 6's substance —
  // factory reset and local firmware upload are refused in Remote Assistance —
  // is here, side by side with the mode that allows them, because the pair of
  // tables is the specification and either one alone reads as arbitrary.
  group('ProximityStrategy.canRecoverFrom', () {
    test('locally nothing is unrecoverable', () {
      const strategy = LocalProximityStrategy();

      for (final disruption in DisruptionClass.values) {
        expect(strategy.canRecoverFrom(disruption), isTrue,
            reason: '${disruption.name} became unrecoverable locally. Nothing '
                'in #1496 may take an operation away from the local build: the '
                'operator can power cycle, re-cable and read the label on the '
                'box, which is the whole content of "proximity".');
      }
    });

    test('remotely a lost credential or a lost path is not recoverable', () {
      const strategy = RemoteProximityStrategy();

      // Factory reset. The reset restores the password printed on the sticker,
      // and there is no sticker in the agent's building — so the Guardian
      // session is left proxying a login that no longer exists.
      expect(strategy.canRecoverFrom(DisruptionClass.credentialLoss), isFalse);

      // Local firmware upload. `firmware_local_upload_service.dart` derives the
      // host from `window.location`, which under RA is Guardian rather than the
      // router. This one is not a policy choice, it is a bug being named.
      expect(strategy.canRecoverFrom(DisruptionClass.transportLoss), isFalse);
    });

    test('remotely a restart is, because the box comes back on its own', () {
      // The half that is easy to lose. An agent's two most common needs are a
      // reboot and a cloud OTA upgrade, and both look as destructive as a
      // factory reset from the UI. Classifying by consequence is what keeps them
      // available; a guard that refused everything disruptive would be worse
      // than no guard, because it would be shipped and then worked around.
      expect(
          const RemoteProximityStrategy()
              .canRecoverFrom(DisruptionClass.transientRestart),
          isTrue);
    });

    test('the two modes disagree on exactly two classes', () {
      const local = LocalProximityStrategy();
      const remote = RemoteProximityStrategy();

      final differing = DisruptionClass.values
          .where((d) => local.canRecoverFrom(d) != remote.canRecoverFrom(d))
          .map((d) => d.name)
          .toList();

      expect(
        differing,
        ['credentialLoss', 'transportLoss'],
        reason: 'found $differing. A third divergence means an operation '
            'changed mode behaviour without this file saying so, and a shorter '
            'list means one of the two blocks silently reopened. This is also '
            'the assertion that keeps `transientRestart` from being split: a '
            'fourth class that both modes answer identically is a value with no '
            'measured difference, which Article XVII refuses.',
      );
    });
  });

  group('CredentialStrategy — local', () {
    late MockUspAuthCoordinator mockAuth;
    late MockRouterFingerprintService mockFingerprint;
    late ProviderContainer container;

    setUp(() {
      mockAuth = MockUspAuthCoordinator();
      mockFingerprint = MockRouterFingerprintService();
      container = ProviderContainer(overrides: [
        uspAuthCoordinatorProvider.overrideWithValue(mockAuth),
        routerFingerprintServiceProvider.overrideWithValue(mockFingerprint),
      ]);
    });

    tearDown(() => container.dispose());

    test('reestablishAfterOutage restores the session then compares the serial',
        () async {
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenAnswer((_) async {});
      when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'ABC123');
      when(() => mockFingerprint.matches('ABC123'))
          .thenAnswer((_) async => true);

      final same = await const LocalCredentialStrategy()
          .reestablishAfterOutage(_refOf(container));

      expect(same, isTrue);
      // Ordered: comparing a serial read over a session that has not been
      // restored yet reads the *old* connection, which after a factory reset is
      // the one whose credentials no longer exist.
      verifyInOrder([
        () => mockAuth.restoreSession(isRecovering: true),
        () => mockAuth.getSerialNumber(),
        () => mockFingerprint.matches('ABC123'),
      ]);
    });

    test('reestablishAfterOutage reports false when the serial changed',
        () async {
      when(() => mockAuth.restoreSession(isRecovering: true))
          .thenAnswer((_) async {});
      when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'XYZ789');
      when(() => mockFingerprint.matches('XYZ789'))
          .thenAnswer((_) async => false);

      expect(
        await const LocalCredentialStrategy()
            .reestablishAfterOutage(_refOf(container)),
        isFalse,
      );
    });

    test('onCredentialRebound leaves the coordinator alone', () {
      // Locally a re-login is a *new* login through the same door: the refresh
      // window it computed still describes the credential in use. Dropping it
      // would cost a needless token refresh on the next call and nothing else,
      // which is why this is a no-op rather than "harmless to do anyway" — the
      // strategy states the fact instead of hiding it behind a shared reset.
      const LocalCredentialStrategy().onCredentialRebound(_refOf(container));

      verifyZeroInteractions(mockAuth);
    });
  });

  group('CredentialStrategy — remote', () {
    late MockUspAuthCoordinator mockAuth;
    late MockRouterFingerprintService mockFingerprint;
    late ProviderContainer container;

    setUp(() {
      mockAuth = MockUspAuthCoordinator();
      mockFingerprint = MockRouterFingerprintService();
      container = ProviderContainer(overrides: [
        uspAuthCoordinatorProvider.overrideWithValue(mockAuth),
        routerFingerprintServiceProvider.overrideWithValue(mockFingerprint),
      ]);
    });

    tearDown(() => container.dispose());

    test('reestablishAfterOutage is a constant yes, and touches nothing',
        () async {
      final same = await const RemoteCredentialStrategy()
          .reestablishAfterOutage(_refOf(container));

      expect(same, isTrue);
      // Both steps the local strategy takes are actively wrong here, not merely
      // unnecessary: a `temporaryAccessToken` cannot be refreshed, and the
      // fingerprint store holds a serial written at *local* login — a support
      // session never wrote one. Identity is Guardian's job; it binds a session
      // to one serial server-side, so "a different router answered" is not a
      // state this code can be in.
      verifyZeroInteractions(mockAuth);
      verifyZeroInteractions(mockFingerprint);
    });

    test('onCredentialRebound clears the coordinator per-session state', () {
      // Acceptance 9. A second `activate()` needs no mode switch — an idle
      // timeout logs the user out while the Guardian session is still alive, and
      // one tap on Connect gets back here with a *different* token. The
      // coordinator's `_lastRestoreResult` and refresh window describe the old
      // one; kept, they answer for a credential that no longer exists.
      const RemoteCredentialStrategy().onCredentialRebound(_refOf(container));

      verify(() => mockAuth.resetSessionState()).called(1);
    });
  });

  group('RemoteTransportStrategy.isRouterReachable', () {
    late MockUspClient mockUsp;
    late ProviderContainer container;

    setUp(() {
      mockUsp = MockUspClient();
      container = ProviderContainer(overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
      ]);
    });

    tearDown(() => container.dispose());

    test('never throws, whatever the transport does', () async {
      // The contract says so in words, and `RecoveryProbeService` takes it
      // literally: there is no try/catch around the call. A throw here would
      // escape `_runProbe`, and `Timer.periodic`'s callback is not awaited by
      // anyone, so it would surface as an unhandled async error and the probe
      // loop would keep running with no result recorded.
      when(() => mockUsp.get(any())).thenThrow(StateError('socket gone'));

      await expectLater(
        const RemoteTransportStrategy(credential: RemoteCredentialStrategy())
            .isRouterReachable(_refOf(container)),
        completion(isFalse),
      );
    });
  });
}

/// Riverpod exposes no public `Ref` on a container, and these strategies only
/// ever `read` — so a one-line adapter is enough, and is honest about the fact
/// that the strategies use `Ref` as a service locator rather than for lifecycle.
///
/// Using a real provider body would also work, but it would make every test above
/// assert through a provider it does not otherwise care about.
Ref _refOf(ProviderContainer container) => container.read(_refExposerProvider);

final _refExposerProvider = Provider<Ref>((ref) => ref);
