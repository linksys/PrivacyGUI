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
// The cases for the firmware check and the firmware install are red on the
// base branch: that is the bug #1904 reports. They are skipped until #1904 P1
// ties that work to the session. Run them with `skip: false` to see it.
//
// #1904 P2 adds a case here for each of the other scheduled owners.

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
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/di.dart';

/// Skipped until #1904 P1: on the base branch these cases are red, because
/// the firmware check and the install go on after a logout.
const _redUntil1904P1 = true;

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

/// One request as the router received it.
class _Received {
  _Received(this.action, this.header);

  final String action;
  final Map<String, String> header;

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
  final List<_Received> received = [];

  @override
  Future<Response> execute(BaseCommand command) async {
    final http = command as BaseHttpCommand;
    received.add(_Received(command.spec.action, Map.of(http.header)));
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
    expect(router.received.where((r) => r.action.contains('Transaction')),
        isNotEmpty,
        reason: 'polling did run while logged in');

    final after = await logOut(tester);

    expect(after, isEmpty);
  });

  netTest('a firmware check started before the logout sends nothing after it',
      skip: _redUntil1904P1, (tester) async {
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
      'a firmware install followed before the logout sends nothing '
      'after it',
      skip: _redUntil1904P1, (tester) async {
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
    // Still installing at every check, so the install's checks never end on
    // their own while the case runs.
    router.answer(JNAPAction.getFirmwareUpdateStatus,
        _firmwareStatus(update: true, installing: true));
    final started = firmware.updateFirmware();
    await tester.pump(const Duration(seconds: 4));
    await started;
    expect(router.received.map((r) => r.action),
        contains(JNAPAction.updateFirmwareNow.actionValue),
        reason: 'the install did start while logged in');

    final after = await logOut(tester);

    expect(after.where((r) => r.carriesCredential), isEmpty);
  });
}
