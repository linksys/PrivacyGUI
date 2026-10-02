import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_trigger_result.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/test_data/scenes/login_scene_data.dart';

/// #1641: the login redirect read `pnpStatusServiceProvider` through
/// `routerProvider`'s `Ref` only after awaiting device info. Logging in changes
/// `authProvider`, which `routerProvider` depends on, while that await is
/// pending — so the read threw "Cannot use ref functions after the dependency
/// of a provider changed but before the provider rebuilt", and the redirect
/// decision that threw never ran its PnP check.
///
/// Driven through [RouterNotifier] directly rather than a pumped `GoRouter`:
/// the defect is in the ordering inside `_prepare`, and the window it needs —
/// auth changing while the device-info fetch is pending — is one this test can
/// hold open on purpose and a widget pump cannot.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SuspendedSession session;
  late _CountingPnp pnp;
  late ProviderContainer container;
  late RouterNotifier router;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    session = _SuspendedSession();
    pnp = _CountingPnp();
    container = ProviderContainer(overrides: [
      authProvider.overrideWith(_ManualAuth.new),
      sessionProvider.overrideWith(() => session),
      pnpStatusServiceProvider.overrideWithValue(pnp),
    ]);
    addTearDown(container.dispose);
    // Something keeps routerProvider alive, as `app.dart` watches it.
    container.listen(routerProvider, (_, __) {});
    router = RouterNotifier(container.read(_refProvider));
  });

  _ManualAuth auth() => container.read(authProvider.notifier) as _ManualAuth;

  /// Lets every in-flight redirect reach the device-info await, then changes
  /// auth the way a login does, then releases the fetch.
  Future<void> loginDuring(List<Future<void>> decisions) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(session.pending, decisions.length,
        reason: 'every decision is suspended on device info');
    auth().signedOut();
    auth().signedIn();
    session.release();
    await Future.wait(decisions);
  }

  test('a login while redirectLogic waits on device info does not throw',
      () async {
    await container.read(authProvider.future);
    auth().signedIn();
    final errors = <Object>[];

    await loginDuring([
      router
          .redirectLogic(_state(RoutePath.localLoginPassword))
          .then((_) {}, onError: errors.add),
    ]);

    expect(errors, isEmpty);
    expect(pnp.checks, 1, reason: 'the decision still checks PnP');
  });

  test(
      'both decisions on /localLoginPassword survive a login, and each checks '
      'PnP once', () async {
    // The login route's redirect runs autoConfigurationLogic (result discarded)
    // and redirectLogic for one navigation, and both reach `_prepare`, so both
    // must survive a login. (On the bench this fix took the assertion from two
    // per password login to one; the rest come from routerProvider being rebuilt
    // on every login change, tracked separately.)
    await container.read(authProvider.future);
    auth().signedIn();
    final state = _state(RoutePath.localLoginPassword);
    final errors = <Object>[];

    await loginDuring([
      router.autoConfigurationLogic(state).then((_) {}, onError: errors.add),
      router.redirectLogic(state).then((_) {}, onError: errors.add),
    ]);

    expect(errors, isEmpty);
    expect(pnp.checks, 2);
  });
}

/// A provider handing out its own `Ref`, standing in for `routerProvider`'s.
/// It watches nothing itself: `redirectLogic` adds the `authProvider` watch,
/// exactly as it does on the real `Ref`, so the dependency that goes stale is
/// the one the redirect creates.
final _refProvider = Provider<Ref>((ref) => ref);

GoRouterState _state(String location) => GoRouterState(
      RouteConfiguration(
        ValueNotifier(RoutingConfig(routes: [
          GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        ])),
        navigatorKey: GlobalKey<NavigatorState>(),
      ),
      uri: Uri.parse(location),
      matchedLocation: location,
      fullPath: location,
      pathParameters: const {},
      pageKey: const ValueKey('state'),
    );

/// Auth whose login the test performs by hand.
class _ManualAuth extends AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState.empty();

  /// What `init()` answers once a stored token is restored.
  @override
  Future<AuthState?> init() async => state.value;

  void signedIn() =>
      state = const AsyncValue.data(AuthState(loginType: LoginType.local));

  void signedOut() =>
      state = const AsyncValue.data(AuthState(loginType: LoginType.none));
}

/// A session with no cached device info, whose fetch is held until [release] —
/// the window a real login lands in.
class _SuspendedSession extends SessionNotifier {
  final _gate = Completer<void>();
  int pending = 0;

  void release() => _gate.complete();

  @override
  SessionState build() => const SessionState();

  @override
  Future<NodeDeviceInfo> forceFetchDeviceInfo() async => testLoginDeviceInfo;

  @override
  Future<void> saveSelectedNetwork(
      String serialNumber, String networkId) async {}

  @override
  Future<NodeDeviceInfo> fetchDeviceInfoAndInitializeServices() async {
    pending++;
    await _gate.future;
    return testLoginDeviceInfo;
  }
}

class _CountingPnp implements PnpStatusService {
  int checks = 0;

  @override
  Future<PnpTriggerResult> check(String? currentSerialNumber) async {
    checks++;
    return PnpTriggerResult.notNeeded();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
