/// Composed states for the four `lib/page/login/` pages the layout gate sweeps
/// (#1379, wave 3).
///
/// A `_scene_data` file rather than a `_test_data` one, per CLAUDE.md's testing
/// section: everything here is a whole composed state ready to hand to a provider
/// override, not a builder for assembling one.
///
/// ## Why these are so small
///
/// Wave 1 and wave 2's scenes carry lists — devices, reservations, wizard configs.
/// The login pages carry almost nothing, and that is a property of the pages rather
/// than a thin fixture: three of the four are forms whose fields start empty, and
/// their providers are USP-mode **stubs** (`routerPasswordProvider`,
/// `autoParentFirstLoginProvider`) whose only job today is to decide which of two
/// branches a view renders. So a scene here is one flag or one nullable int, and the
/// value of stating it as a named final is that the case which uses it can say *why*
/// that branch is the one under measurement.
library;

import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/page/login/providers/router_password_provider.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

/// What `sessionProvider.fetchDeviceInfoAndInitializeServices()` returns to
/// `login_local_view`'s `initState`.
///
/// The view never renders any of these seven strings — it awaits the call only to
/// sequence `_getAdminPasswordAuthStatus()` after it. The fixture exists because the
/// real method reaches `sessionServiceProvider` and then
/// `routerFingerprintServiceProvider`, and an unoverridden `initState` throws
/// `Service not initialized: USP service not available` out of the first of those,
/// which fails the cell rather than measuring it.
///
/// `serialNumber` is non-empty on purpose even though nothing reads it: the real
/// method skips the fingerprint write when it is empty, and a fixture that is safe
/// only because it took the early-return branch would stop being safe the moment
/// someone gave it a serial number.
const testLoginDeviceInfo = NodeDeviceInfo(
  modelNumber: 'M60',
  firmwareVersion: '1.0.16',
  description: 'Linksys Router',
  firmwareDate: '2026-01-01',
  manufacturer: 'Linksys',
  serialNumber: 'TEST0000000001',
  hardwareVersion: '1',
);

/// `login_local_view` with a password hint on the router.
///
/// The hint is what adds `AppExpansionPanel.compactSingle` to the card — a header
/// row with a label and a chevron that a hintless router does not render at all. The
/// panel opens on tap and this sweep taps nothing, so the *text* below is never laid
/// out and its length does not matter; the row is the measured delta, and it is
/// present in 234 cells of this state and in none of `AuthState.empty()`'s.
///
/// `LoginType.none`, i.e. not logged in: `build` pushes `context.go('/')` when the
/// state transitions to logged-in, and this family's router has one route.
final localLoginWithHintState = AuthState(
  localPasswordHint: 'router label',
  loginType: LoginType.none,
);

/// `local_reset_router_password_view` with its save button enabled.
///
/// `isValid` is the one field this page reads, and it decides only whether
/// `AppButton.onTap` is null — the enabled and disabled buttons are the same size.
/// It is pinned anyway so the branch under measurement is a decision rather than
/// `RouterPasswordNotifier.build()`'s default, which is the argument
/// `kPnpNoInternetPageCase` makes about its own phase.
///
/// **What this page does not measure, recorded rather than papered over.** The seven
/// `AppPasswordRule`s handed to `AppPasswordInput(rules:)` are the width-sensitive
/// part of this form — seven localized sentences in a column — and ui_kit renders
/// them only once the field is focused. Focusing is a tap per cell, the second axis
/// `kWifiSettingsPageCase` declines for its own second tab, so the rule list stays
/// unmeasured here and is a later wave's scope.
const routerPasswordValidState = RouterPasswordState(isValid: true);

/// `local_router_recovery_view` after two failed recovery keys.
///
/// `remainingErrorAttempts` is nullable and null renders **no** error text at all,
/// so pinning it is what puts the two-line error paragraph in the tree. Two rather
/// than 1 or 0: `_getErrorString` has three branches and only this one interpolates
/// a count into a localized sentence (`localLoginRemainingAttempts`), which is the
/// branch whose length varies per locale by the most. The other two append a fixed
/// string.
const routerRecoveryTwoAttemptsLeftState =
    RouterPasswordState(remainingErrorAttempts: 2);
