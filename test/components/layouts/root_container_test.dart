/// Pins the idle-logout policy and the wiring that delivers it — PrivacyGUI#1454.
///
/// Deliberately NOT tagged `ui`: nothing here renders anything worth looking at.
/// It answers three questions that are otherwise unanswerable from inside the
/// tree, and all of them have already been asked in earnest.
///
/// **Is the window still what we decided?** [kIdleLogoutWindow] is a
/// security-relevant literal. Nothing else in the suite references it, so before
/// this file a silent revert to five minutes — or a fat-fingered `minutes: 150`
/// — broke no test.
///
/// **Which routes skip it?** [idleCheckWhiteList] exempts a route from the
/// logout, which makes it as security-relevant as the window. Its entries are the
/// add-nodes flow's entry points (#879, #1734): a BLE onboarding session can
/// outlast the window, and a logout mid-session leaves it running unwatched.
/// Dropping one broke no test before #1734, and adding one should be a decision,
/// so the list is pinned whole.
///
/// **Is the timer even connected?** `onIdle`'s first guard is `!kReleaseMode`,
/// so a debug build never logs out and the `Idled!` log sits *after* that guard.
/// From outside, "not wired up" and "wired up but suppressed in debug" therefore
/// look identical, and the second has been mistaken for the first. This asserts
/// the wiring directly instead of leaving it to inference.
///
/// What it does not cover: everything past that first guard. `kReleaseMode` is a
/// compile-time constant, so the login, dashboard, whitelist and pause checks —
/// and the `logout()` call itself — are unreachable from a test binding. Those
/// need a release build. The whitelist's *contents* are pinned; the check that
/// reads them is not.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/layouts/idle_checker.dart';
import 'package:privacy_gui/components/layouts/root_container.dart';
import 'package:privacy_gui/route/constants.dart';

void main() {
  test('the idle-logout window matches 1.x at 15 minutes', () {
    expect(kIdleLogoutWindow, const Duration(minutes: 15));
  });

  test('the idle logout skips both entries into the add-nodes flow, and only',
      () {
    expect(
      idleCheckWhiteList,
      unorderedEquals([RouteNamed.addNodes, RouteNamed.pnpAddNodes]),
      reason: 'the topology entry (#879) and the PnP Your Network entry '
          '(#1734); either one missing logs the user out mid-session',
    );
  });

  testWidgets('AppRootContainer arms an IdleChecker with that window',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AppRootContainer(child: SizedBox.expand()),
        ),
      ),
    );

    final finder = find.byType(IdleChecker);
    expect(finder, findsOneWidget,
        reason: 'no checker in the tree means no idle logout at all');

    final checker = tester.widget<IdleChecker>(finder);
    expect(checker.idleTime, kIdleLogoutWindow,
        reason: 'the checker must be handed the policy, not its own value');
    expect(checker.onIdle, isNotNull,
        reason: 'a checker with no onIdle counts down to nothing');
  });
}
