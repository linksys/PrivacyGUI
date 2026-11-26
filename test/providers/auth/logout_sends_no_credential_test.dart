// After logout() returns, the router receives no request that carries a
// credential (#1904 P0, safety-net row 1).
//
// The real AuthNotifier, the real RouterRepository and the real owner of each
// piece of work, with only the executor swapped for one that records what
// reaches it. Each case starts its work while logged in, logs out, and lets
// the fake clock run on. A request built after the logout carries the factory
// default (`loginType` is `none`, router_repository.dart:395), so the check is
// on every request the router receives once logout() has returned.
//
// The cases for the firmware check and the firmware install were red before
// #1904 P1: that is the bug #1904 reports. P1 ties that work to the login
// (`AuthNotifier.logoutGeneration`), so a logout ends it before its next
// request.
//
// #1904 P2 ties the other scheduled owners to the login too, each with a case
// below that failed before its owner was tied.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/command/http/base_http_command.dart';
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/jnap/spec/jnap_spec.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/troubleshooting/providers/troubleshooting_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/di.dart';

const _password = 'TestAdmin1!';

/// The headers that carry a credential to the router.
const _credentialHeaders = {
  kJNAPAuthorization,
  kJNAPSession,
  HttpHeaders.authorizationHeader,
};

String _isoMinutesAgo(int minutes) => DateTime.now()
    .toUtc()
    .subtract(Duration(minutes: minutes))
    .toIso8601String();

/// `GetFirmwareUpdateStatus` output for the router alone. While [installing],
/// an install is under way, so the checks that follow it go on.
Map<String, dynamic> _firmwareStatus({
  bool update = false,
  bool installing = false,
}) =>
    {
      'lastSuccessfulCheckTime': _isoMinutesAgo(60),
      if (update)
        'availableUpdate': {
          'firmwareVersion': '1.3.2',
          'firmwareDate': '2026-11-01T00:00:00Z',
          'description': 'Fixes',
        },
      if (installing)
        'pendingOperation': {
          'operation': 'Installing',
          'progressPercent': 10,
        },
    };

/// The install's own request. The check sends the same action, with
/// `onlyCheck: true`.
bool _isInstallRequest(_Received r) =>
    r.action == JNAPAction.updateFirmwareNow.actionValue &&
    r.data['onlyCheck'] == false;

/// One node of `GetDevices` output, online unless [online] is false.
Map<String, dynamic> _node(String id, {bool online = true}) => {
      'connections': [
        if (online)
          {'macAddress': 'AA:00:00:00:00:01', 'ipAddress': '192.168.1.2'},
      ],
      'properties': [
        {'name': 'userDeviceLocation', 'value': id},
      ],
      'unit': <String, dynamic>{},
      'deviceID': id,
      'maxAllowedProperties': 16,
      'model': {'deviceType': 'Infrastructure', 'modelNumber': 'MX6200'},
      'isAuthority': false,
      'lastChangeRevision': 1,
      'knownInterfaces': [
        {'macAddress': 'AA:00:00:00:00:01', 'interfaceType': 'Wireless'},
      ],
      'nodeType': 'Slave',
    };

/// One request as the router received it.
class _Received {
  _Received(this.action, this.header, this.data);

  final String action;
  final Map<String, String> header;

  /// The request's body, for a single action; empty for a transaction.
  final Map<String, dynamic> data;

  bool get carriesCredential => header.keys.any(_credentialHeaders.contains);

  @override
  String toString() {
    final credential = header.keys.where(_credentialHeaders.contains);
    return '$action${credential.isEmpty ? '' : ' with $credential'}';
  }
}

/// Records every request, and answers each action from [outputs], keyed by
/// the action's URL, alone or in a transaction. An action not named there is
/// answered OK with no output.
class _RecordingRouter with JNAPCommandExecutor<Response> {
  final Map<String, Map<String, dynamic>> outputs = {};

  void answer(JNAPAction action, Map<String, dynamic> output) =>
      outputs[action.actionValue] = output;

  /// How long the router takes to answer an action. The request counts as
  /// received when it arrives, before the wait.
  final Map<String, Duration> delays = {};

  void answerAfter(JNAPAction action, Duration delay) =>
      delays[action.actionValue] = delay;

  final List<_Received> received = [];

  @override
  Future<Response> execute(BaseCommand command) async {
    final http = command as BaseHttpCommand;
    final spec = command.spec;
    received.add(_Received(spec.action, Map.of(http.header),
        spec is JNAPCommandSpec ? Map.of(spec.data) : const {}));
    final delay = delays[command.spec.action];
    if (delay != null) await Future.delayed(delay);
    if (command is TransactionHttpCommand) {
      return Response(
          jsonEncode({
            keyJnapResult: jnapResultOk,
            keyJnapResponses: [
              for (final action in command.actions)
                {
                  keyJnapResult: jnapResultOk,
                  keyJnapOutput: outputs[action.actionValue] ?? const {},
                },
            ],
          }),
          200);
    }
    return Response(
        jsonEncode({
          keyJnapResult: jnapResultOk,
          keyJnapOutput: outputs[command.spec.action] ?? const {},
        }),
        200);
  }

  @override
  void dropCommand(String id) {}
}

class _TestRouterRepository extends RouterRepository {
  _TestRouterRepository(super.ref, this.router);

  final _RecordingRouter router;

  @override
  JNAPCommandExecutor get executor => router;
}

class _LocalConnectivityNotifier extends ConnectivityNotifier {
  @override
  ConnectivityState build() => const ConnectivityState(
        hasInternet: true,
        connectivityInfo: ConnectivityInfo(
          gatewayIp: '192.168.1.1',
          routerType: RouterType.behindManaged,
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  mockDependencyRegister();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => Directory.systemTemp.createTempSync('logout_net').path,
  );

  late _RecordingRouter router;
  late ProviderContainer container;

  AuthNotifier auth() => container.read(authProvider.notifier);

  /// Logged in locally, with [_password], as the app is after a restart.
  Future<void> logIn() async {
    FlutterSecureStorage.setMockInitialValues({pLocalPassword: _password});
    SharedPreferences.setMockInitialValues({});
    await auth().init();
    expect(container.read(authProvider).value?.loginType, LoginType.local);
  }

  /// Lets the command queue send what it holds and then stop its own timer,
  /// which it does 3 s after its last request. Time here is the test binding's
  /// fake clock: a test that awaits a send without advancing it waits forever.
  Future<void> drainQueue(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 4));

  /// [testWidgets], cleaned up after [body] even when it fails: polling's
  /// timers are static and the command queue is a singleton, so a timer left
  /// behind in this case's fake clock would break the cases after it.
  void netTest(
    String description,
    Future<void> Function(WidgetTester tester) body, {
    bool skip = false,
  }) {
    testWidgets(description, skip: skip, (tester) async {
      try {
        await body(tester);
      } finally {
        container.read(pollingProvider.notifier).stopPolling();
        await drainQueue(tester);
      }
    });
  }

  /// Logs out, lets the clock run on, and returns what the router received
  /// once logout() had returned.
  Future<List<_Received>> logOut(WidgetTester tester) async {
    await auth().logout();
    final mark = router.received.length;
    // Longer than any check the cases start, and than two poll ticks.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 5));
    }
    return router.received.sublist(mark);
  }

  setUp(() {
    buildBetterActions(JNAPService.values.map((s) => s.value).toList());
    router = _RecordingRouter()
      ..answer(JNAPAction.getFirmwareUpdateStatus, _firmwareStatus())
      // Polled with the status, and parsed by the firmware notifier's build.
      ..answer(JNAPAction.getFirmwareUpdateSettings, const {
        'updatePolicy': 'AutomaticallyCheckAndInstall',
        'autoUpdateWindow': {'startMinute': 120, 'durationMinutes': 180},
      })
      // Read after every poll (polling_provider.dart, _additionalPolling).
      ..answer(JNAPAction.getMACFilterSettings, const {
        'macFilterMode': 'Disabled',
        'maxMACAddresses': 32,
        'macAddresses': <String>[],
      });
    container = ProviderContainer(overrides: [
      connectivityProvider.overrideWith(() => _LocalConnectivityNotifier()),
      accessPolicyProvider.overrideWithValue(AccessPolicy.full),
      routerRepositoryProvider
          .overrideWith((ref) => _TestRouterRepository(ref, router)),
    ]);
  });

  tearDown(() {
    container.dispose();
    // AuthNotifier's constructor installs a handler on the shared client.
    LinksysHttpClient.onError = null;
  });

  netTest('while logged in, a request carries the credential', (tester) async {
    // Without this, a check that nothing after the logout carries a credential
    // would pass for a detector that sees none at all.
    await logIn();

    final sent = container
        .read(routerRepositoryProvider)
        .send(JNAPAction.getDeviceInfo, auth: true);
    await drainQueue(tester);
    await sent;

    expect(router.received.single.carriesCredential, isTrue);
  });

  netTest('polling started before the logout sends nothing after it',
      (tester) async {
    await logIn();
    container.read(pollingProvider.notifier).startPolling();
    // The first poll, then one tick of the timer.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 61));
    // Only the first poll reaches the router here: the timer's ticks are
    // answered from the command cache, whose expiry reads the real clock,
    // not this test's. Without logout()'s stopPolling() the case still fails.
    expect(router.received.where((r) => r.action.contains('Transaction')),
        isNotEmpty,
        reason: 'polling did run while logged in');

    final after = await logOut(tester);

    expect(after, isEmpty);
  });

  netTest(
      'polling started while the logout is under way sends nothing after it',
      (tester) async {
    // A start-up that reaches checkAndStartPolling while logout() clears the
    // stores. A build that keeps the login until then lets it start, so the
    // logout stops polling again at its end.
    await logIn();

    final loggingOut = auth().logout();
    container.read(pollingProvider.notifier).checkAndStartPolling();
    await loggingOut;
    final mark = router.received.length;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 5));
    }

    // Its device-mode read may already be queued and go out after the logout
    // (the command queue is not cleared), but that read carries no
    // credential. The polls that would carry one never start.
    expect(router.received.sublist(mark).where((r) => r.carriesCredential),
        isEmpty);
  });

  netTest(
      'a forced poll whose device-mode read is out at the logout sends '
      'nothing after it', (tester) async {
    // A poll that has no command set yet reads the device mode first and
    // builds one (polling_provider.dart, _polling). The logout lands while that
    // read is out. The transaction it was going to send belongs to a login
    // that has ended (#1904, from #1834's review).
    await logIn();
    router.answerAfter(JNAPAction.getDeviceMode, const Duration(seconds: 1));
    final polled = container.read(pollingProvider.notifier).forcePolling();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.received.map((r) => r.action),
        contains(JNAPAction.getDeviceMode.actionValue),
        reason: 'the device-mode read is out');

    final after = await logOut(tester);
    await polled;

    expect(after.where((r) => r.carriesCredential), isEmpty);
  });

  netTest('a firmware check started before the logout sends nothing after it',
      (tester) async {
    // The bug: the dashboard starts the check as it opens, and a logout in the
    // next 5 s leaves its two status reads to go out with the default password.
    await logIn();
    container
        .read(firmwareUpdateProvider.notifier)
        .fetchAvailableFirmwareUpdates();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.received.map((r) => r.action),
        contains(JNAPAction.updateFirmwareNow.actionValue),
        reason: 'the check did start while logged in');

    final after = await logOut(tester);

    expect(after.where((r) => r.carriesCredential), isEmpty);
  });

  netTest(
      'a firmware check whose first request is still being answered at the '
      'logout sends nothing after it', (tester) async {
    // The check reaches its status reads only once the router has answered
    // its first request, which here is after the logout. They belong to the
    // login the check began in, not to whatever is current when they start.
    await logIn();
    router.answerAfter(
        JNAPAction.updateFirmwareNow, const Duration(seconds: 1));
    container
        .read(firmwareUpdateProvider.notifier)
        .fetchAvailableFirmwareUpdates();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.received.map((r) => r.action),
        contains(JNAPAction.updateFirmwareNow.actionValue),
        reason: 'the check did start while logged in');

    final after = await logOut(tester);

    expect(after.where((r) => r.carriesCredential), isEmpty);
  });

  netTest(
      'a firmware install whose request is still being answered at the '
      'logout sends nothing after it, and shows no install', (tester) async {
    await logIn();
    router.answer(
        JNAPAction.getFirmwareUpdateStatus, _firmwareStatus(update: true));
    final firmware = container.read(firmwareUpdateProvider.notifier);
    firmware.fetchAvailableFirmwareUpdates();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 2));
    }
    expect(firmware.getAvailableUpdateNumber(), 1);
    router
      ..answer(JNAPAction.getFirmwareUpdateStatus,
          _firmwareStatus(update: true, installing: true))
      ..answerAfter(JNAPAction.updateFirmwareNow, const Duration(seconds: 1));
    final started = firmware.updateFirmware();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.received.where(_isInstallRequest), hasLength(1),
        reason: 'the install did start while logged in');
    expect(container.read(firmwareUpdateProvider).isUpdating, isTrue);

    final after = await logOut(tester);
    await started;

    expect(after.where((r) => r.carriesCredential), isEmpty);
    expect(container.read(firmwareUpdateProvider).isUpdating, isFalse);
  });

  /// Logged in, with one update found and its install started. The router
  /// reports the install done at its next status read.
  Future<void> startAnInstallAboutToFinish(WidgetTester tester) async {
    await logIn();
    router.answer(
        JNAPAction.getFirmwareUpdateStatus, _firmwareStatus(update: true));
    final firmware = container.read(firmwareUpdateProvider.notifier);
    firmware.fetchAvailableFirmwareUpdates();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 2));
    }
    expect(firmware.getAvailableUpdateNumber(), 1);
    final started = firmware.updateFirmware();
    await tester.pump(const Duration(milliseconds: 200));
    await started;
    expect(router.received.where(_isInstallRequest), hasLength(1),
        reason: 'the install did start while logged in');
  }

  netTest(
      'an install whose last status read is out at the logout, and reports '
      'it done, starts nothing after it', (tester) async {
    // From the review of #1956 (W1). The read went out before the logout and
    // comes back after it. Its "done" must not start the install's
    // completion: a forced poll, a fresh check and polling again, all sent
    // with no login.
    await startAnInstallAboutToFinish(tester);
    router.answerAfter(
        JNAPAction.getFirmwareUpdateStatus, const Duration(seconds: 1));
    // The install's first status read goes out 3 s after it starts.
    await tester.pump(const Duration(milliseconds: 3000));
    expect(
        router.received.where(
            (r) => r.action == JNAPAction.getFirmwareUpdateStatus.actionValue),
        isNotEmpty,
        reason: 'the last status read is out');

    final after = await logOut(tester);

    expect(after.where((r) => r.carriesCredential), isEmpty);
    expect(container.read(firmwareUpdateProvider).isUpdating, isFalse);
  });

  netTest(
      'an install that finishes just before the logout does not start polling '
      'again after it', (tester) async {
    // The narrower window from the same review. The install's completion is
    // already under way when the logout lands, here in its fresh check. What
    // comes after, polling started again, belongs to the login that ended.
    await startAnInstallAboutToFinish(tester);
    // The completion's fresh check: its first request is slow to answer.
    router.answerAfter(
        JNAPAction.updateFirmwareNow, const Duration(seconds: 1));
    bool checkIsOut() => router.received.any((r) =>
        r.action == JNAPAction.updateFirmwareNow.actionValue &&
        r.data['onlyCheck'] == true &&
        router.received.indexOf(r) >
            router.received.lastIndexWhere(_isInstallRequest));
    // The install's first status read, 3 s in, reports it done.
    for (var i = 0; i < 100 && !checkIsOut(); i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(checkIsOut(), isTrue, reason: "the completion's check is out");

    final after = await logOut(tester);

    expect(after.where((r) => r.carriesCredential), isEmpty);
    expect(container.read(firmwareUpdateProvider).isUpdating, isFalse);
    // Polling started again would not show at the router here: its polls are
    // answered from the command cache, whose expiry reads the real clock. Its
    // state would, since logout() reset it and any poll writes it again.
    expect(container.read(pollingProvider).value?.lastUpdate, 0,
        reason: 'polling has not run since the logout reset it');
  });

  netTest('a check ended by a logout leaves the status it had', (tester) async {
    // It has nothing to report. Writing an empty list would tell PnP and the
    // auto-parent first login that no update was found (#1956 review).
    await logIn();
    final firmware = container.read(firmwareUpdateProvider.notifier);
    firmware.fetchAvailableFirmwareUpdates();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 2));
    }
    expect(container.read(firmwareUpdateProvider).nodesStatus, hasLength(1));

    firmware.fetchAvailableFirmwareUpdates();
    await tester.pump(const Duration(milliseconds: 200));
    await logOut(tester);

    expect(container.read(firmwareUpdateProvider).nodesStatus, hasLength(1));
  });

  netTest('a check that continues work from an ended login sends nothing',
      (tester) async {
    // How the install's completion asks for its fresh check: with the
    // install's login. Once that has ended, the check asks the router nothing.
    await logIn();
    final generation = auth().logoutGeneration;
    await auth().logout();
    final mark = router.received.length;

    final checked = container
        .read(firmwareUpdateProvider.notifier)
        .fetchAvailableFirmwareUpdates(logoutGeneration: generation);
    await drainQueue(tester);
    await checked;

    expect(router.received.sublist(mark), isEmpty);
  });

  // ---- #1904 P2: the other owners of a scheduled loop ----

  netTest('a speed test started before the logout sends nothing after it',
      (tester) async {
    // Its status read repeats every 100 ms until the test reports an end
    // (maxRetry: -1). A speed test left running at a logout read on with the
    // default password for as long as the app stayed open.
    await logIn();
    router
      ..answer(JNAPAction.runHealthCheck, const {'resultID': 7})
      ..answer(JNAPAction.getHealthCheckStatus, const {
        'healthCheckModuleCurrentlyRunning': 'SpeedTest',
        'speedTestResult': {
          'resultID': 7,
          'exitCode': 'Unavailable',
          'serverID': '3967',
          'latency': 0,
          'downloadBandwidth': 0,
          'uploadBandwidth': 0,
        },
      });
    final health = container.read(healthCheckProvider.notifier);
    health.runHealthCheck(Module.speedtest);
    await tester.pump(const Duration(seconds: 1));
    expect(
        router.received.where(
            (r) => r.action == JNAPAction.getHealthCheckStatus.actionValue),
        isNotEmpty,
        reason: 'the speed test is running');

    final after = await logOut(tester);

    expect(after.where((r) => r.carriesCredential), isEmpty);
    // Nothing follows the run any more, so the page must not open on it.
    expect(container.read(healthCheckProvider).status, isNot('RUNNING'));
  });

  /// Logs in, starts a status stream the way its page does, and logs out
  /// while it still reads. Returns what the router received after the logout.
  Future<List<_Received>> logOutDuring(WidgetTester tester, JNAPAction action,
      Map<String, dynamic> running, Stream<Object?> Function() start) async {
    await logIn();
    router.answer(action, running);
    // Not cancelled: cancelling an async* loop waits for its next yield,
    // which this test's fake clock would never reach after the case ends. The
    // loop runs out on its own within the time logOut lets pass.
    start().listen((_) {});
    // The first status read goes out 3 s after the stream starts, the next one
    // a second later. Logging out between them keeps a read that is queued at
    // the very moment of the logout out of the count: such a read was built
    // with the user's own credential, and the queue sends it 50 ms later.
    await tester.pump(const Duration(milliseconds: 3500));
    expect(router.received.where((r) => r.action == action.actionValue),
        isNotEmpty,
        reason: 'the status reads are going on');
    return logOut(tester);
  }

  netTest(
      'an Instant Verify ping started before the logout sends nothing '
      'after it', (tester) async {
    final verify = container.read(instantVerifyProvider.notifier);
    final after = await logOutDuring(tester, JNAPAction.getPingStatus,
        const {'isRunning': true, 'pingLog': 'PING 8.8.8.8'}, () {
      verify.ping(host: '8.8.8.8', pingCount: 5);
      return verify.getPingStatus();
    });

    expect(after.where((r) => r.carriesCredential), isEmpty);
    // The run is over, so the page's Execute button is not left disabled.
    expect(container.read(instantVerifyProvider).isRunning, isFalse);
  });

  netTest(
      'an Instant Verify traceroute started before the logout sends '
      'nothing after it', (tester) async {
    final verify = container.read(instantVerifyProvider.notifier);
    final after = await logOutDuring(tester, JNAPAction.getTracerouteStatus,
        const {'isRunning': true, 'tracerouteLog': 'traceroute to 8.8.8.8'},
        () {
      verify.traceroute(host: '8.8.8.8', pingCount: null);
      return verify.getTracerouteStatus();
    });

    expect(after.where((r) => r.carriesCredential), isEmpty);
    expect(container.read(instantVerifyProvider).isRunning, isFalse);
  });

  netTest(
      'a troubleshooting ping started before the logout sends nothing '
      'after it', (tester) async {
    final troubleshooting = container.read(troubleshootingProvider.notifier);
    final after = await logOutDuring(
        tester,
        JNAPAction.getPingStatus,
        const {'isRunning': true, 'pingLog': 'PING 8.8.8.8'},
        troubleshooting.getPingStatus);

    expect(after.where((r) => r.carriesCredential), isEmpty);
  });

  netTest(
      "a node reboot's wait for the node to go offline sends nothing after "
      'the logout, and ends the reboot', (tester) async {
    // After rebooting a node, the topology reads the devices every 3 s, up to
    // 20 times, until the node is offline. The page then forces a poll and
    // starts polling again, so the reboot must end with the logout.
    await logIn();
    router.answer(JNAPAction.getDevices, {
      'devices': [_node('node-1')],
      'revision': 1,
    });
    Object? ended;
    container
        .read(instantTopologyProvider.notifier)
        .reboot(['node-1']).then((_) {}, onError: (Object e) {
      ended = e;
    });
    // The first device read goes out 3 s after the reboot is asked for.
    await tester.pump(const Duration(milliseconds: 4500));
    expect(
        router.received
            .where((r) => r.action == JNAPAction.getDevices.actionValue),
        isNotEmpty,
        reason: 'the wait is under way');

    final after = await logOut(tester);

    expect(after.where((r) => r.carriesCredential), isEmpty);
    expect(ended, isA<LoggedOutException>());
  });

  netTest(
      'a firmware install followed before the logout sends nothing '
      'after it, and shows no install once logged out', (tester) async {
    await logIn();
    router.answer(
        JNAPAction.getFirmwareUpdateStatus, _firmwareStatus(update: true));
    final firmware = container.read(firmwareUpdateProvider.notifier);
    // A check first, so that there is an update to install.
    firmware.fetchAvailableFirmwareUpdates();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 2));
    }
    expect(firmware.getAvailableUpdateNumber(), 1);
    // Still installing at every check, so the install's checks would go on
    // until they run out: 60 of them, 2 s apart.
    router.answer(JNAPAction.getFirmwareUpdateStatus,
        _firmwareStatus(update: true, installing: true));
    final started = firmware.updateFirmware();
    await tester.pump(const Duration(seconds: 4));
    await started;
    expect(router.received.where(_isInstallRequest), hasLength(1),
        reason: 'the install did start while logged in');

    expect(container.read(firmwareUpdateProvider).isUpdating, isTrue);

    final after = await logOut(tester);

    expect(after.where((r) => r.carriesCredential), isEmpty);
    // Nothing follows the install any more, so nothing would ever turn this
    // off: the next login would find a spinner that never ends.
    expect(container.read(firmwareUpdateProvider).isUpdating, isFalse);
  });
}
