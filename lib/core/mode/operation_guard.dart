import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
import 'package:privacy_gui/framework/mode/proximity_strategy.dart';

/// The one seam a disruptive router operation goes through before it runs.
///
/// **There is exactly one of this class and it has no Local/Remote pair** —
/// #1496 acceptance 3c, guarded by `test/core/mode/mode_contract_roster_test.dart`.
/// A `RemoteOperationGuard` would duplicate the logging, the error type and the
/// call-site roster in order to change one boolean, and the boolean already lives
/// in a strategy. Cause 4 answers *what is refused*; this class answers *what
/// happens when it is*, which is the same in every mode.
///
/// [allows] is a straight delegation to [ProximityStrategy.canRecoverFrom], and
/// that is not an accident to be tidied away: it is the reason the guard can
/// exist without becoming a second copy of the policy.
/// `test/core/mode/operation_guard_test.dart` asserts the delegation rather than
/// the answers, so this file can never start disagreeing with cause 4.
///
/// **The roster of seams.** Five operations name a [DisruptionClass] and call
/// [enforce]. `test/core/mode/destructive_operation_roster_test.dart` pins the
/// list, because "adding a destructive operation without a class does not
/// compile" — acceptance 6's wording — is not a property Dart can give us:
/// nothing in the type system knows what an operation is, and an author who
/// simply does not call [enforce] breaks no signature.
///
/// | Seam | Class | Local | RA |
/// | --- | --- | --- | --- |
/// | `UspAdminNotifier.reboot` | `transientRestart` | ok | ok |
/// | `UspAdminNotifier.factoryReset` | `credentialLoss` | ok | **refused** |
/// | `FirmwareUpdateNotifier.runUpload` | `transportLoss` | ok | **refused** |
/// | `FirmwareUpdateNotifier.triggerInstall` | `transientRestart` | ok | ok |
/// | `FirmwareUpdateNotifier.triggerOtaInstall` | `transientRestart` | ok | ok |
///
/// The three allowed seams call [enforce] too, and they are the more important
/// half of the roster. With only the refused ones wired, the code reads "factory
/// reset asks, reboot does not" and a reader cannot tell whether reboot is
/// allowed or whether somebody forgot — which is precisely the ambiguity that put
/// reboot and factory reset in the same mental bucket in the first place. Wired
/// both ways, the difference between the two is one enum value at the seam and
/// nothing else, and a *new* operation missing from the roster is visible.
///
/// A Wi-Fi settings change is classified `transientRestart` and deliberately has
/// no seam: it is a parameter write rather than a USP command, its recovery
/// answer is already carried by `RecoveryTrigger.operationalWifiChange`, and
/// putting a guard on `Set` would mean putting one on every `Set`.
class OperationGuard {
  const OperationGuard(this._proximity);

  final ProximityStrategy _proximity;

  /// Whether an operation costing [disruption] may run in this mode.
  ///
  /// **No production caller today**, and that is stated rather than dressed up:
  /// every seam in the roster below calls [enforce]. It is public for two
  /// concrete reasons and not for a speculative disabled button, which is what an
  /// earlier draft of this comment claimed — phase 7 (#1497) hides affordances
  /// through `SurfaceStrategy`, so that caller is unlikely ever to be here.
  ///
  /// First, it is the predicate the ticket specifies (`bool allows(DisruptionClass
  /// d) => proximity.canRecoverFrom(d)`), and it is what
  /// `operation_guard_test.dart` asserts over `DisruptionClass.values` × every
  /// profile — testing the *derivation* instead of a hand-written expectations
  /// table, which is only possible against a member that returns the answer
  /// rather than throwing it. Second, it is [enforce]'s own condition, so the two
  /// cannot drift: there is no second reading of the policy to keep in step.
  bool allows(DisruptionClass disruption) =>
      _proximity.canRecoverFrom(disruption);

  /// Runs [operation] past the guard, or throws [UnauthorizedError].
  ///
  /// **Throws rather than returning a result**, because every one of the five
  /// seams sits directly above a USP command and a `bool` the caller may ignore
  /// is indistinguishable from success. `_onConfirmInstall` in
  /// `firmware_update_view.dart` is the concrete case: a silent refusal there
  /// would fall straight through to `triggerInstall` and then to the recovery
  /// dialog, i.e. to a wait for a reboot that was never asked for.
  ///
  /// [UnauthorizedError] rather than a new `ServiceError` subtype: its existing
  /// copy — "You do not have permission to perform this action." — is already
  /// translated in all 26 ARB files and says the true thing. A new subtype would
  /// buy a more specific sentence at the cost of 26 new strings on a path that
  /// phase 7 makes unreachable.
  ///
  /// [operation] is a diagnostic label for the log, not user-facing copy;
  /// `localizeServiceError` maps [UnauthorizedError] by type and never reads
  /// `detail`.
  void enforce(DisruptionClass disruption, {required String operation}) {
    if (allows(disruption)) return;
    logger.w('[Mode] refused $operation: this mode cannot recover from '
        '${disruption.name}');
    throw UnauthorizedError(
      detail: '$operation is not available in this mode (${disruption.name})',
    );
  }

  /// No `operator ==`, deliberately — and unlike `BridgeConfig`'s version of this
  /// note, the reason here is that it would be provably inert.
  ///
  /// Review asked for one, on the ground that this class is a stateless value and
  /// that phase 7 (#1497) will `ref.watch(operationGuardProvider)` in a widget, so
  /// an equal-but-new guard would rebuild it for nothing. Measured 2026-09-08, and
  /// that rebuild cannot happen: `appModeProvider` is
  /// `Provider<AppMode>((ref) => AppMode.resolve())` with no dependencies, so it
  /// is computed once per container and never recomputes;
  /// `appModeProfileProvider` therefore never recomputes and returns a `const`
  /// profile besides; so this guard is constructed exactly once per container and
  /// a watcher can never be handed a second instance to compare. `==` would
  /// change no rebuild count anywhere, which is the shape #1502 recorded as the
  /// worst kind of guard to add — one that passes analyze and the whole suite
  /// while doing nothing, and that no test can be made red before the fix.
  ///
  /// It becomes worth adding the moment the mode is genuinely reactive (a session
  /// that starts local and is escalated to Remote Assistance would do it), because
  /// then `local → cloud` and `local → demo` are transitions across which
  /// `_proximity` is the *same* `const` singleton and only `==` would coalesce
  /// them.
}

/// Cause 4's answer, wrapped for the operation seams.
///
/// Reads the profile rather than taking a mode, so overriding
/// `appModeProfileProvider` in a test puts every seam in that mode at once —
/// which is falsification criterion 3's requirement that no new remote test
/// assigns `BuildConfig.forceCommandType`.
final operationGuardProvider = Provider<OperationGuard>(
  (ref) => OperationGuard(ref.watch(appModeProfileProvider).proximity),
);
