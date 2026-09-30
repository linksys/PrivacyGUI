// Baseline for VPN Settings' "Test Again" in the default build.
//
// With unsaved changes, Test Again offers to save them first and then saves
// through the page's own save path - not the Save bar - before running the
// test. A read-only build has to account for that path. These tests pin that in
// the default build an unchanged page tests straight away, and a changed page
// asks, saves when told to, and does neither when cancelled.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_state.dart';
import 'package:privacy_gui/page/vpn/views/vpn_settings_page.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/vpn_test_state.dart';

/// The real notifier with its network calls replaced by counters, so the page
/// runs against a live `state` that a test can move to make the page dirty.
class _CountingVPNNotifier extends VPNNotifier {
  int saves = 0;
  int tests = 0;

  @override
  VPNState build() => VPNTestState.defaultState;

  @override
  Future<VPNState> fetch([bool force = false, bool statusOnly = false]) async =>
      state;

  @override
  Future<VPNState> save() async {
    saves++;
    return state;
  }

  @override
  Future<VPNState> testVPNConnection() async {
    tests++;
    return VPNTestState.testResultState;
  }
}

void main() {
  late _CountingVPNNotifier vpn;

  mockDependencyRegister();
  final ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    vpn = _CountingVPNNotifier();
    when(mockServiceHelper.isSupportVPN()).thenReturn(true);
  });

  tearDown(() => reset(mockServiceHelper));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testableSingleRoute(
      overrides: [vpnProvider.overrideWith(() => vpn)],
      child: const VPNSettingsPage(),
    ));
    await tester.pumpAndSettle();
  }

  /// Makes the page dirty the way an edit does: the provider's settings move
  /// away from what the page preserved on load.
  Future<void> makeDirty(WidgetTester tester) async {
    vpn.state = VPNTestState.defaultState
        .copyWith(
            settings: VPNTestState.defaultState.settings
                .copyWith(tunneledUserIP: '10.0.0.99'));
    await tester.pumpAndSettle();
  }

  final testAgain = find.byKey(const ValueKey('testAgain'));

  testWidgets('an unchanged page tests without saving', (tester) async {
    await pump(tester);

    await tester.ensureVisible(testAgain);
    await tester.tap(testAgain);
    await tester.pumpAndSettle();

    expect(vpn.saves, 0);
    expect(vpn.tests, 1);
  });

  testWidgets('a changed page asks, saves, then tests', (tester) async {
    await pump(tester);
    await makeDirty(tester);

    await tester.ensureVisible(testAgain);
    await tester.tap(testAgain);
    await tester.pumpAndSettle();
    expect(find.text('You have unsaved changes on this page'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppTextButton, 'Save'));
    await tester.pumpAndSettle();
    // The save path confirms once more before writing.
    await tester.tap(find.widgetWithText(AppTextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(vpn.saves, 1);
    expect(vpn.tests, 1);
  });

  testWidgets('cancelling on a changed page does neither', (tester) async {
    await pump(tester);
    await makeDirty(tester);

    await tester.ensureVisible(testAgain);
    await tester.tap(testAgain);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppTextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(vpn.saves, 0);
    expect(vpn.tests, 0);
  });
}
