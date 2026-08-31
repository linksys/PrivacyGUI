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
// The harness drives [pollingFailureCountProvider] directly rather than through
// PollingNotifier: what the poll does with a failure is settled in
// polling_provider_test.dart, and what is under test here is only the decision to
// put the alert on screen - the route exemption, the login guard, and the promise
// that instances never stack.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/components/layouts/root_container.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

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

void main() {
  mockDependencyRegister();

  late ProviderContainer container;

  /// The alert, found by its localized title.
  final alert = find.text('Router Not Found');

  Future<void> pumpRootContainer(
    WidgetTester tester, {
    LoginType loginType = LoginType.local,
    LinksysRouteConfig? config,
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
    ]);
    addTearDown(container.dispose);
    // The login guard reads authProvider synchronously, and an AsyncNotifier
    // nobody has read yet is still loading. Settle it here so these tests are
    // about the route and the failure count rather than about start-up timing.
    await container.read(authProvider.future);

    await tester.pumpWidget(testableSingleRoute(
      provider: container,
      locale: const Locale('en'),
      child: AppRootContainer(
        route: LinksysRoute(
          name: 'test',
          path: '/',
          config: config,
          builder: (context, state) => const SizedBox.shrink(),
        ),
        child: const Text('dashboard'),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Leaves polling in the state a router that has stopped answering leaves it
  /// in, [failures] polls into the streak.
  Future<void> failPolls(WidgetTester tester, int failures) async {
    container.read(pollingFailureCountProvider.notifier).state = failures;
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

  testWidgets('a router that stops answering raises the alert', (tester) async {
    await pumpRootContainer(tester);
    expect(alert, findsNothing);

    await failPolls(tester, pollFailuresBeforeUnreachable);

    expect(alert, findsOneWidget);

    await closeAlert(tester);
  });

  testWidgets('a single failed poll raises nothing', (tester) async {
    // The dashboard is only worth interrupting once the router has really gone:
    // one lost poll is what an HTTP-service restart looks like from here, and the
    // re-try that follows it usually answers.
    await pumpRootContainer(tester);

    await failPolls(tester, 1);

    expect(alert, findsNothing);
  });

  testWidgets('a route that raises the alert itself gets no second one',
      (tester) async {
    // Firmware update is the case: it takes the router away for minutes, says so
    // itself, and must not have a second alert pushed in from behind over its
    // progress screen.
    await pumpRootContainer(tester,
        config: const LinksysRouteConfig(ignoreConnectivityEvent: true));

    await failPolls(tester, pollFailuresBeforeUnreachable);

    expect(alert, findsNothing);
  });

  testWidgets('the alert never stacks', (tester) async {
    // Ticks keep failing every interval while the router is away, and each one
    // raises the count again. The alert is blocking and cannot be dismissed, so a
    // second copy would have to be worked through one tap at a time.
    await pumpRootContainer(tester);

    await failPolls(tester, pollFailuresBeforeUnreachable);
    await failPolls(tester, pollFailuresBeforeUnreachable + 1);
    await failPolls(tester, pollFailuresBeforeUnreachable + 2);

    expect(alert, findsOneWidget);

    await closeAlert(tester);
  });

  testWidgets('the alert can be raised again once it has been closed',
      (tester) async {
    // The flip side of never stacking: the guard must be released when the alert
    // goes, or the router could only ever be reported unreachable once per
    // session.
    await pumpRootContainer(tester);

    await failPolls(tester, pollFailuresBeforeUnreachable);
    await closeAlert(tester);
    expect(alert, findsNothing);

    await failPolls(tester, 0);
    await failPolls(tester, pollFailuresBeforeUnreachable);

    expect(alert, findsOneWidget);

    await closeAlert(tester);
  });

  testWidgets('nothing is raised before anybody is logged in', (tester) async {
    // Polling is not running for the user's benefit yet, and the login page has
    // no stale dashboard to correct.
    await pumpRootContainer(tester, loginType: LoginType.none);

    await failPolls(tester, pollFailuresBeforeUnreachable);

    expect(alert, findsNothing);
  });
}
