// The two places a session starts (#1904 P0, the session start row):
// - the router's redirect: a local or a remote login as the app opens, and
//   again on every later page change;
// - PrepareDashboardView, which PnP opens once it has logged in.
//
// #1904 P2 makes them one sequence. Until then, this pins what each does
// today, differences included, through seams P2 does not move: the redirect
// and the page are the way in, and the router, polling and the device cache
// are the edges. DashboardManagerNotifier and the action table run for real.
//
// Each case lists everything the start leaves behind, so a change to any part
// of it fails the case that shows it. Where the two places differ today:
// - the redirect saves the network only when the router changed; the page
//   saves it every time;
// - the redirect retries a router that is briefly unreachable; the page
//   gives up at once;
// - the redirect sets the model number; the page leaves it unset;
// - the redirect asks polling to start, forced only when the router changed;
//   the page stops and starts it;
// - they fall back to different logins.
//
// Two of today's behaviours look wrong and are pinned as they are, for P2 to
// decide:
// - both load the device cache of the router opened before, when the phone
//   now reaches another one;
// - a page change whose device check fails stays on the page.
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
import 'package:privacy_gui/core/cache/cache_manager.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/dashboard/views/prepare_dashboard_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_state.dart';
import 'package:privacy_gui/providers/global_model_number_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/di.dart';
import '../common/recording_polling.dart';
import '../common/router_boundary.dart';
import '../common/testable_router.dart';
import '../test_data/device_info_test_data.dart';

final _deviceInfoOutput =
    jsonDecode(testDeviceInfo)['output'] as Map<String, dynamic>;
final _services = Set.of(NodeDeviceInfo.fromJson(_deviceInfoOutput).services);
const _serial = '65G10M27E03056';
const _model = 'LN16';

/// The router the phone opened before, which is not the one it reaches now.
const _otherSerial = 'OTHERROUTER01';

/// What the device cache holds before a start loads one.
const _nothingLoaded = '(nothing loaded yet)';

const _landed = ValueKey('landed');

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

/// A router already set up, as its setup checks report it.
class _SetUpRouter extends PnpNotifier {
  @override
  PnpState build() => PnpState(deviceInfo: null);

  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) async {}

  @override
  Future<AutoConfigurationSettings?> autoConfigurationCheck() async =>
      const AutoConfigurationSettings(
        isAutoConfigurationSupported: true,
        userAcknowledgedAutoConfiguration: true,
      );

  @override
  Future<bool> isRouterPasswordSet() async => true;
}

/// The local login PnP has made by the time it opens PrepareDashboardView.
class _PnpLogin extends AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState(loginType: LoginType.local);
}

/// Polling that records what it is told, including each check to start it and
/// whether the check was forced.
class _Polling extends RecordingPolling {
  _Polling([super.data = const {}]);

  final List<bool> startChecks = [];

  @override
  void checkAndStartPolling([bool force = false]) {
    startChecks.add(force);
    super.checkAndStartPolling(force);
  }
}

/// A device cache store with nothing in it and no file behind it. What a start
/// does with the cache is which router's cache it loads.
class _EmptyCacheStore implements CacheManager {
  @override
  Future<String?> get() async => null;

  @override
  Future<void> set(String value) async {}
}

void main() {
  mockDependencyRegister();

  late ForceCommand buildForce;
  late Directory cacheDir;
  late RouterBoundary router;
  late _Polling polling;
  ProviderContainer? openContainer;
  late BuildContext context;

  setUpAll(() {
    // The cache singleton reads its file once as it is made, before setUp
    // swaps in the empty store. Give it a directory of its own, away from the
    // shared temp file (#1928).
    TestWidgetsFlutterBinding.ensureInitialized();
    cacheDir = Directory.systemTemp.createTempSync('session_start_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cacheDir.path,
    );
  });
  tearDownAll(() => cacheDir.deleteSync(recursive: true));

  setUp(() {
    buildForce = BuildConfig.forceCommandType;
    initBetterActions();
    LinksysCacheManager()
      ..cacheManager = _EmptyCacheStore()
      ..loadedSerialNumber = _nothingLoaded;
    router = RouterBoundary()
      ..holds(JNAPAction.getDeviceInfo, _deviceInfoOutput);
  });

  tearDown(() {
    BuildConfig.forceCommandType = buildForce;
    openContainer?.dispose();
    openContainer = null;
    initBetterActions();
  });

  /// The router answers getDeviceInfo with each of [answers] in turn: its
  /// device info, a JNAPError, or an exception for no answer at all.
  void routerAnswers(List<Object> answers) =>
      router.holdsInTurn(JNAPAction.getDeviceInfo, answers);

  /// The app's router, as a [force] build opens it, with what is stored and
  /// what polling last read.
  Future<ProviderContainer> app(
    WidgetTester tester, {
    ForceCommand force = ForceCommand.local,
    RouterType routerType = RouterType.behindManaged,
    Map<String, String> secure = const {},
    Map<String, Object> prefs = const {},
    Map<JNAPAction, JNAPResult> polled = const {},
  }) async {
    BuildConfig.forceCommandType = force;
    FlutterSecureStorage.setMockInitialValues(Map.of(secure));
    SharedPreferences.setMockInitialValues(Map.of(prefs));
    polling = _Polling(polled);
    final container = openContainer = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      connectivityProvider.overrideWith(() => _Connectivity(routerType)),
      pnpProvider.overrideWith(_SetUpRouter.new),
      pollingProvider.overrideWith(() => polling),
    ]);
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));
    return container;
  }

  /// Where the router's redirect sends [location].
  ///
  /// Run on the real clock: the redirect waits on storage and, for a router
  /// that is briefly unreachable, on a real delay.
  Future<String?> redirect(
      WidgetTester tester, ProviderContainer container, String location) async {
    final goRouter = container.read(routerProvider);
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

  /// Opens PrepareDashboardView as PnP does, with what is stored. Returns
  /// where the page went, and the providers it used.
  ///
  /// PnP has logged in by then, so the login is read before the page opens:
  /// the page reads it once, and a login still loading reads as none.
  ///
  /// Every override sits on this container, which the page's scope takes as
  /// its parent. A provider the scope does not override is made in the parent,
  /// where an override on the scope alone would not reach it.
  Future<(String?, ProviderContainer)> prepareDashboard(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    BuildConfig.forceCommandType = ForceCommand.local;
    SharedPreferences.setMockInitialValues(Map.of(prefs));
    polling = _Polling();
    final container = openContainer = ProviderContainer(overrides: [
      authProvider.overrideWith(_PnpLogin.new),
      connectivityProvider
          .overrideWith(() => _Connectivity(RouterType.behindManaged)),
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
      accessPolicyProvider.overrideWithValue(AccessPolicy.full),
    ]);
    await tester.runAsync(() => container.read(authProvider.future));
    String? landing;
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      provider: container,
      extraRoutes: [
        for (final (name, path) in [
          (RouteNamed.dashboardHome, RoutePath.dashboardHome),
          (RouteNamed.localLoginPassword, RoutePath.localLoginPassword),
          (RouteNamed.cloudLoginAuth, RoutePath.cloudLoginAuth),
        ])
          LinksysRoute(
            name: name,
            path: path,
            builder: (context, state) {
              landing = state.uri.toString();
              return const SizedBox(key: _landed);
            },
          ),
      ],
      child: const PrepareDashboardView(),
    ));
    // The page works through real futures before it navigates.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pumpAndSettle();
    expect(find.byKey(_landed), findsOneWidget, reason: 'the page navigated');
    return (landing, container);
  }

  /// Checks everything a start left behind.
  Future<void> expectStart(
    ProviderContainer container, {
    required String? landing,
    required String? landsOn,
    required List<JNAPAction> sent,
    required String? storedSerial,
    required String? storedNetwork,
    required String cacheOf,
    required bool tableBuilt,
    required List<bool> startChecks,
    required int restarts,
    required String modelNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    expect(landing, landsOn, reason: 'where it lands');
    expect(router.actions, sent, reason: 'what the router received');
    expect(prefs.getString(pCurrentSN), storedSerial,
        reason: 'the stored serial number');
    expect(prefs.getString(pSelectedNetworkId), storedNetwork,
        reason: 'the stored network');
    expect(LinksysCacheManager().loadedSerialNumber, cacheOf,
        reason: 'whose device cache is loaded');
    expect(routerServices, tableBuilt ? _services : isEmpty,
        reason: 'the services the action table is built for');
    expect(polling.startChecks, startChecks,
        reason: 'the checks to start polling, and whether each was forced');
    expect((
      stopped: polling.stopped,
      started: polling.started
    ), (
      stopped: restarts,
      started: restarts
    ), reason: 'how often polling was stopped and started');
    expect(container.read(globalModelNumberProvider), modelNumber,
        reason: 'the model number');
  }

  const deviceInfoTwice = [JNAPAction.getDeviceInfo, JNAPAction.getDeviceInfo];
  const noDeviceInfo = JNAPError(result: 'ErrorUnknown');
  final unreachable = ClientException('Connection refused');
  final localLogin = {pLocalPassword: 'TestAdmin1!'};

  group("a local login, as the router's redirect opens the app", () {
    testWidgets('with no router stored', (tester) async {
      final container = await app(tester, secure: localLogin);

      await expectStart(
        container,
        landing: await redirect(tester, container, '/?from=test'),
        landsOn: RoutePath.dashboardHome,
        sent: deviceInfoTwice,
        storedSerial: _serial,
        storedNetwork: '',
        cacheOf: '',
        tableBuilt: true,
        startChecks: [true],
        restarts: 1,
        modelNumber: _model,
      );
    });

    testWidgets('on the router it opened last', (tester) async {
      final container =
          await app(tester, secure: localLogin, prefs: {pCurrentSN: _serial});

      await expectStart(
        container,
        landing: await redirect(tester, container, '/?from=test'),
        landsOn: RoutePath.dashboardHome,
        sent: deviceInfoTwice,
        storedSerial: _serial,
        // The router did not change, so nothing is saved.
        storedNetwork: null,
        cacheOf: _serial,
        tableBuilt: true,
        startChecks: [false],
        restarts: 1,
        modelNumber: _model,
      );
    });

    testWidgets('on another router than the one it opened last',
        (tester) async {
      final container = await app(tester,
          secure: localLogin, prefs: {pCurrentSN: _otherSerial});

      await expectStart(
        container,
        landing: await redirect(tester, container, '/?from=test'),
        landsOn: RoutePath.dashboardHome,
        sent: deviceInfoTwice,
        storedSerial: _serial,
        storedNetwork: '',
        // The serial number is read before the new one is saved.
        cacheOf: _otherSerial,
        tableBuilt: true,
        startChecks: [true],
        restarts: 1,
        modelNumber: _model,
      );
    });

    testWidgets('when the router gives no device info', (tester) async {
      routerAnswers([_deviceInfoOutput, noDeviceInfo]);
      final container = await app(tester, secure: localLogin);

      await expectStart(
        container,
        landing: await redirect(tester, container, '/?from=test'),
        landsOn: '/localLoginPassword?error=noDeviceInfo',
        sent: deviceInfoTwice,
        storedSerial: _serial,
        storedNetwork: '',
        cacheOf: '',
        tableBuilt: false,
        startChecks: [],
        restarts: 0,
        modelNumber: '',
      );
    });

    testWidgets('when the router is briefly unreachable', (tester) async {
      routerAnswers([_deviceInfoOutput, unreachable, _deviceInfoOutput]);
      final container = await app(tester, secure: localLogin);

      // One retry, two seconds later, on the real clock.
      await expectStart(
        container,
        landing: await redirect(tester, container, '/?from=test'),
        landsOn: RoutePath.dashboardHome,
        sent: [...deviceInfoTwice, JNAPAction.getDeviceInfo],
        storedSerial: _serial,
        storedNetwork: '',
        cacheOf: '',
        tableBuilt: true,
        startChecks: [true],
        restarts: 1,
        modelNumber: _model,
      );
    });
  });

  group("a local login, as the router's redirect changes page", () {
    testWidgets('once polling knows the router', (tester) async {
      final container = await app(
        tester,
        secure: localLogin,
        prefs: {pCurrentSN: _serial},
        polled: {
          JNAPAction.getDeviceInfo:
              JNAPSuccess(result: 'OK', output: _deviceInfoOutput),
        },
      );
      await tester.runAsync(() => container.read(authProvider.notifier).init());

      await expectStart(
        container,
        landing: await redirect(tester, container, RoutePath.dashboardHome),
        // It stays on the page.
        landsOn: null,
        sent: [],
        storedSerial: _serial,
        storedNetwork: null,
        cacheOf: _serial,
        tableBuilt: true,
        startChecks: [false],
        restarts: 1,
        modelNumber: _model,
      );
    });

    testWidgets('when the router gives no device info', (tester) async {
      routerAnswers([_deviceInfoOutput, noDeviceInfo]);
      final container =
          await app(tester, secure: localLogin, prefs: {pCurrentSN: _serial});
      await tester.runAsync(() => container.read(authProvider.notifier).init());

      await expectStart(
        container,
        landing: await redirect(tester, container, RoutePath.dashboardHome),
        // The redirect drops where the failure would send it.
        landsOn: null,
        sent: deviceInfoTwice,
        storedSerial: _serial,
        storedNetwork: null,
        cacheOf: _serial,
        tableBuilt: false,
        startChecks: [],
        restarts: 0,
        modelNumber: '',
      );
    });
  });

  group("a remote login, as the router's redirect opens the app", () {
    testWidgets('on the router its Guardian session names', (tester) async {
      final container = await app(
        tester,
        force: ForceCommand.none,
        routerType: RouterType.others,
        secure: {
          pSessionToken: jsonEncode({
            'access_token': 'agent-token',
            'token_type': 'Bearer',
            'expires_in': 3600,
          }),
          pSessionTokenTs: '${DateTime.now().millisecondsSinceEpoch}',
        },
        prefs: {pCurrentSN: _serial, pGRASessionId: 'G1'},
      );

      await expectStart(
        container,
        landing: await redirect(tester, container, '/?from=test'),
        landsOn: RoutePath.dashboardHome,
        // The Guardian session names the router, so it is not asked first.
        sent: [JNAPAction.getDeviceInfo],
        storedSerial: _serial,
        storedNetwork: '',
        cacheOf: _serial,
        tableBuilt: true,
        startChecks: [false],
        restarts: 1,
        modelNumber: _model,
      );
    });
  });

  group("PnP's local login, as PrepareDashboardView opens the dashboard", () {
    testWidgets('with no router stored', (tester) async {
      final (landing, container) = await prepareDashboard(tester);

      await expectStart(
        container,
        landing: landing,
        landsOn: RoutePath.dashboardHome,
        sent: deviceInfoTwice,
        storedSerial: _serial,
        storedNetwork: '',
        cacheOf: '',
        tableBuilt: true,
        startChecks: [],
        restarts: 1,
        modelNumber: '',
      );
    });

    testWidgets('on the router it opened last', (tester) async {
      final (landing, container) =
          await prepareDashboard(tester, prefs: {pCurrentSN: _serial});

      await expectStart(
        container,
        landing: landing,
        landsOn: RoutePath.dashboardHome,
        sent: deviceInfoTwice,
        storedSerial: _serial,
        // Saved even though the router did not change.
        storedNetwork: '',
        cacheOf: _serial,
        tableBuilt: true,
        startChecks: [],
        restarts: 1,
        modelNumber: '',
      );
    });

    testWidgets('on another router than the one it opened last',
        (tester) async {
      final (landing, container) =
          await prepareDashboard(tester, prefs: {pCurrentSN: _otherSerial});

      await expectStart(
        container,
        landing: landing,
        landsOn: RoutePath.dashboardHome,
        sent: deviceInfoTwice,
        storedSerial: _serial,
        storedNetwork: '',
        // The serial number is read before the new one is saved.
        cacheOf: _otherSerial,
        tableBuilt: true,
        startChecks: [],
        restarts: 1,
        modelNumber: '',
      );
    });

    testWidgets('when the router gives no device info', (tester) async {
      routerAnswers([_deviceInfoOutput, noDeviceInfo]);
      final (landing, container) = await prepareDashboard(tester);

      await expectStart(
        container,
        landing: landing,
        landsOn: '/localLoginPassword?error=Unexpected',
        sent: deviceInfoTwice,
        storedSerial: _serial,
        storedNetwork: '',
        cacheOf: '',
        tableBuilt: false,
        startChecks: [],
        restarts: 0,
        modelNumber: '',
      );
    });

    testWidgets('when the router is briefly unreachable', (tester) async {
      routerAnswers([_deviceInfoOutput, unreachable, _deviceInfoOutput]);
      final (landing, container) = await prepareDashboard(tester);

      await expectStart(
        container,
        landing: landing,
        // No retry.
        landsOn: '/localLoginPassword?error=Unexpected',
        sent: deviceInfoTwice,
        storedSerial: _serial,
        storedNetwork: '',
        cacheOf: '',
        tableBuilt: false,
        startChecks: [],
        restarts: 0,
        modelNumber: '',
      );
    });
  });
}
