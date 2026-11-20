import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/pnp_setup_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../common/di.dart';
import '../../common/testable_router.dart';
import '../../mocks/router_repository_mocks.dart';
import '../../test_data/device_info_test_data.dart';

// Keep transport decisions explicit and deterministic. The real widget and
// BasePnpNotifier's local step-state handling are used throughout these tests.
class _Pnp extends PnpNotifier {
  _Pnp({this.unconfigured = false});

  final bool unconfigured;
  final saveResult = Completer<void>();
  int saves = 0;
  int fetches = 0;
  int deviceFetches = 0;
  int reconnectChecks = 0;
  int radioReads = 0;
  bool changedAdminPassword = false;
  bool configuredAfterSave = true;
  bool clearAuthOnError = false;
  int configuredChecks = 0;
  final checkedPasswords = <String?>[];
  final calls = <String>[];
  // Device mode the provider holds when save() is called (#1748).
  final unconfiguredAtSave = <bool>[];
  // When set, the Auto Master status this fake reports (#1748). When null the
  // real notifier's lookup is used, as before.
  AutoMasterStatus? autoMasterStatus;
  Future<void> Function()? reconnect;
  Future<void> Function(String?)? authenticate;
  // When true, the password check is the real one, sent to the router the test
  // passes to [_showSetup], and [authenticate] is not used.
  bool checksPasswordOnRouter = false;

  @override
  PnpState build() => PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: unconfigured,
        isPrePaired: true,
        stepStateList: const {
          0: PnpStepState(status: StepViewStatus.data, data: {}),
        },
      );

  @override
  Future<void> fetchData() async {
    fetches++;
    // Real PnP enters this page after authentication. Seed the same ready
    // session in the isolated test before the post-save helper reads it.
    await ref.read(authProvider.future);
  }

  @override
  Future<void> fetchDevices() async {
    deviceFetches++;
  }

  @override
  Map<String, dynamic>? getData(JNAPAction action) {
    if (action == JNAPAction.getRadioInfo) radioReads++;
    return super.getData(action);
  }

  @override
  PnpWiFiSettings getDefaultWiFiSettings() => const PnpWiFiSettings(
        isSplitMode: false,
        radios: [
          PnpWiFiRadio(
            radioId: 'RADIO_2.4GHz',
            band: 'RADIO_2.4GHz',
            ssid: 'TestRouter',
            password: 'TestWiFiPassword',
            security: 'WPA2/WPA3-Mixed-Personal',
            isEnabled: true,
          ),
        ],
      );

  @override
  bool get didSetAdminPasswordDuringSave => changedAdminPassword;

  @override
  Future<void> save() {
    saves++;
    calls.add('save');
    unconfiguredAtSave.add(state.isRouterUnConfigured);
    return saveResult.future;
  }

  @override
  Future<void> testConnectionReconnected() async {
    reconnectChecks++;
    calls.add('same-router');
    await reconnect?.call();
  }

  @override
  Future<void> checkAdminPassword(String? password) async {
    checkedPasswords.add(password);
    calls.add('authenticate');
    if (checksPasswordOnRouter) return super.checkAdminPassword(password);
    try {
      await authenticate?.call(password);
    } catch (_) {
      if (clearAuthOnError) {
        (ref.read(authProvider.notifier) as _Auth).clearForPendingLogin();
      }
      rethrow;
    }
  }

  @override
  Future<AutoMasterStatus?> checkAutoMasterStatus() {
    final status = autoMasterStatus;
    return status == null
        ? super.checkAutoMasterStatus()
        : Future.value(status);
  }

  @override
  Future<void> checkRouterConfigured() async {
    configuredChecks++;
    calls.add('configured');
    state = state.copyWith(isUnconfigured: !configuredAfterSave);
  }
}

/// Who refuses the firmware install.
enum _Refusal { router, accessPolicy }

class _Firmware extends FirmwareUpdateNotifier {
  /// [refusal]: an update is available, and the install is refused, by the
  /// router or by the access policy. Without it, no update is available.
  _Firmware({this.refusal});

  final _Refusal? refusal;
  int checks = 0;
  int installs = 0;

  @override
  FirmwareUpdateState build() => FirmwareUpdateState.empty();

  @override
  Future<void> fetchAvailableFirmwareUpdates() async {
    checks++;
  }

  @override
  int getAvailableUpdateNumber() => refusal == null ? 0 : 1;

  /// As the real provider takes a refused install. The access policy refuses
  /// before `isUpdating` is set, so it never changes. The router refuses
  /// after: `isUpdating` turns on, then off, and the error is rethrown.
  /// firmware_update_access_test and firmware_update_provider_test pin that
  /// order on the real provider.
  @override
  Future updateFirmware() async {
    installs++;
    if (refusal == _Refusal.accessPolicy) {
      throw const ReadOnlyAccessException(JNAPAction.updateFirmwareNow);
    }
    state = state.copyWith(isUpdating: true);
    state = state.copyWith(isUpdating: false);
    throw const JNAPError(result: 'ErrorUnknown');
  }
}

class _Auth extends AuthNotifier {
  void clearForPendingLogin() => state = const AsyncValue.loading();
  @override
  Future<AuthState> build() async => const AuthState(
        loginType: LoginType.local,
        localPassword: 'TestAdminPassword',
      );
}

/// The router side of `pnpCheckAdminPassword` on core7 firmware:
/// CheckAdminPassword3, as linksys/JNAP's core.hsl specifies it. A wrong
/// password is ErrorInvalidAdminPassword and starts a delay, and every check
/// during the delay is ErrorPasswordCheckDelayed, the right password included.
/// On the bench (M63, 2026-11-20) the delay outlasted every probe of the
/// reconnect window, so this one never ends.
class _CheckAdminPassword3 {
  _CheckAdminPassword3({required this.adminPassword}) {
    when(repository.send(
      JNAPAction.pnpCheckAdminPassword,
      data: anyNamed('data'),
      extraHeaders: anyNamed('extraHeaders'),
      auth: anyNamed('auth'),
      type: anyNamed('type'),
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((invocation) async {
      final data = invocation.namedArguments[#data] as Map<String, dynamic>;
      return _check(data['adminPassword'] as String?);
    });
  }

  final String adminPassword;
  final repository = MockRouterRepository();

  /// The result of every check the router refused, in order.
  final refusals = <String>[];

  JNAPSuccess _check(String? password) {
    final refusal = refusals.isNotEmpty
        ? errorPasswordCheckDelayed
        : password == adminPassword
            ? null
            : errorInvalidAdminPassword;
    if (refusal == null) {
      return JNAPSuccess(result: 'OK', output: const {'isPasswordValid': true});
    }
    refusals.add(refusal);
    throw JNAPError(result: refusal);
  }
}

/// The real localLogin keeps an accepted password in flutter_secure_storage, a
/// platform channel the test binding does not implement.
void _stubSecureStorage(WidgetTester tester) {
  const channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (_) async => null);
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}

Future<void> _showSetup(WidgetTester tester, _Pnp pnp, _Firmware firmware,
    {bool beginSave = true, RouterRepository? router}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(testableSingleRoute(
    child: const PnpSetupView(),
    locale: const Locale('en'),
    config: LinksysRouteConfig(
      column: ColumnGrid(column: 6, centered: true),
      noNaviRail: true,
    ),
    overrides: [
      pnpProvider.overrideWith(() => pnp),
      firmwareUpdateProvider.overrideWith(() => firmware),
      authProvider.overrideWith(_Auth.new),
      if (router != null) routerRepositoryProvider.overrideWithValue(router),
    ],
  ));
  await tester.pumpAndSettle();
  expect(find.text('Keep current WiFi settings'), findsNothing);
  if (beginSave) {
    await tester.tap(find.text('Next').hitTestable());
    await tester.pump();
    expect(pnp.saves, 1);
  }
}

Future<void> _loseSave(WidgetTester tester, _Pnp pnp) async {
  pnp.saveResult.completeError(ExceptionNeedToReconnect());
  await tester.pump();
  expect(find.text('Reconnecting to your router'), findsOneWidget);
  expect(find.text('Next').hitTestable(), findsNothing);
}

Future<void> _finishReconnectAttempts(WidgetTester tester) async {
  await tester.pump(pnpReconnectInitialDelay);
  for (var attempt = 1; attempt < pnpReconnectMaxAttempts; attempt++) {
    await tester.pump(pnpReconnectRetryDelay);
  }
  await tester.pumpAndSettle();
}

void main() {
  mockDependencyRegister();

  setUp(() {
    final services = getIt.get<ServiceHelper>();
    when(services.isSupportGuestNetwork(any)).thenReturn(false);
    when(services.isSupportLedMode(any)).thenReturn(false);
  });

  testWidgets(
      'lost save automatically reconnects without resaving or radio gate',
      (tester) async {
    final pnp = _Pnp();
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);
    await _loseSave(tester, pnp);

    await tester.pump(pnpReconnectInitialDelay);
    await tester.pumpAndSettle();
    expect(pnp.saves, 1);
    expect(pnp.reconnectChecks, 2); // Post-save and stock final ready check.
    expect(pnp.checkedPasswords, ['TestAdminPassword']);
    expect(pnp.radioReads, 0);
    expect(firmware.checks, 1);
    expect(find.text('Done').hitTestable(), findsOneWidget);
    await tester.pump(const Duration(minutes: 2));
    expect(pnp.saves, 1);
    expect(firmware.checks, 1);
  });

  testWidgets('rapid duplicate Next cannot send two setup transactions',
      (tester) async {
    final pnp = _Pnp();
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware, beginSave: false);
    final next =
        tester.widget<FilledButton>(find.byType(FilledButton).hitTestable());
    // Two input events can arrive before the saving view has repainted.
    next.onPressed!();
    next.onPressed!();
    await tester.pump();
    expect(pnp.saves, 1);
    await _loseSave(tester, pnp);
    expect(firmware.checks, 0);
    await tester.pump(pnpReconnectInitialDelay);
    await tester.pumpAndSettle();
    expect(pnp.saves, 1);
  });

  testWidgets('explicit save rejection never reaches add-nodes or firmware',
      (tester) async {
    final pnp = _Pnp(unconfigured: true);
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);
    pnp.saveResult
        .completeError(ExceptionSavingChanges('ErrorInvalidSettings'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ErrorInvalidSettings'), findsOneWidget);
    expect(find.byType(TextField).hitTestable(), findsNWidgets(2));
    expect(pnp.deviceFetches, 0);
    expect(pnp.reconnectChecks, 0);
    expect(firmware.checks, 0);
    expect(pnp.saves, 1);
  });

  testWidgets('wrong router times out then offers a connection-only retry',
      (tester) async {
    final pnp = _Pnp()
      ..reconnect = () async => throw ExceptionNeedToReconnect();
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);
    await _loseSave(tester, pnp);
    await _finishReconnectAttempts(tester);

    expect(pnp.reconnectChecks, pnpReconnectMaxAttempts);
    expect(pnp.checkedPasswords, isEmpty);
    expect(firmware.checks, 0);
    expect(find.text('Try again').hitTestable(), findsOneWidget);
    await tester.pump(const Duration(minutes: 2));
    expect(pnp.reconnectChecks, pnpReconnectMaxAttempts);
    expect(pnp.saves, 1);
    pnp.reconnect = () async {};
    await tester.tap(find.text('Try again').hitTestable());
    await tester.pumpAndSettle();
    expect(pnp.saves, 1);
    expect(firmware.checks, 1);
  });

  testWidgets('automatic reconnect waits for same-router and password checks',
      (tester) async {
    final sameRouter = Completer<void>();
    final authenticated = Completer<void>();
    final pnp = _Pnp();
    pnp.reconnect = () => sameRouter.future;
    pnp.authenticate = (_) => authenticated.future;
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);
    await _loseSave(tester, pnp);
    await tester.pump(pnpReconnectInitialDelay);
    expect(pnp.reconnectChecks, 1);
    expect(pnp.checkedPasswords, isEmpty);
    expect(firmware.checks, 0);

    sameRouter.complete();
    await tester.pump();
    expect(pnp.checkedPasswords, ['TestAdminPassword']);
    expect(firmware.checks, 0);
    authenticated.complete();
    await tester.pumpAndSettle();

    expect(pnp.calls.take(3), ['save', 'same-router', 'authenticate']);
    expect(pnp.saves, 1);
    expect(firmware.checks, 1);
    expect(find.text('Done').hitTestable(), findsOneWidget);
  });

  testWidgets('login password fallback occurs only after same-router check',
      (tester) async {
    // The save did not land, so the router still has the password PnP logged
    // in with.
    final pnp = _Pnp()
      ..changedAdminPassword = true
      ..authenticate = (password) async {
        if (password == 'TestWiFiPassword') {
          throw ExceptionInvalidAdminPassword();
        }
      };
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);
    await _loseSave(tester, pnp);
    await tester.pump(pnpReconnectInitialDelay);
    await tester.pumpAndSettle();

    expect(pnp.checkedPasswords, ['TestWiFiPassword', 'TestAdminPassword']);
    expect(pnp.calls.take(4),
        ['save', 'same-router', 'authenticate', 'authenticate']);
    expect(pnp.saves, 1);
    expect(find.text('Done').hitTestable(), findsOneWidget);
  });

  testWidgets(
      'factory-default save on CheckAdminPassword3 reaches Done without a refused check',
      (tester) async {
    // The save made the WiFi password the admin password, so the default the
    // app logged in with is now wrong. The real checkAdminPassword runs,
    // against core7's password check.
    final router = _CheckAdminPassword3(adminPassword: 'TestWiFiPassword');
    final pnp = _Pnp()
      ..changedAdminPassword = true
      ..checksPasswordOnRouter = true;
    final firmware = _Firmware();
    _stubSecureStorage(tester);
    await _showSetup(tester, pnp, firmware, router: router.repository);
    await _loseSave(tester, pnp);
    await _finishReconnectAttempts(tester);

    expect(router.refusals, isEmpty);
    expect(find.text('Done').hitTestable(), findsOneWidget);
  });

  testWidgets(
      'rejected reconnect password stops automatic attempts and permits retry',
      (tester) async {
    final pnp = _Pnp()
      ..authenticate = (_) async => throw ExceptionInvalidAdminPassword();
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);
    await _loseSave(tester, pnp);
    await tester.pump(pnpReconnectInitialDelay);
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(pnp.checkedPasswords, ['TestAdminPassword']);
    expect(firmware.checks, 0);
    expect(pnp.saves, 1);
    expect(find.text('Try again').hitTestable(), findsOneWidget);
    pnp.authenticate = (_) async {};
    await tester.tap(find.text('Try again').hitTestable());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(pnp.saves, 1);
    expect(firmware.checks, 1);
    expect(find.text('Done').hitTestable(), findsOneWidget);
  });

  testWidgets('transient auth loading does not discard accepted password',
      (tester) async {
    var attempts = 0;
    final pnp = _Pnp()
      ..clearAuthOnError = true
      ..authenticate = (_) async {
        if (++attempts == 1) throw ExceptionNeedToReconnect();
      };
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);
    await _loseSave(tester, pnp);
    await tester.pump(pnpReconnectInitialDelay);
    expect(pnp.checkedPasswords, ['TestAdminPassword']);
    await tester.pump(pnpReconnectRetryDelay);
    await tester.pumpAndSettle();
    expect(pnp.checkedPasswords, ['TestAdminPassword', 'TestAdminPassword']);
    expect(pnp.saves, 1);
    expect(firmware.checks, 1);
  });

  testWidgets('unconfigured router cannot advance an ambiguous save',
      (tester) async {
    final pnp = _Pnp(unconfigured: true)..configuredAfterSave = false;
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);
    await _loseSave(tester, pnp);
    await _finishReconnectAttempts(tester);
    expect(pnp.configuredChecks, pnpReconnectMaxAttempts);
    expect(pnp.deviceFetches, 0);
    expect(firmware.checks, 0);
    expect(find.text('Try again').hitTestable(), findsOneWidget);

    pnp.configuredAfterSave = true;
    await tester.tap(find.text('Try again').hitTestable());
    await tester.pumpAndSettle();
    expect(pnp.saves, 1);
    expect(pnp.deviceFetches, 1);
    expect(firmware.checks, 0);
  });

  testWidgets('disposal prevents late password fallback or continuation',
      (tester) async {
    final authentication = Completer<void>();
    final pnp = _Pnp()
      ..changedAdminPassword = true
      ..authenticate = (_) => authentication.future;
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);
    await _loseSave(tester, pnp);
    await tester.pump(pnpReconnectInitialDelay);
    expect(pnp.checkedPasswords, ['TestWiFiPassword']);
    await tester.pumpWidget(const SizedBox());
    authentication.completeError(ExceptionInvalidAdminPassword());
    await tester.pump();
    await tester.pump(pnpReconnectRetryDelay);
    expect(pnp.checkedPasswords, ['TestWiFiPassword']);
    expect(firmware.checks, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deadline exposes pending check without late auth or overlap',
      (tester) async {
    final reachable = Completer<void>();
    final pnp = _Pnp()..reconnect = () => reachable.future;
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);
    await _loseSave(tester, pnp);
    await tester.pump(pnpReconnectInitialDelay);
    await tester.pump(pnpReconnectDeadline);
    await tester.pumpAndSettle();
    expect(find.text('Your router is not ready yet'), findsOneWidget);
    expect(find.textContaining('previous connection check is still ending'),
        findsOneWidget);
    final retry =
        tester.widget<FilledButton>(find.byType(FilledButton).hitTestable());
    expect(retry.onPressed, isNull);
    expect(pnp.reconnectChecks, 1);
    reachable.complete();
    await tester.pump();
    await tester.pump(pnpReconnectRetryDelay);
    await tester.pumpAndSettle();
    expect(pnp.checkedPasswords, isEmpty);
    expect(firmware.checks, 0);
    expect(
        tester
            .widget<FilledButton>(find.byType(FilledButton).hitTestable())
            .onPressed,
        isNotNull);
    pnp.reconnect = () async {};
    final enabled =
        tester.widget<FilledButton>(find.byType(FilledButton).hitTestable());
    enabled.onPressed!();
    enabled.onPressed!();
    await tester.pumpAndSettle();
    expect(pnp.saves, 1);
    expect(pnp.checkedPasswords, ['TestAdminPassword']);
    expect(firmware.checks, 1);
    expect(tester.takeException(), isNull);
  });

  // #1748: PnP read the device mode while Auto Master was still running and
  // cached `Unconfigured`. Auto Master then made the router Master, and after
  // the re-login setup is entered with Auto Master already `complete`. The
  // save must not be built from the stale value, or it sends
  // `SetDeviceMode Master` and firmware rejects it with ErrorAlreadyMaster.
  testWidgets(
      'stale unconfigured mode is re-read after Auto Master completes (#1748)',
      (tester) async {
    final pnp = _Pnp(unconfigured: true)
      ..autoMasterStatus = AutoMasterStatus.complete
      ..configuredAfterSave = true; // GetDeviceMode now answers Master.
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);

    expect(pnp.configuredChecks, 1);
    expect(pnp.calls, ['configured', 'save']);
    expect(pnp.unconfiguredAtSave, [false]);
  });

  testWidgets(
      'still-unconfigured router keeps SetDeviceMode after Auto Master (#1748)',
      (tester) async {
    final pnp = _Pnp(unconfigured: true)
      ..autoMasterStatus = AutoMasterStatus.complete
      ..configuredAfterSave =
          false; // GetDeviceMode still answers Unconfigured.
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);

    expect(pnp.configuredChecks, 1);
    expect(pnp.unconfiguredAtSave, [true]);
  });

  for (final status in [AutoMasterStatus.idle, AutoMasterStatus.running]) {
    testWidgets(
        'unconfigured router without completed Auto Master is not re-read '
        '(${status.name}, #1748)', (tester) async {
      final pnp = _Pnp(unconfigured: true)
        ..autoMasterStatus = status
        ..configuredAfterSave = true;
      final firmware = _Firmware();
      await _showSetup(tester, pnp, firmware, beginSave: false);

      expect(pnp.configuredChecks, 0);
      expect(pnp.state.isRouterUnConfigured, isTrue);
    });
  }

  testWidgets('configured router is not re-read after Auto Master (#1748)',
      (tester) async {
    final pnp = _Pnp()..autoMasterStatus = AutoMasterStatus.complete;
    final firmware = _Firmware();
    await _showSetup(tester, pnp, firmware);

    expect(pnp.configuredChecks, 0);
    expect(pnp.unconfiguredAtSave, [false]);
  });

  for (final reachable in [true, false]) {
    testWidgets(
        'stock Wi-Fi-ready screen does not poll radios when router is '
        '${reachable ? 'reachable' : 'unreachable'}', (tester) async {
      final pnp = _Pnp();
      if (!reachable) {
        pnp.reconnect = () async => throw ExceptionNeedToReconnect();
      }
      final firmware = _Firmware();
      await _showSetup(tester, pnp, firmware);
      pnp.saveResult.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(pnp.saves, 1);
      expect(firmware.checks, 1);
      expect(pnp.reconnectChecks, 1);
      expect(pnp.fetches, 1);
      expect(pnp.radioReads, 0);
      expect(find.text('Done').hitTestable(), findsOneWidget);
      await tester.pump(const Duration(minutes: 2));
      expect(pnp.reconnectChecks, 1);
      expect(pnp.radioReads, 0);
    });
  }

  for (final (refusal, who) in [
    (_Refusal.router, 'the router'),
    (_Refusal.accessPolicy, 'the access policy'),
  ]) {
    testWidgets('a firmware install $who refuses still goes on to Wi-Fi Ready',
        (tester) async {
      final pnp = _Pnp();
      final firmware = _Firmware(refusal: refusal);
      await _showSetup(tester, pnp, firmware);
      pnp.saveResult.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(firmware.installs, 1);
      expect(find.text('Done').hitTestable(), findsOneWidget);
      // Two minutes on, nothing has started the install again.
      await tester.pump(const Duration(minutes: 2));
      expect(firmware.installs, 1);
    });
  }
}
