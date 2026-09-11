// Behavioural tests for the troubleshooter's ISP-save view.
//
// This view had no tests at all, yet it carries two things that are easy to
// lose in a merge:
//
//   1. The pre-save Auto Master gate (`_checkAndWaitForAutoMaster`), including
//      the `autoMasterRotatedSinceLogin` narrowing. The firmware latches
//      GetAutoMasterStatus at `complete` forever, so redirecting on `complete`
//      alone bounces every previously auto-mastered router straight back to PnP
//      and the user can never save their PPPoE settings at all.
//   2. The post-WAN-up Auto Master wait and the mid-check credential-rotation
//      `catchError`, where a rotation is *success* and must not be reported as
//      an ISP settings failure.
//
// Both live in hunks that a patch touching this file has to merge by hand.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_save_settings_view.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_waiting_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../../../../../common/di.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../mocks/internet_settings_notifier_mocks.dart';
import '../../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import '../../../../../mocks/pnp_troubleshooter_notifier_mocks.dart';
import '../../../../../test_data/device_info_test_data.dart';
import '../../../../../test_data/internet_settings_state_data.dart';

/// English text of `loc(context).pnpErrorForStaticIpAndDhcp` — what the view
/// pops for a DHCP/static failure. Asserting the string (not merely non-null)
/// pins the wanType -> message mapping in `_getErrorMessage`.
const dhcpErrorMessage =
    "Couldn't establish a connection. Please check your info and try again.";

LinksysRouteConfig _routeConfig() => LinksysRouteConfig(
    column: ColumnGrid(column: 6, centered: true), noNaviRail: true);

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;
  late MockPnpTroubleshooterNotifier mockTroubleshooterNotifier;
  late InternetSettingsState newSettings;

  /// Whatever the pushed route popped with, or null if it has not popped.
  Object? poppedWith;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

  void stubPnpState({bool autoMasterRotatedSinceLogin = false}) {
    when(mockPnpNotifier.build()).thenReturn(PnpState(
      deviceInfo: NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
      isUnconfigured: true,
      autoMasterRotatedSinceLogin: autoMasterRotatedSinceLogin,
    ));
  }

  /// The real notifier emits the per-attempt verdict on the stream and then
  /// calls `onCompleted`; reproduce that order, since the view relies on it
  /// (`settingError` is assigned in the listener and read in `onCompleted`).
  void stubCheckNewSettings({required bool isValid}) {
    when(mockTroubleshooterNotifier.checkNewSettings(
      settingWanType: anyNamed('settingWanType'),
      onCompleted: anyNamed('onCompleted'),
    )).thenAnswer((invocation) {
      final onCompleted = invocation.namedArguments[const Symbol('onCompleted')]
          as Function(bool);
      Stream<bool> emit() async* {
        yield isValid;
        onCompleted(!isValid);
      }

      return emit();
    });
  }

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();
    mockTroubleshooterNotifier = MockPnpTroubleshooterNotifier();
    poppedWith = null;

    when(mockServiceHelper.isSupportGuestNetwork(any)).thenReturn(true);
    when(mockServiceHelper.isSupportLedMode(any)).thenReturn(true);

    stubPnpState();
    when(mockPnpNotifier.fetchData()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkInternetConnection(any))
        .thenAnswer((_) => Future<dynamic>.value(true));

    // ipv4ConnectionType is "DHCP" in this fixture -> WanType.dhcp.
    newSettings = InternetSettingsState.fromJson(internetSettingsStateData);
    when(mockInternetSettingsNotifier.build()).thenReturn(newSettings);
    when(mockInternetSettingsNotifier.savePnpIpv4(any))
        .thenAnswer((_) => Future<dynamic>.value());

    when(mockTroubleshooterNotifier.build())
        .thenReturn(PnpTroubleshooterState.init());
    stubCheckNewSettings(isValid: true);
  });

  /// A stream that neither emits nor closes, so the mixin's `await for` parks
  /// and the view stays on the waiting view.
  Stream<AutoMasterStatus?> neverEnding() =>
      StreamController<AutoMasterStatus?>().stream;

  /// Pumps a three-route stack and *pushes* the view under test, so
  /// `context.pop(message)` has a route to return to and its argument is
  /// observable. `context.goNamed(pnp)` is observed via [pnpStub] instead.
  Future<void> pumpSaveView(WidgetTester tester) async {
    final router = GoRouter(
      navigatorKey: shellNavigatorKey,
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          config: _routeConfig(),
          builder: (context, state) =>
              const SizedBox.shrink(key: Key('hostStub')),
        ),
        LinksysRoute(
          path: '/${RoutePath.pnpIspSaveSettings}',
          name: RouteNamed.pnpIspSaveSettings,
          config: _routeConfig(),
          builder: (context, state) => PnpIspSaveSettingsView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
        LinksysRoute(
          path: RoutePath.pnp,
          name: RouteNamed.pnp,
          config: _routeConfig(),
          builder: (context, state) =>
              const SizedBox.shrink(key: Key('pnpStub')),
        ),
      ],
    );

    await tester.pumpWidget(testableRouter(
      router: router,
      overrides: [
        pnpProvider.overrideWith(() => mockPnpNotifier),
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
        pnpTroubleshooterProvider
            .overrideWith(() => mockTroubleshooterNotifier),
      ],
    ));
    await tester.pump();

    router.pushNamed(
      RouteNamed.pnpIspSaveSettings,
      extra: {'newSettings': newSettings},
    ).then((value) => poppedWith = value);
    await tester.pump();
  }

  /// The flow crosses stream subscriptions and mock futures that only settle on
  /// real event-loop turns, so drain there and then render. Leaving an `await
  /// for` early cancels the subscription, and that cancellation only completes
  /// on a real turn — the mixin does it up to twice per run, hence the rounds.
  Future<void> settleFlow(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  final onPnp = find.byKey(const Key('pnpStub'));
  final onSpinner = find.byType(AppFullScreenSpinner);
  final onWaitingView = find.byType(PnpAutoMasterWaitingView);
  final onAutoMasterError = find.byIcon(LinksysIcons.signalWifiOff);

  // ===========================================================================
  // Pre-save Auto Master gate
  // ===========================================================================

  group('Troubleshooter - ISP save: pre-save Auto Master gate', () {
    testWidgets('Running holds the save until the wait resolves',
        (tester) async {
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.running);
      when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer((_) => neverEnding());

      await pumpSaveView(tester);
      await settleFlow(tester);

      // Still parked on the waiting view, and crucially nothing was written.
      expect(onWaitingView, findsOneWidget);
      expect(onSpinner, findsNothing);
      expect(onAutoMasterError, findsNothing);
      verifyNever(mockInternetSettingsNotifier.savePnpIpv4(any));
    });

    testWidgets('Running then Complete redirects to pnp without saving',
        (tester) async {
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.running);
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.complete));

      await pumpSaveView(tester);
      await settleFlow(tester);

      expect(onPnp, findsOneWidget);
      verifyNever(mockInternetSettingsNotifier.savePnpIpv4(any));
    });

    testWidgets('Running then Failed continues to the save', (tester) async {
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.running);
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.failed));
      // Park after the write so the assertion is about the write itself.
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => neverEnding());

      await pumpSaveView(tester);
      await settleFlow(tester);

      verify(mockInternetSettingsNotifier.savePnpIpv4(any)).called(1);
    });

    testWidgets('Budget spent with the router gone shows the connection error',
        (tester) async {
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.running);
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
      when(mockPnpNotifier.testConnectionReconnected())
          .thenAnswer((_) => Future<dynamic>.error(ExceptionNeedToReconnect()));

      await pumpSaveView(tester);
      await settleFlow(tester);

      expect(onAutoMasterError, findsOneWidget);
      verifyNever(mockInternetSettingsNotifier.savePnpIpv4(any));
    });

    testWidgets('Unavailable status continues to the save', (tester) async {
      // null = unreachable router, or firmware that will not serve the status
      // unauthed. Nothing to wait for.
      when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async => null);
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => neverEnding());

      await pumpSaveView(tester);
      await settleFlow(tester);

      verify(mockInternetSettingsNotifier.savePnpIpv4(any)).called(1);
      verifyNever(mockPnpNotifier.pollAutoMasterStatus());
    });

    testWidgets('Idle continues to the save', (tester) async {
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.idle);
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => neverEnding());

      await pumpSaveView(tester);
      await settleFlow(tester);

      verify(mockInternetSettingsNotifier.savePnpIpv4(any)).called(1);
    });

    // The regression this branch's narrowing exists for: the firmware latches
    // `complete` permanently, so on any router that has ever been
    // auto-mastered, an unqualified `complete` check bounces to PnP before
    // saving -> PnP finds no internet -> back to the troubleshooter -> loop, and
    // the PPPoE settings can never be saved.
    testWidgets(
        'Complete without a rotation since login continues to the save',
        (tester) async {
      stubPnpState(autoMasterRotatedSinceLogin: false);
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.complete);
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => neverEnding());

      await pumpSaveView(tester);
      await settleFlow(tester);

      // No bounce to PnP, and the write actually happened. (The view does end
      // up on the waiting view afterwards — that is the *post*-WAN-up wait,
      // which only exists because the save went through.)
      expect(onPnp, findsNothing);
      verify(mockInternetSettingsNotifier.savePnpIpv4(any)).called(1);
    });

    testWidgets('Complete after a rotation since login redirects to pnp',
        (tester) async {
      stubPnpState(autoMasterRotatedSinceLogin: true);
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.complete);

      await pumpSaveView(tester);
      await settleFlow(tester);

      expect(onPnp, findsOneWidget);
      verifyNever(mockInternetSettingsNotifier.savePnpIpv4(any));
    });
  });

  // ===========================================================================
  // Post-WAN-up Auto Master wait
  // ===========================================================================

  group('Troubleshooter - ISP save: after WAN comes up', () {
    setUp(() {
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.idle);
    });

    testWidgets('waits for Auto Master to start, then redirects to pnp',
        (tester) async {
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.complete));

      await pumpSaveView(tester);
      await settleFlow(tester);

      // waitForRunningFirst: true — phase A must run before phase B.
      verify(mockPnpNotifier.pollAutoMasterUntilRunning()).called(1);
      verify(mockPnpNotifier.pollAutoMasterStatus()).called(1);
      expect(onPnp, findsOneWidget);
      expect(poppedWith, isNull);
    });

    testWidgets('an unknown Auto Master outcome still redirects to pnp',
        (tester) async {
      // budgetExhausted: the settings are already saved, so there is nothing
      // pending here — PnP re-reads whatever state the router is in.
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
      when(mockPnpNotifier.testConnectionReconnected())
          .thenAnswer((_) => Future<dynamic>.value(true));

      await pumpSaveView(tester);
      await settleFlow(tester);

      expect(onPnp, findsOneWidget);
    });

    testWidgets('no internet connection pops the ISP error message',
        (tester) async {
      when(mockPnpNotifier.checkInternetConnection(any)).thenAnswer(
          (_) => Future<dynamic>.error(ExceptionNoInternetConnection()));

      await pumpSaveView(tester);
      await settleFlow(tester);

      expect(poppedWith, dhcpErrorMessage);
      expect(onPnp, findsNothing);
      verifyNever(mockPnpNotifier.pollAutoMasterUntilRunning());
    });

    // A rotation inside the ~90s internet-check window IS Auto Master
    // succeeding. Popping an ISP error here would blame the settings the user
    // just got right.
    testWidgets('a rotation mid-check goes back to pnp, not an ISP error',
        (tester) async {
      when(mockPnpNotifier.checkInternetConnection(any)).thenAnswer(
          (_) => Future<dynamic>.error(ExceptionInvalidAdminPassword()));

      await pumpSaveView(tester);
      await settleFlow(tester);

      expect(onPnp, findsOneWidget);
      expect(poppedWith, isNot(dhcpErrorMessage));
    });

    testWidgets(
        'Try Again after WAN is up re-enters via pnp instead of re-saving',
        (tester) async {
      when(mockPnpNotifier.pollAutoMasterUntilRunning())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
      when(mockPnpNotifier.testConnectionReconnected())
          .thenAnswer((_) => Future<dynamic>.error(ExceptionNeedToReconnect()));

      await pumpSaveView(tester);
      await settleFlow(tester);
      expect(onAutoMasterError, findsOneWidget);

      await tester.tap(find.byType(AppFilledButton));
      await settleFlow(tester);

      // _autoMasterPostWanUp == true: the settings are already written, so the
      // recovery path is re-entry, never a second write.
      expect(onPnp, findsOneWidget);
      verify(mockInternetSettingsNotifier.savePnpIpv4(any)).called(1);
    });
  });

  // ===========================================================================
  // Pre-save retry and save failures
  // ===========================================================================

  group('Troubleshooter - ISP save: failure paths', () {
    testWidgets('Try Again before the save re-runs the save from the top',
        (tester) async {
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.running);
      when(mockPnpNotifier.pollAutoMasterStatus())
          .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
      when(mockPnpNotifier.testConnectionReconnected())
          .thenAnswer((_) => Future<dynamic>.error(ExceptionNeedToReconnect()));

      await pumpSaveView(tester);
      await settleFlow(tester);
      expect(onAutoMasterError, findsOneWidget);
      verify(mockPnpNotifier.checkAutoMasterStatus()).called(1);

      await tester.tap(find.byType(AppFilledButton));
      await settleFlow(tester);

      // _autoMasterPostWanUp == false: nothing was written yet, so the whole
      // save (gate included) runs again.
      verify(mockPnpNotifier.checkAutoMasterStatus()).called(1);
      expect(onPnp, findsNothing);
    });

    testWidgets('a JNAPError from the write pops the ISP error message',
        (tester) async {
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.idle);
      when(mockInternetSettingsNotifier.savePnpIpv4(any)).thenAnswer(
          (_) => Future<dynamic>.error(JNAPError(result: '', error: 'error')));

      await pumpSaveView(tester);
      await settleFlow(tester);

      expect(poppedWith, dhcpErrorMessage);
      verifyNever(mockPnpNotifier.checkInternetConnection(any));
    });

    testWidgets('a failing new-settings check pops the ISP error message',
        (tester) async {
      when(mockPnpNotifier.checkAutoMasterStatus())
          .thenAnswer((_) async => AutoMasterStatus.idle);
      stubCheckNewSettings(isValid: false);

      await pumpSaveView(tester);
      await settleFlow(tester);

      expect(poppedWith, dhcpErrorMessage);
      verifyNever(mockPnpNotifier.checkInternetConnection(any));
    });
  });
}
