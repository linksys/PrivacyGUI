import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/cache/cache_manager.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/dashboard/views/prepare_dashboard_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/di.dart';
import '../../../common/router_boundary.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/device_info_test_data.dart';

/// A login of [loginType] with nothing left to prepare.
class _Auth extends AuthNotifier {
  _Auth(this.loginType);
  final LoginType loginType;

  @override
  Future<AuthState> build() async => AuthState(loginType: loginType);
}

class _Connectivity extends ConnectivityNotifier {
  @override
  ConnectivityState build() => const ConnectivityState(
      hasInternet: true, connectivityInfo: ConnectivityInfo());

  @override
  Future<ConnectivityState> forceUpdate() async => state;
}

/// The router never answers with its device info, which is what sends the page
/// to its error fallback.
class _NoDeviceInfo extends DashboardManagerNotifier {
  @override
  DashboardManagerState build() => const DashboardManagerState();

  @override
  Future<NodeDeviceInfo> checkDeviceInfo() async =>
      throw Exception('no device info');
}

/// A device cache store with nothing in it and no file behind it. The start
/// loads the cache of the router it reaches, and a file read would not finish
/// on the test's fake clock.
class _EmptyCacheStore implements CacheManager {
  @override
  Future<String?> get() async => null;

  @override
  Future<void> set(String value) async {}
}

// #1637: when preparing the dashboard fails, the page falls back to a login.
// One that can write goes where the router sends a logged-out user: the local
// login on a local build, the Guardian login otherwise (#1849). One that may
// not write goes back to the session login, which shows the error.
void main() {
  mockDependencyRegister();

  late ForceCommand buildForce;
  setUp(() => buildForce = BuildConfig.forceCommandType);
  tearDown(() => BuildConfig.forceCommandType = buildForce);

  // The page loads the device cache through a container of its own, so the
  // cache cannot be overridden; give its file store somewhere to look instead.
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => Directory.systemTemp.path,
  );

  Future<void> prepareAndFail(WidgetTester tester, AccessPolicy policy,
      {ForceCommand force = ForceCommand.local}) async {
    BuildConfig.forceCommandType = force;
    SharedPreferences.setMockInitialValues({});
    LinksysCacheManager()
      ..cacheManager = _EmptyCacheStore()
      ..loadedSerialNumber = '';
    final router = RouterBoundary()
      ..holds(JNAPAction.getDeviceInfo, jsonDecode(testDeviceInfo)['output']);
    // Every override sits on this container, which the page's scope takes as
    // its parent: a provider the scope does not override is made there.
    final container = ProviderContainer(overrides: [
      // A local login, as PnP leaves it: only PnP opens this page.
      authProvider.overrideWith(() => _Auth(LoginType.local)),
      connectivityProvider.overrideWith(_Connectivity.new),
      dashboardManagerProvider.overrideWith(_NoDeviceInfo.new),
      routerRepositoryProvider.overrideWithValue(router.repo),
      accessPolicyProvider.overrideWithValue(policy),
    ]);
    addTearDown(container.dispose);
    // PnP has logged in by the time it opens this page, so the login is read
    // first. The page reads it once, and a login still loading reads as none,
    // which skipped the page's local-login step (#1904).
    await tester.runAsync(() => container.read(authProvider.future));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      provider: container,
      extraRoutes: [
        for (final (name, path) in [
          (RouteNamed.localLoginPassword, RoutePath.localLoginPassword),
          (RouteNamed.cloudLoginAuth, RoutePath.cloudLoginAuth),
        ])
          LinksysRoute(
            name: name,
            path: path,
            builder: (context, state) =>
                Text('$name ${state.uri.queryParameters['error'] ?? ''}'),
          ),
      ],
      child: const PrepareDashboardView(),
    ));
    // The page works through real futures before it navigates.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pumpAndSettle();
    expect(router.actions, [JNAPAction.getDeviceInfo],
        reason: 'the local login asked which router it reaches');
  }

  testWidgets('falls back to the local login, with the error, on a local build',
      (tester) async {
    await prepareAndFail(tester, AccessPolicy.full);

    expect(find.text('${RouteNamed.localLoginPassword} Unexpected'),
        findsOneWidget);
  });

  testWidgets('falls back to the Guardian login, with the error, otherwise',
      (tester) async {
    await prepareAndFail(tester, AccessPolicy.full, force: ForceCommand.none);

    expect(
        find.text('${RouteNamed.cloudLoginAuth} Unexpected'), findsOneWidget);
  });

  testWidgets('falls back to the session login, with the error, on read-only',
      (tester) async {
    await prepareAndFail(tester, const AccessPolicy(canWrite: false));

    expect(
        find.text('${RouteNamed.cloudLoginAuth} Unexpected'), findsOneWidget);
    expect(find.textContaining(RouteNamed.localLoginPassword), findsNothing);
  });
}
