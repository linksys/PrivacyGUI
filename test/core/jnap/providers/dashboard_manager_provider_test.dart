// The dashboard manager's own calls: reading the router's device info (and
// building the action table from it), checking the router is back, and
// switching to another network. dashboard_manager_state_test.dart pins the
// state a poll builds, through RecordingPolling (#1922 P0).

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';
import '../../../mocks/router_repository_mocks.dart';
import '../../../test_data/device_info_test_data.dart';

class _LocalAuth extends AuthNotifier {
  @override
  Future<AuthState> build() =>
      Future.value(const AuthState(loginType: LoginType.local));
}

class _RemoteAuth extends AuthNotifier {
  @override
  Future<AuthState> build() =>
      Future.value(const AuthState(loginType: LoginType.remote));
}

const _serial = '20J2060A839173';

/// `GetDeviceInfo` output of the WHW03 with [serialNumber].
Map<String, dynamic> _deviceInfo(String serialNumber) => {
      'manufacturer': 'Linksys',
      'modelNumber': 'WHW03',
      'hardwareVersion': '2',
      'description': 'Velop',
      'serialNumber': serialNumber,
      'firmwareVersion': '2.1.20.213195',
      'firmwareDate': '2023-07-25T07:27:06Z',
      'services': [
        'http://linksys.com/jnap/core/Core',
        'http://linksys.com/jnap/healthcheck/HealthCheckManager',
      ],
    };

/// [output] as the router's answer, after a trip through JSON text.
JNAPSuccess _ok(Map<String, dynamic> output) => JNAPSuccess(
    result: 'OK',
    output: jsonDecode(jsonEncode(output)) as Map<String, dynamic>);

void main() {
  late MockRouterRepository repo;
  late ProviderContainer container;

  setUp(() {
    initBetterActions();
    repo = MockRouterRepository();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(repo),
      authProvider.overrideWith(() => _LocalAuth()),
      pollingProvider.overrideWith(() => RecordingPolling()),
    ]);
  });

  tearDown(() {
    container.dispose();
    initBetterActions();
  });

  group('checkDeviceInfo', () {
    // Every caller builds the action table from what checkDeviceInfo reads,
    // so it builds the table itself (#1923 P2).
    test('builds the action table from the device info it reads', () async {
      final output = Map<String, dynamic>.from(
          (jsonDecode(testDeviceInfo) as Map)['output'] as Map);
      when(repo.send(
        JNAPAction.getDeviceInfo,
        data: anyNamed('data'),
        extraHeaders: anyNamed('extraHeaders'),
        auth: anyNamed('auth'),
        type: anyNamed('type'),
        fetchRemote: anyNamed('fetchRemote'),
        cacheLevel: anyNamed('cacheLevel'),
        timeoutMs: anyNamed('timeoutMs'),
        retries: anyNamed('retries'),
        sideEffectOverrides: anyNamed('sideEffectOverrides'),
      )).thenAnswer((_) async => JNAPSuccess(result: 'OK', output: output));

      final info = await container
          .read(dashboardManagerProvider.notifier)
          .checkDeviceInfo(null);

      expect(info.serialNumber, output['serialNumber']);
      expect(routerServices, Set<String>.from(output['services'] as List));
      expect(JNAPAction.getWANSettings.actionValue,
          'http://linksys.com/jnap/router/GetWANSettings5');
    });
  });

  group('through the router', () {
    late RouterBoundary router;
    late ProviderContainer app;

    DashboardManagerNotifier notifier() =>
        app.read(dashboardManagerProvider.notifier);

    /// How each GetDeviceInfo went out: its fetchRemote, timeout and retries.
    List<(Object?, Object?, Object?)> deviceInfoReads() {
      final captured = verify(router.repo.send(
        JNAPAction.getDeviceInfo,
        data: anyNamed('data'),
        extraHeaders: anyNamed('extraHeaders'),
        auth: anyNamed('auth'),
        type: anyNamed('type'),
        fetchRemote: captureAnyNamed('fetchRemote'),
        cacheLevel: anyNamed('cacheLevel'),
        timeoutMs: captureAnyNamed('timeoutMs'),
        retries: captureAnyNamed('retries'),
        sideEffectOverrides: anyNamed('sideEffectOverrides'),
      )).captured;
      return [
        for (var i = 0; i < captured.length; i += 3)
          (captured[i], captured[i + 1], captured[i + 2]),
      ];
    }

    void start({
      Map<JNAPAction, JNAPResult> poll = const {},
      AuthNotifier Function() auth = _LocalAuth.new,
    }) {
      app = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router.repo),
        authProvider.overrideWith(auth),
        pollingProvider.overrideWith(() => RecordingPolling(poll)),
      ]);
      addTearDown(app.dispose);
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      router = RouterBoundary();
    });

    group('checkDeviceInfo', () {
      test('takes the device info from the last poll, without asking again',
          () async {
        start(poll: {JNAPAction.getDeviceInfo: _ok(_deviceInfo(_serial))});

        final info = await notifier().checkDeviceInfo(null);

        expect(info.serialNumber, _serial);
        expect(router.actions, isEmpty);
        expect(routerServices, {
          'http://linksys.com/jnap/core/Core',
          'http://linksys.com/jnap/healthcheck/HealthCheckManager',
        });
      });

      test('asks a router on the local network once, waiting 3 s', () async {
        router.holds(JNAPAction.getDeviceInfo, _deviceInfo(_serial));
        start();
        await app.read(authProvider.future);

        await notifier().checkDeviceInfo(null);

        // fetchRemote is the default: the cache may answer.
        expect(deviceInfoReads(), [(false, 3000, 0)]);
      });

      test('asks through the cloud with a 10 s wait and one retry', () async {
        router.holds(JNAPAction.getDeviceInfo, _deviceInfo(_serial));
        start(auth: _RemoteAuth.new);
        await app.read(authProvider.future);

        await notifier().checkDeviceInfo(null);

        expect(deviceInfoReads(), [(false, 10000, 1)]);
      });

      test('builds no action table when the router refuses', () async {
        router.refuses(JNAPAction.getDeviceInfo);
        start();

        await expectLater(
            notifier().checkDeviceInfo(null), throwsA(isA<JNAPError>()));

        expect(routerServices, isEmpty);
      });
    });

    group('checkRouterIsBack', () {
      test('answers with the router when it is the one logged in to', () async {
        SharedPreferences.setMockInitialValues({pCurrentSN: _serial});
        router.holds(JNAPAction.getDeviceInfo, _deviceInfo(_serial));
        start();

        final info = await notifier().checkRouterIsBack();

        expect(info.serialNumber, _serial);
        // Past the cache, once.
        expect(deviceInfoReads(), [(true, 10000, 0)]);
      });

      test('knows the router by setup\'s serial number before a login',
          () async {
        SharedPreferences.setMockInitialValues({pPnpConfiguredSN: _serial});
        router.holds(JNAPAction.getDeviceInfo, _deviceInfo(_serial));
        start();

        final info = await notifier().checkRouterIsBack();

        expect(info.modelNumber, 'WHW03');
      });

      test('fails when another router answers in its place', () async {
        SharedPreferences.setMockInitialValues({pCurrentSN: _serial});
        router.holds(JNAPAction.getDeviceInfo, _deviceInfo('19A10M00000000'));
        start();

        await expectLater(
            notifier().checkRouterIsBack(),
            throwsA(predicate(
                (Object error) => '$error'.contains('SN not match'))));
      });

      test('passes on a router that does not answer', () async {
        SharedPreferences.setMockInitialValues({pCurrentSN: _serial});
        router.refuses(JNAPAction.getDeviceInfo);
        start();

        await expectLater(
            notifier().checkRouterIsBack(), throwsA(isA<JNAPError>()));
      });
    });

    group('saveSelectedNetwork', () {
      test(
          'remembers the router and its network, and clears the dashboard '
          'until the next poll', () async {
        start(poll: {
          JNAPAction.getDeviceInfo: _ok(_deviceInfo(_serial)),
          JNAPAction.getSystemStats: _ok({
            'uptimeSeconds': 19555,
            'CPULoad': '0.23',
            'MemoryLoad': '0.79',
          }),
        });
        expect(app.read(dashboardManagerProvider).uptimes, 19555);

        await notifier().saveSelectedNetwork('19A10M00000000', 'network-2');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(pCurrentSN), '19A10M00000000');
        expect(prefs.getString(pSelectedNetworkId), 'network-2');
        expect(app.read(selectedNetworkIdProvider), 'network-2');
        final cleared = app.read(dashboardManagerProvider);
        expect(cleared.deviceInfo, isNull);
        expect(cleared.uptimes, 0);
        expect(cleared.cpuLoad, isNull);
      });
    });

    group('what the poll says', () {
      test('supports the health check modules the router lists', () {
        start(poll: {
          JNAPAction.getSupportedHealthCheckModules: _ok({
            'supportedHealthCheckModules': ['SpeedTest'],
          }),
        });

        expect(notifier().isHealthCheckModuleSupported('SpeedTest'), isTrue);
        expect(notifier().isHealthCheckModuleSupported('ChannelAnalyzer'),
            isFalse);
      });
    });
  });
}
