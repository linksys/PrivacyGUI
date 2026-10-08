import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/page/dashboard/views/prepare_dashboard_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';

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
  Future<NodeDeviceInfo> checkDeviceInfo(String? serialNumber) async =>
      throw Exception('no device info');
}

// #1637: when preparing the dashboard fails, the page falls back to cloud
// account login. A login that may not write is redirected away from account
// login, so it goes back to the session login instead, which shows the error.
void main() {
  mockDependencyRegister();

  // The page loads the device cache through a container of its own, so the
  // cache cannot be overridden; give its file store somewhere to look instead.
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => Directory.systemTemp.path,
  );

  Future<void> prepareAndFail(WidgetTester tester, AccessPolicy policy) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        // Local, so the page skips the remote network selection.
        authProvider.overrideWith(() => _Auth(LoginType.local)),
        connectivityProvider.overrideWith(_Connectivity.new),
        dashboardManagerProvider.overrideWith(_NoDeviceInfo.new),
        accessPolicyProvider.overrideWithValue(policy),
      ],
      extraRoutes: [
        for (final (name, path) in [
          (RouteNamed.cloudLoginAccount, RoutePath.cloudLoginAccount),
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
  }

  testWidgets('falls back to account login with full access', (tester) async {
    await prepareAndFail(tester, AccessPolicy.full);

    expect(find.textContaining(RouteNamed.cloudLoginAccount), findsOneWidget);
  });

  testWidgets('falls back to the session login, with the error, on read-only',
      (tester) async {
    await prepareAndFail(tester, const AccessPolicy(canWrite: false));

    expect(find.text('${RouteNamed.cloudLoginAuth} Unexpected'),
        findsOneWidget);
    expect(find.textContaining(RouteNamed.cloudLoginAccount), findsNothing);
  });
}
