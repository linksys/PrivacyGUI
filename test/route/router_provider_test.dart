import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/di.dart';
import '../common/recording_polling.dart';
import '../common/router_boundary.dart';
import '../test_data/device_info_test_data.dart';

// Where the app sends someone as it opens: the router's redirect. Each case
// fixes what the router and the stored login say, runs the redirect for a
// location, and checks where it leads. The account login and its select
// network page are deletion candidates (#1849).

final _deviceInfo =
    NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']);
const _serial = '65G10M27E03056';

/// The phone's link to the router, fixed.
class _Connectivity extends ConnectivityNotifier {
  _Connectivity(this.routerType);

  final RouterType routerType;

  @override
  ConnectivityState build() => ConnectivityState(
      hasInternet: true,
      connectivityInfo: ConnectivityInfo(routerType: routerType));

  @override
  Future<ConnectivityState> forceUpdate() async => state;
}

/// What the router's setup checks report.
class _SetupChecks extends PnpNotifier {
  _SetupChecks({this.config, this.passwordSet = true, this.deviceInfo});

  final AutoConfigurationSettings? config;
  final bool passwordSet;
  final NodeDeviceInfo? deviceInfo;

  @override
  PnpState build() => PnpState(deviceInfo: deviceInfo);

  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) async {}

  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() async => config;

  @override
  Future<bool> isRouterPasswordSet() async => passwordSet;
}

/// The dashboard's device check: answers with [deviceInfo], or fails with
/// each error in [failures] first.
class _DeviceCheck extends DashboardManagerNotifier {
  final List<Object> failures = [];
  final List<(String, String)> savedNetworks = [];
  int checks = 0;

  @override
  DashboardManagerState build() => const DashboardManagerState();

  @override
  Future<NodeDeviceInfo> checkDeviceInfo(String? serialNumber) async {
    checks++;
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return _deviceInfo;
  }

  @override
  Future<void> saveSelectedNetwork(
      String serialNumber, String networkId) async {
    savedNetworks.add((serialNumber, networkId));
  }
}

/// Polling that records being asked to start.
class _Polling extends RecordingPolling {
  int startChecks = 0;

  @override
  void checkAndStartPolling([bool force = false]) => startChecks++;
}

const _readyRouter = AutoConfigurationSettings(
  isAutoConfigurationSupported: true,
  userAcknowledgedAutoConfiguration: true,
);

void main() {
  mockDependencyRegister();
  late ForceCommand buildForce;

  late RouterBoundary router;
  late _DeviceCheck deviceCheck;
  late _Polling polling;
  late ProviderContainer container;
  late BuildContext context;

  setUpAll(() {
    // The dashboard's cache is a singleton that keeps its file in the temp
    // directory.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
  });

  setUp(() => buildForce = BuildConfig.forceCommandType);
  tearDown(() {
    BuildConfig.forceCommandType = buildForce;
    container.dispose();
  });

  /// Opens the app as a [force] build, with what is stored and what the router
  /// and its setup checks say.
  Future<GoRouter> open(
    WidgetTester tester, {
    ForceCommand force = ForceCommand.local,
    RouterType routerType = RouterType.behindManaged,
    _SetupChecks? setup,
    Map<String, String> secure = const {},
    Map<String, Object> prefs = const {},
  }) async {
    BuildConfig.forceCommandType = force;
    FlutterSecureStorage.setMockInitialValues(Map.of(secure));
    SharedPreferences.setMockInitialValues(Map.of(prefs));
    router = RouterBoundary()
      ..holds(JNAPAction.getDeviceInfo, jsonDecode(testDeviceInfo)['output']);
    deviceCheck = _DeviceCheck();
    polling = _Polling();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      connectivityProvider.overrideWith(() => _Connectivity(routerType)),
      pnpProvider
          .overrideWith(() => setup ?? _SetupChecks(config: _readyRouter)),
      dashboardManagerProvider.overrideWith(() => deviceCheck),
      pollingProvider.overrideWith(() => polling),
    ]);
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));
    return container.read(routerProvider);
  }

  /// Where the redirect sends [location].
  ///
  /// Run on the real clock: the dashboard's cache reads its file on the way,
  /// and file I/O never completes on the test's fake one.
  Future<String?> redirect(
      WidgetTester tester, GoRouter goRouter, String location) async {
    final uri = Uri.parse(location);
    return tester
        .runAsync<String?>(() async => await goRouter.configuration.topRedirect(
              context,
              GoRouterState(
                goRouter.configuration,
                uri: uri,
                matchedLocation: uri.path,
                fullPath: uri.path,
                pathParameters: const {},
                pageKey: ValueKey(location),
              ),
            ));
  }

  final localLogin = {pLocalPassword: 'Linksys123!'};
  Map<String, String> guardianLogin() => {
        pSessionToken: jsonEncode({
          'access_token': 'agent-token',
          'token_type': 'Bearer',
          'expires_in': 3600,
        }),
        pSessionTokenTs: '${DateTime.now().millisecondsSinceEpoch}',
      };

  group('opening the app on a router being set up', () {
    testWidgets('goes to setup when the router asks for it', (tester) async {
      final goRouter = await open(tester,
          setup: _SetupChecks(
              config: const AutoConfigurationSettings(
                  isAutoConfigurationSupported: true,
                  userAcknowledgedAutoConfiguration: false)),
          secure: localLogin);

      expect(await redirect(tester, goRouter, '/?from=test'), '/pnp?from=test');
      // Setup starts from no login.
      expect(
          await const FlutterSecureStorage().read(key: pLocalPassword), isNull);
    });

    testWidgets('goes to setup after a factory reset left no password',
        (tester) async {
      final goRouter = await open(tester,
          setup: _SetupChecks(
              config: const AutoConfigurationSettings(
                  isAutoConfigurationSupported: false),
              passwordSet: false));

      expect(await redirect(tester, goRouter, '/?from=test'), '/pnp?from=test');
    });

    testWidgets('goes to setup when a configured router has no password yet',
        (tester) async {
      final goRouter = await open(tester,
          setup: _SetupChecks(config: _readyRouter, passwordSet: false));

      expect(await redirect(tester, goRouter, '/?from=test'), '/pnp?from=test');
    });
  });

  group('opening the app on a router already set up', () {
    testWidgets('asks for the admin password when none is stored',
        (tester) async {
      final goRouter = await open(tester);

      expect(await redirect(tester, goRouter, '/?from=test'),
          '/localLoginPassword?from=test');
    });

    testWidgets('asks for the password when the setup checks fail',
        (tester) async {
      final goRouter = await open(tester, setup: _SetupChecks(config: null));

      expect(await redirect(tester, goRouter, '/?from=test'),
          '/localLoginPassword?from=test');
    });

    testWidgets('goes to the dashboard with a stored password', (tester) async {
      final goRouter = await open(tester, secure: localLogin);

      expect(await redirect(tester, goRouter, '/?from=test'),
          RoutePath.dashboardHome);
      expect(router.actions, contains(JNAPAction.getDeviceInfo));
      expect(deviceCheck.savedNetworks, [(_serial, '')]);
      expect(polling.startChecks, 1);
    });

    testWidgets('back to the password when the router gives no device info',
        (tester) async {
      final goRouter = await open(tester, secure: localLogin);
      deviceCheck.failures.add(const JNAPError(result: 'ErrorUnknown'));

      expect(await redirect(tester, goRouter, '/?from=test'),
          '/localLoginPassword?error=noDeviceInfo');
      expect(polling.startChecks, 0);
    });

    testWidgets('waits out a router restarting its services', (tester) async {
      final goRouter = await open(tester, secure: localLogin);
      deviceCheck.failures
        ..add(ClientException('Connection refused'))
        ..add(ClientException('Connection refused'));

      // Two retries, two seconds apart, on the real clock.
      expect(await redirect(tester, goRouter, '/?from=test'),
          RoutePath.dashboardHome);
      expect(deviceCheck.checks, 3);
    });

    testWidgets('gives up on a router that stays unreachable', (tester) async {
      final goRouter = await open(tester, secure: localLogin);
      deviceCheck.failures.addAll([
        for (var i = 0; i < 3; i++) ClientException('Connection refused'),
      ]);

      expect(await redirect(tester, goRouter, '/?from=test'),
          '/localLoginPassword?error=noDeviceInfo');
      expect(deviceCheck.checks, 3);
    });
  });

  group('opening the remote build', () {
    testWidgets('sends someone not logged in to the Guardian login',
        (tester) async {
      final goRouter = await open(tester,
          force: ForceCommand.none, routerType: RouterType.others);

      expect(await redirect(tester, goRouter, '/?from=test'),
          '/cloudLoginAuth?from=test');
    });

    testWidgets('takes a Guardian login to the dashboard of its router',
        (tester) async {
      final goRouter = await open(tester,
          force: ForceCommand.none,
          routerType: RouterType.others,
          secure: guardianLogin(),
          prefs: {pCurrentSN: _serial, pGRASessionId: 'G1'});

      expect(await redirect(tester, goRouter, '/?from=test'),
          RoutePath.dashboardHome);
      // The Guardian session names the router; no network to pick.
      expect(deviceCheck.savedNetworks, [(_serial, '')]);
    });

    testWidgets('logs out a remote login whose Guardian session is gone',
        (tester) async {
      final goRouter = await open(tester,
          force: ForceCommand.none,
          routerType: RouterType.others,
          secure: guardianLogin(),
          prefs: {pCurrentSN: _serial});

      expect(await redirect(tester, goRouter, '/?from=test'),
          '/cloudLoginAuth?from=test');
      expect(
          await const FlutterSecureStorage().read(key: pSessionToken), isNull);
    });
  });

  group('going straight to a page', () {
    testWidgets('a dashboard page without a login goes to the login',
        (tester) async {
      final goRouter = await open(tester);

      // With no query to carry over, the login path has none either.
      expect(await redirect(tester, goRouter, RoutePath.dashboardHome),
          '/localLoginPassword');
    });

    testWidgets('a setup page before setup has begun goes to its start',
        (tester) async {
      final goRouter = await open(tester);

      expect(await redirect(tester, goRouter, '/pnp/pnpConfig?from=test'),
          '/pnp?from=test');
    });

    testWidgets('a setup page once setup has begun stays', (tester) async {
      final goRouter = await open(tester,
          setup: _SetupChecks(config: _readyRouter, deviceInfo: _deviceInfo));

      expect(await redirect(tester, goRouter, '/pnp/pnpConfig?from=test'),
          '/pnp/pnpConfig?from=test');
    });
  });
}
