// Widget tests for the trigger site of #1419.
//
// A background poll that stops getting answers is the only way the router can go
// away that nothing else on screen reports: every deliberate disappearance is
// announced by the flow that caused it, while a failing poll left the provider in
// an error state that keeps its previous value - so the dashboard went on
// presenting the last good snapshot as if it were live. AppRootContainer is where
// the app notices, because it is the only widget that outlives every route and
// has the WidgetRef to listen with.
//
// Most of the harness drives [routerUnreachableProvider] directly rather than
// through PollingNotifier: how long a router has to be silent before it counts as
// unreachable is settled in polling_provider_test.dart, and what is under test
// here is only the decision to put the alert on screen - the route exemption, the
// login guard, and the promise that instances never stack.
//
// The last group is the exception, and runs the alert's own Try again button
// against the real PollingNotifier, because that button is the only way out of a
// blocking dialog and its recovery crosses all three parts: the dialog, the
// provider, and the trigger that must not immediately fire again.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/components/layouts/root_container.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/instant_privacy_provider_mocks.dart';
import '../../../mocks/router_repository_mocks.dart';
import '../../../test_data/device_info_test_data.dart';

/// An [AuthNotifier] that reports a login state and does nothing else.
///
/// The real one reads shared preferences and secure storage on the way to an
/// answer; all this trigger asks of it is whether anybody is logged in.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this.loginType);

  final LoginType loginType;

  @override
  Future<AuthState> build() => Future.value(AuthState(loginType: loginType));
}

/// A [DashboardManagerNotifier] whose router-is-back check answers whichever way
/// the test needs.
///
/// The real one compares the serial number it reads back against the one in
/// shared preferences, and its build watches the very poll it is standing in for
/// here. Whether the router answered is the only part of it the alert's Try again
/// button acts on.
class _FakeDashboardManagerNotifier extends DashboardManagerNotifier {
  _FakeDashboardManagerNotifier({required this.routerIsBack});

  final bool routerIsBack;

  @override
  DashboardManagerState build() => createState();

  @override
  Future<NodeDeviceInfo> checkRouterIsBack() async {
    if (!routerIsBack) {
      throw Exception('[CheckRouterBack]: SN not match');
    }
    return NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']);
  }
}

void main() {
  mockDependencyRegister();

  late ProviderContainer container;

  /// The route config the container is built with, swappable mid-test.
  ///
  /// Only the exemption test changes it, and it swaps the config in place rather
  /// than pumping a second widget tree so that the same ProviderContainer, the
  /// same [AppRootContainer] state and the same listener stay in place - which is
  /// what a second report has to travel through.
  late ValueNotifier<LinksysRouteConfig?> routeConfig;

  /// The alert, found by its localized title.
  final alert = find.text('Router Not Found');

  Future<void> pumpRootContainer(
    WidgetTester tester, {
    LoginType loginType = LoginType.local,
    LinksysRouteConfig? config,
    List<Override> overrides = const [],
  }) async {
    // A desktop surface, because the alert is sized for one: its three bullets
    // and the Try again button do not fit the 800x600 default, and a laid-out
    // dialog is what the assertions below are looking at.
    await tester.setScreenSize(device1440w);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    container = ProviderContainer(overrides: [
      authProvider.overrideWith(() => _FakeAuthNotifier(loginType)),
      ...overrides,
    ]);
    addTearDown(container.dispose);
    // The login guard reads authProvider synchronously, and an AsyncNotifier
    // nobody has read yet is still loading. Settle it here so these tests are
    // about the route and the report rather than about start-up timing.
    await container.read(authProvider.future);

    routeConfig = ValueNotifier(config);
    addTearDown(routeConfig.dispose);

    await tester.pumpWidget(testableSingleRoute(
      provider: container,
      locale: const Locale('en'),
      child: ValueListenableBuilder<LinksysRouteConfig?>(
        valueListenable: routeConfig,
        builder: (context, config, _) => AppRootContainer(
          route: LinksysRoute(
            name: 'test',
            path: '/',
            config: config,
            builder: (context, state) => const SizedBox.shrink(),
          ),
          child: const Text('dashboard'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Leaves polling in the state a router that has been silent for
  /// [pollUnreachableAfterInSec] leaves it in.
  ///
  /// Every failed poll from there on reports again, hence the increment rather
  /// than a set: what the trigger has to do with a second report is half of what
  /// is under test here.
  Future<void> reportUnreachable(WidgetTester tester) async {
    final reports = container.read(routerUnreachableProvider.notifier);
    reports.state = reports.state + 1;
    await tester.pumpAndSettle();
  }

  /// And what a router that answers again leaves behind.
  Future<void> withdrawReport(WidgetTester tester) async {
    container.read(routerUnreachableProvider.notifier).state = 0;
    await tester.pumpAndSettle();
  }

  /// Closes the alert the way its Try again button does.
  ///
  /// Not tidying-up for its own sake: the single-instance flag lives for as long
  /// as the alert is on screen, and a widget tree torn down with a dialog still
  /// up never completes its route - which would leave the flag set for every test
  /// after this one.
  Future<void> closeAlert(WidgetTester tester) async {
    shellNavigatorKey.currentState?.pop();
    await tester.pumpAndSettle();
  }

  group('raising the alert', () {
    testWidgets('a router that stops answering raises the alert',
        (tester) async {
      await pumpRootContainer(tester);
      expect(alert, findsNothing);

      await reportUnreachable(tester);

      expect(alert, findsOneWidget);

      await closeAlert(tester);
    });

    testWidgets('a route that raises the alert itself gets no second one',
        (tester) async {
      // Firmware update is the case: it takes the router away for minutes, says
      // so itself, and must not have a second alert pushed in from behind over
      // its progress screen.
      await pumpRootContainer(tester,
          config: const LinksysRouteConfig(ignoreConnectivityEvent: true));

      await reportUnreachable(tester);

      expect(alert, findsNothing);
    });

    testWidgets('a report dropped by an exempt route is not lost',
        (tester) async {
      // Why the trigger listens to a count rather than to a settled flag. The
      // exempt route is the one thing here that comes and goes: an update that
      // finishes with the router still away leaves an operator on an ordinary
      // page in front of a dashboard nothing is feeding, and the next failed poll
      // is what has to tell them.
      await pumpRootContainer(tester,
          config: const LinksysRouteConfig(ignoreConnectivityEvent: true));

      await reportUnreachable(tester);
      expect(alert, findsNothing, reason: 'that route says so itself');

      routeConfig.value = null;
      await tester.pumpAndSettle();
      expect(alert, findsNothing,
          reason: 'leaving it raises nothing by itself');

      await reportUnreachable(tester);

      expect(alert, findsOneWidget);

      await closeAlert(tester);
    });

    testWidgets('the alert never stacks', (tester) async {
      // Ticks keep failing every interval while the router is away, and each one
      // reports again. The alert is blocking and cannot be dismissed, so a second
      // copy would have to be worked through one tap at a time.
      await pumpRootContainer(tester);

      await reportUnreachable(tester);
      await reportUnreachable(tester);
      await reportUnreachable(tester);

      expect(alert, findsOneWidget);

      await closeAlert(tester);
    });

    testWidgets('the alert can be raised again once it has been closed',
        (tester) async {
      // The flip side of never stacking: the guard must be released when the
      // alert goes, or the router could only ever be reported unreachable once
      // per session.
      await pumpRootContainer(tester);

      await reportUnreachable(tester);
      await closeAlert(tester);
      expect(alert, findsNothing);

      await withdrawReport(tester);
      await reportUnreachable(tester);

      expect(alert, findsOneWidget);

      await closeAlert(tester);
    });

    testWidgets('nothing is raised before anybody is logged in',
        (tester) async {
      // Polling is not running for the user's benefit yet, and the login page has
      // no stale dashboard to correct.
      await pumpRootContainer(tester, loginType: LoginType.none);

      await reportUnreachable(tester);

      expect(alert, findsNothing);
    });
  });

  group('recovering through Try again', () {
    // The alert cannot be dismissed, so Try again is the only way out of it, and
    // #1419's fix leans on the whole of that path: the button re-checks the
    // router, restarts polling - which is what withdraws the report - and pops
    // itself. A report left standing behind it would put the dialog straight back
    // up, locking the operator out of an app whose router had come back.

    late List<JNAPTransactionBuilder> transactions;

    /// Raises the alert over a container whose polling is the real thing.
    Future<void> pumpAlert(WidgetTester tester,
        {required bool routerIsBack}) async {
      // JNAPAction.actionValue reads a map main() populates at start-up, and the
      // poll this restarts builds its commands from it.
      initBetterActions();
      transactions = [];
      final mockRepo = MockRouterRepository();
      when(mockRepo.send(
        any,
        data: anyNamed('data'),
        extraHeaders: anyNamed('extraHeaders'),
        auth: anyNamed('auth'),
        type: anyNamed('type'),
        fetchRemote: anyNamed('fetchRemote'),
        cacheLevel: anyNamed('cacheLevel'),
        timeoutMs: anyNamed('timeoutMs'),
        retries: anyNamed('retries'),
        sideEffectOverrides: anyNamed('sideEffectOverrides'),
      )).thenAnswer((_) async =>
          JNAPSuccess(result: 'OK', output: const {'mode': 'Master'}));
      when(mockRepo.transaction(
        any,
        fetchRemote: anyNamed('fetchRemote'),
        cacheLevel: anyNamed('cacheLevel'),
        timeoutMs: anyNamed('timeoutMs'),
        retries: anyNamed('retries'),
        sideEffectOverrides: anyNamed('sideEffectOverrides'),
      )).thenAnswer((invocation) async {
        transactions.add(
            invocation.positionalArguments.first as JNAPTransactionBuilder);
        return JNAPTransactionSuccessWrap(result: 'OK', data: const []);
      });

      await pumpRootContainer(tester, overrides: [
        routerRepositoryProvider.overrideWithValue(mockRepo),
        dashboardManagerProvider.overrideWith(
            () => _FakeDashboardManagerNotifier(routerIsBack: routerIsBack)),
        // The fan-out a successful poll does. Only this one runs with every
        // service unsupported, and the real one would send through the same mock.
        instantPrivacyProvider.overrideWith(() => MockInstantPrivacyNotifier()),
      ]);

      await reportUnreachable(tester);
      expect(alert, findsOneWidget,
          reason: 'the alert is what is recovered from');
    }

    testWidgets('a router that has come back takes the alert with it',
        (tester) async {
      await pumpAlert(tester, routerIsBack: true);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(alert, findsNothing);
      expect(container.read(routerUnreachableProvider), 0,
          reason: 'a report left standing puts the dialog straight back up');

      // Past the deliberate first-poll delay, to the poll itself.
      await tester.pump(const Duration(seconds: pollFirstDelayInSec + 1));
      expect(transactions, isNotEmpty,
          reason: 'the dashboard must be being fed again');

      container.read(pollingProvider.notifier).stopPolling();
    });

    testWidgets('a router that is still away leaves the alert up',
        (tester) async {
      // Try again is the operator asking; it is not the operator being right. A
      // check that fails has to leave the alert exactly as it was, because there
      // is nothing behind it worth showing yet.
      await pumpAlert(tester, routerIsBack: false);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(alert, findsOneWidget);
      expect(container.read(routerUnreachableProvider), greaterThan(0));
      expect(transactions, isEmpty,
          reason: 'and polling must not have resumed');

      await closeAlert(tester);
    });
  });
}
