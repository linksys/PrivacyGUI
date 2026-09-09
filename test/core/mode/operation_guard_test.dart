// #1496 phase 6: `OperationGuard` is a *delegation* to cause 4, and stays one.
//
// THE DECISION GUARDED. Which disruptive operations a mode permits has exactly
// one home — `ProximityStrategy.canRecoverFrom` — and the guard's job is to be
// the seam operations call, not to hold an opinion. So the tests below assert
// `guard.allows(d) == profile.proximity.canRecoverFrom(d)` rather than a table of
// expected booleans.
//
// That looks like a tautology and is not. It is the difference between two ways
// this file could have been written, and the other way is the failure mode phase
// 6 exists to prevent: a literal list here ("RA blocks credentialLoss and
// transportLoss") would make this file the second place the policy lives, and the
// two copies then agree until someone changes one of them. The policy's own
// assertions are in `test/core/mode/impl/recovery_strategies_test.dart`, beside
// the other member of the same contract, where both modes' answers can be read
// side by side.
//
// Mutation-checked in the direction that matters: replacing `allows`'s body with
// `=> true` turns the two remote arms red here, while leaving
// `recovery_strategies_test.dart` green — and replacing a `canRecoverFrom` arm
// does the opposite. The two files fail for different causes on purpose.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/operation_guard.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';

/// Every profile the composition root can produce, including the two aliases.
///
/// Cloud and demo alias local through a labelled constructor rather than being
/// their own classes, so they are not separate rows in any policy table — but
/// they *are* separate rows here, because the thing under test is the delegation
/// and an alias is exactly the case where a guard that read `profile.mode`
/// instead of `profile.proximity` would answer differently.
const _profiles = <AppModeProfile>[
  LocalModeProfile(),
  RemoteModeProfile(),
  LocalModeProfile.aliasedAs(AppMode.cloud),
  LocalModeProfile.aliasedAs(AppMode.demo),
];

void main() {
  group('allows() is cause 4 and nothing else', () {
    for (final profile in _profiles) {
      for (final disruption in DisruptionClass.values) {
        test('${profile.mode.name} / ${disruption.name}', () {
          expect(
            OperationGuard(profile.proximity).allows(disruption),
            profile.proximity.canRecoverFrom(disruption),
            reason: 'OperationGuard answered ${disruption.name} differently '
                'from the ${profile.mode.name} profile\'s own '
                'ProximityStrategy. The guard must delegate: the moment it '
                'holds any part of the answer, "which operations are refused" '
                'has two homes, and the copy nobody edits is the one a new '
                'DisruptionClass gets wrong.',
          );
        });
      }
    }
  });

  group('enforce()', () {
    // Chosen for what they are in RA, then asserted through `allows` rather than
    // by name, so this group cannot drift from the policy either.
    const refusedRemotely = DisruptionClass.credentialLoss;
    const allowedEverywhere = DisruptionClass.transientRestart;

    test('returns normally when the mode can recover', () {
      final guard = _local;

      expect(
        () => guard.enforce(allowedEverywhere, operation: 'reboot'),
        returnsNormally,
      );
      expect(
        () => guard.enforce(refusedRemotely, operation: 'factory reset'),
        returnsNormally,
        reason: 'a local build must keep every operation it had before #1496. '
            'The five seams are on the local code path too, and their existing '
            'tests run under the default profile.',
      );
    });

    test('throws UnauthorizedError when it cannot', () {
      final guard = _remote;

      expect(
        () => guard.enforce(refusedRemotely, operation: 'factory reset'),
        throwsA(isA<UnauthorizedError>()),
        reason: 'a refusal has to throw. Every seam sits directly above a USP '
            'command, and a bool the caller may ignore is indistinguishable '
            'from success — in firmware_update_view._onConfirmInstall a silent '
            'refusal falls through to triggerInstall and then to a recovery '
            'dialog waiting for a reboot nobody asked for.',
      );
    });

    test('the thrown error names the operation for the log, not the user', () {
      final guard = _remote;

      try {
        guard.enforce(DisruptionClass.transportLoss,
            operation: 'local firmware upload');
        fail('expected a refusal');
      } on UnauthorizedError catch (e) {
        expect(e.detail, contains('local firmware upload'));
        expect(e.detail, contains('transportLoss'));
      }
      // `localizeServiceError` maps UnauthorizedError by type and never reads
      // `detail`, so this string is diagnostics. It is asserted anyway because
      // the alternative — a refusal that logs nothing identifying — is a
      // support ticket that reads "the button did nothing".
    });

    test('still allows what the mode can recover from, remotely', () {
      final guard = _remote;

      expect(
        () => guard.enforce(allowedEverywhere, operation: 'reboot'),
        returnsNormally,
        reason: 'reboot and cloud OTA stay available in Remote Assistance — '
            'that is the whole point of classifying by consequence instead of '
            'by how destructive an operation sounds. A guard that refused '
            'everything disruptive would take the two operations an agent most '
            'often needs.',
      );
    });
  });

  group('the provider follows the profile', () {
    // Falsification criterion 3: the mode is selected by overriding a provider.
    // No test in this file touches `BuildConfig.forceCommandType`.
    OperationGuard guardUnder(AppModeProfile profile) {
      final container = ProviderContainer(
        overrides: [appModeProfileProvider.overrideWithValue(profile)],
      );
      addTearDown(container.dispose);
      return container.read(operationGuardProvider);
    }

    for (final profile in _profiles) {
      test('${profile.mode.name} composes its own proximity answer', () {
        final guard = guardUnder(profile);

        for (final disruption in DisruptionClass.values) {
          expect(
            guard.allows(disruption),
            profile.proximity.canRecoverFrom(disruption),
            reason: 'the guard the container built for ${profile.mode.name} '
                'does not answer ${disruption.name} the way that profile\'s '
                'proximity strategy does, so operationGuardProvider is reading '
                'something other than appModeProfileProvider.proximity — a '
                'static, a different member, or a hard-coded strategy.',
          );
        }
      });
    }

    test('and the override actually changes the answer', () {
      // Without this, the loop above is satisfiable by a guard that ignores the
      // provider entirely: if every mode agreed on every class, "matches the
      // profile" and "constant" would be the same assertion. So this asserts the
      // *existence* of a divergence rather than its contents — the contents are
      // the policy, and the policy is asserted once, in
      // test/core/mode/impl/recovery_strategies_test.dart.
      final local = guardUnder(const LocalModeProfile());
      final remote = guardUnder(const RemoteModeProfile());
      final divergent = DisruptionClass.values
          .where((d) => local.allows(d) != remote.allows(d))
          .map((d) => d.name)
          .toList();

      expect(
        divergent,
        isNotEmpty,
        reason: 'no DisruptionClass is answered differently by the local and '
            'remote profiles, which makes every other test in this file '
            'vacuous — and means cause 4 has no measured difference left to '
            'justify canRecoverFrom at all (Article XVII: a member needs one). '
            'If a policy change really did converge the two modes, delete the '
            'member and the guard rather than leaving them as a pass-through.',
      );
    });
  });
}

/// The guard as each mode composes it.
///
/// Built from the profile rather than from `LocalProximityStrategy` directly, so
/// that a profile wired to the wrong strategy is a failure here too — and so this
/// file has no reason to import `lib/core/mode/impl/`.
final OperationGuard _local =
    OperationGuard(const LocalModeProfile().proximity);
final OperationGuard _remote =
    OperationGuard(const RemoteModeProfile().proximity);
