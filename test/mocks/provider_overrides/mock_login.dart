/// Provider overrides for the four `lib/page/login/` pages (#1379, wave 3).
///
/// One file for all four because they share a directory tree and, more usefully, the
/// same shape of problem: each view's `initState` or `build` reaches a provider that
/// in USP-only mode is either a **stub** with a hardcoded return or a real notifier
/// that touches a service. A fixed notifier is how a case pins which branch it means,
/// and — for `sessionProvider` and `autoParentFirstLoginProvider` — how a cell gets
/// measured at all instead of throwing.
///
/// The states these builders take live in
/// `test/mocks/test_data/scenes/login_scene_data.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/page/login/auto_parent/providers/auto_parent_first_login_provider.dart';
import 'package:privacy_gui/page/login/providers/router_password_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// An [AuthNotifier] pinned to one [AuthState].
///
/// `mock_common.dart`'s `commonOverrides()` already overrides `authProvider`, with a
/// notifier fixed at `AuthState.empty()`. This one is not a duplicate of it: `empty()`
/// carries a null `localPasswordHint`, and the hint is what decides whether
/// `login_local_view` renders its hint panel. Both overrides end up in the same
/// `ProviderScope` and the later one wins, which is why `pageSurfaceHost` builds its
/// list as `[...commonOverrides(), ...overrides]` — a case's own fixture is meant to
/// be able to sharpen a shared default.
class FixedAuthStateNotifier extends AuthNotifier {
  final AuthState _fixedState;

  FixedAuthStateNotifier(this._fixedState);

  @override
  Future<AuthState> build() => Future.value(_fixedState);
}

/// A [SessionNotifier] whose device-info fetch touches no service.
///
/// `fetchDeviceInfoAndInitializeServices` is overridden rather than left to `super`
/// because the real one reads `sessionServiceProvider` — which throws
/// `Service not initialized: USP service not available` under `flutter test` — and
/// then writes a router fingerprint through a second service. Both are out of scope
/// for a layout measurement, and the view uses the result only to sequence what
/// happens next.
class FixedSessionNotifier extends SessionNotifier {
  final NodeDeviceInfo _deviceInfo;

  FixedSessionNotifier(this._deviceInfo);

  @override
  SessionState build() => SessionState(deviceInfo: _deviceInfo);

  @override
  Future<NodeDeviceInfo> fetchDeviceInfoAndInitializeServices() async =>
      _deviceInfo;
}

/// A [RouterPasswordNotifier] pinned to one [RouterPasswordState].
///
/// The two transitions are overridden for the reason `FixedPnpNotifier` overrides
/// its own: a view can trigger them. `setAdminPasswordWithResetCode` in particular
/// **throws `UnimplementedError`** in the real stub, so a future test that taps the
/// reset page's save button would fail on the notifier rather than on the layout.
class FixedRouterPasswordNotifier extends RouterPasswordNotifier {
  final RouterPasswordState _fixedState;

  FixedRouterPasswordNotifier(this._fixedState);

  @override
  RouterPasswordState build() => _fixedState;

  @override
  Future<bool> checkRecoveryCode(String code) async => false;

  @override
  Future<void> setAdminPasswordWithResetCode(
    String password,
    String hint,
    String code,
  ) async {}
}

/// An [AutoParentFirstLoginNotifier] that reports firmware waiting to install.
///
/// The real notifier's `checkAndAutoInstallFirmware()` is a USP-mode stub returning
/// **false**, and false is the branch that leaves the page: the view then calls
/// `finishFirstTimeLogin`, which reaches `autoParentFirstLoginServiceProvider`, and
/// on return does `context.goNamed(RouteNamed.dashboardHome)` — a route
/// `pageSurfaceHost`'s single-route router does not have, so the cell dies on a
/// navigation error instead of measuring a page.
///
/// So `true` is not the convenient answer, it is the only one that keeps this view
/// mounted: firmware-is-installing is the state the screen exists to show.
/// `finishFirstTimeLogin` is neutralised as well, so the fixture does not depend on
/// the check branch being taken to stay off the service.
class FixedAutoParentFirstLoginNotifier extends AutoParentFirstLoginNotifier {
  final bool _firmwareAvailable;

  FixedAutoParentFirstLoginNotifier(this._firmwareAvailable);

  @override
  Future<bool> checkAndAutoInstallFirmware() async => _firmwareAvailable;

  @override
  Future<void> finishFirstTimeLogin([bool failCheck = false]) async {}
}

/// Overrides for `login_local_view`.
List<Override> loginLocalOverrides({
  required AuthState authState,
  required NodeDeviceInfo deviceInfo,
}) =>
    [
      authProvider.overrideWith(() => FixedAuthStateNotifier(authState)),
      sessionProvider.overrideWith(() => FixedSessionNotifier(deviceInfo)),
    ];

/// Overrides for `local_reset_router_password_view` and
/// `local_router_recovery_view`, which read the same provider for different fields.
List<Override> routerPasswordOverrides(RouterPasswordState state) => [
      routerPasswordProvider
          .overrideWith(() => FixedRouterPasswordNotifier(state)),
    ];

/// Overrides for `auto_parent_first_login_view`.
List<Override> autoParentFirstLoginOverrides({
  bool firmwareAvailable = true,
}) =>
    [
      autoParentFirstLoginProvider.overrideWith(
        () => FixedAutoParentFirstLoginNotifier(firmwareAvailable),
      ),
    ];
