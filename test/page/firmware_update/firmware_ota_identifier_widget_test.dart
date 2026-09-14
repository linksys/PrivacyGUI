import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_ota_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../golden_test/golden_framework/mocks/mock_firmware_update.dart';
import '../../golden_test/page/firmware_update/fixtures/firmware_update_test_data.dart';
import '../../mocks/provider_overrides/mock_common.dart';

/// Verifies the E2E identifier hooks on uspFirmwareOta, added by #1549.
///
/// Copied from `firmware_update_identifier_widget_test.dart` on purpose: the two
/// pages are two halves of one install, and the halves that differ are easier to
/// see when everything else reads identically. What differs is which controls
/// each page owns —
///
///   - this page owns `firmware-check`, the cloud check, which #1549 moved off
///     the manual page (asserted absent there), and `firmware-phase-checkingOta`,
///     the only phase anchor the manual page can never emit;
///   - the manual page owns `firmware-pick-file`, `firmware-install-confirm` and
///     `firmware-upload-cancel`, which are asserted absent here — each pumped in
///     the phase that renders it over there, or the absence proves nothing;
///   - the six install-phase anchors (`firmware-phase-*`) are SHARED, because
///     both pages render the same [FirmwareInstallPhaseCard]. That card
///     deliberately carries no `Semantics` boundary of its own, so the anchor is
///     emitted once per frame by whichever page is mounted. This file pumping
///     the same anchors as its sibling is the evidence that stayed true.
///
/// Not tagged `ui`: gated in `run_tests.sh` (the repo's only CI test job).
void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'PrivacyGUI',
            'packageName': 'com.linksys.privacygui',
            'version': '0.0.0',
            'buildNumber': '0',
          };
        }
        return null;
      },
    );
  });

  Widget wrapState(FirmwareUpdateState state) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const FirmwareOtaView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...firmwareUpdateOverrides(
          updateState: state,
          banksData: testBanksData,
          systemInfoData: testSystemInfoData,
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester, FirmwareUpdateState state) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapState(state));
    // Pump frames rather than settle: several phases animate an indeterminate
    // loader, which never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('uspFirmwareOta identifiers', () {
    testWidgets('the page anchor and the cloud check are hooked in idle',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester, idleNoFileState);

      for (final id in const ['firmware-ota', 'firmware-check']) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget,
            reason: 'firmware control "$id" must be locatable');
      }

      handle.dispose();
    });

    // THE SAME CONTROL, STILL THERE, WHILE IT IS WORKING.
    //
    // `firmware-check` used to be published by only one of two buttons chosen on
    // `isChecking`: the busy copy carried no `identifier`, so the hook left the
    // tree for exactly the span an E2E spec spends waiting on the operation it
    // just started. The test above could not see that — it pumps `idle`, which is
    // the state that did publish it. Pinning the id in the busy phase is what
    // makes the absence impossible to reintroduce.
    //
    // `enabled: false` is asserted alongside it because "still locatable" is only
    // half the requirement: a hook that stays clickable while the check runs lets
    // a spec fire a second check into the first one's response.
    testWidgets('the cloud check stays hooked, and disabled, while checking',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester, checkingOtaState);

      final finder = find.bySemanticsIdentifier('firmware-check');
      expect(finder, findsOneWidget,
          reason: '"firmware-check" must stay locatable while the check is in '
              'flight — a spec that clicks it then waits on its busy state has '
              'nothing to wait on otherwise');

      expect(tester.getSemantics(finder),
          isSemantics(hasEnabledState: true, isEnabled: false),
          reason: 'the check must not be re-triggerable while one is running. '
              '`hasEnabledState` is asserted too, because `isEnabled: false` on '
              'a node that carries no enabled state at all is a pass that means '
              'nothing');

      handle.dispose();
    });

    // The mirror of the absence asserted on the manual page. Both directions are
    // pinned because the E2E harvest reads Dart source as text: a control that
    // reappears on the wrong page is silent there, and only a failing
    // expectation says which page owns it.
    //
    // ONE TEST PER PHASE THAT COULD HOST THE CONTROL. An absence assertion is
    // only worth the line it is on if the control would be present were the bug
    // real, and these three live in different phases on the manual page:
    // `firmware-pick-file` and `firmware-install-confirm` in `idle`,
    // `firmware-upload-cancel` in `uploading`. Asserting all three against one
    // idle pump passed for the cancel button by accident — no page renders it in
    // `idle`, so that expectation would have stayed green with the whole upload
    // panel copied onto this page.
    testWidgets('the file-picking controls are not on this page',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester, idleFileSelectedState);

      for (final id in const [
        'firmware-pick-file',
        'firmware-install-confirm',
      ]) {
        expect(find.bySemanticsIdentifier(id), findsNothing,
            reason:
                '"$id" belongs to the manual page — this page installs what '
                'the cloud offers, so it never picks a file. Pumped with a file '
                'selected, the state that renders both on that page');
      }

      handle.dispose();
    });

    testWidgets('the upload cancel control is not on this page',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester, uploadingState);

      expect(find.bySemanticsIdentifier('firmware-upload-cancel'), findsNothing,
          reason: '"firmware-upload-cancel" cancels a chunked browser upload, '
              'which this page never starts. Pumped in `uploading` — the phase '
              'that renders it on the manual page — so this measures absence '
              'rather than the phase being wrong');

      handle.dispose();
    });

    // Phase anchors. One test per phase so the widget binding starts clean —
    // re-pumping a fresh tree into one test after an animating phase does not
    // reliably rebuild the semantics subtree.
    //
    // FOUND *AND* NON-EMPTY. `findsOneWidget` on its own is satisfied by a 0x0
    // node, and this anchor was one for two of the eleven phases: it started life
    // wrapped around the install card's slot, which is null in `idle` and
    // `checkingOta`, so the boundary existed with nothing inside it. Playwright
    // waits on a visible element, so a zero-size anchor is the same as a missing
    // one to the only consumer that reads it — and `findsOneWidget` cannot tell
    // the two apart. The rect is read off the semantics node rather than the
    // widget because that is the object the driver resolves.
    Future<void> runPhaseTest(
        WidgetTester tester, FirmwareUpdateState state, String anchor) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester, state);

      final finder = find.bySemanticsIdentifier(anchor);
      expect(finder, findsOneWidget,
          reason: 'phase anchor "$anchor" must be locatable');

      final rect = tester.getSemantics(finder).rect;
      expect(rect.width, greaterThan(0),
          reason: 'phase anchor "$anchor" must enclose something a driver can '
              'wait on, not a zero-width boundary');
      expect(rect.height, greaterThan(0),
          reason: 'phase anchor "$anchor" must enclose something a driver can '
              'wait on, not a zero-height boundary');

      handle.dispose();
    }

    // The two phases whose anchor has no install card inside it. They are the
    // reason the size assertion above exists, so they are pinned first.
    testWidgets('the idle phase is anchored, with an extent', (tester) async {
      await runPhaseTest(tester, idleNoFileState, 'firmware-phase-idle');
    });

    testWidgets('the checking phase is anchored, with an extent',
        (tester) async {
      await runPhaseTest(
          tester, checkingOtaState, 'firmware-phase-checkingOta');
    });

    testWidgets('the installing phase card is anchored', (tester) async {
      await runPhaseTest(tester, installingState, 'firmware-phase-installing');
    });

    testWidgets('the rebooting phase card is anchored', (tester) async {
      await runPhaseTest(tester, rebootingState, 'firmware-phase-rebooting');
    });

    testWidgets('the done phase card is anchored (success verdict)',
        (tester) async {
      // The whole-flow verdict must be structurally distinguishable from
      // `failed` rather than only by which localized sentence appears.
      await runPhaseTest(tester, doneState, 'firmware-phase-done');
    });

    testWidgets('the failed phase card is anchored (failure verdict)',
        (tester) async {
      await runPhaseTest(tester, failedState, 'firmware-phase-failed');
    });

    testWidgets('the retry control is hooked on failure', (tester) async {
      // `firmware-retry` is the only exit from `failed` on this page, and it is
      // rendered by the shared phase card — so it has to be reachable from both
      // pages, not just the one it was written on.
      final handle = tester.ensureSemantics();
      await pumpPage(tester, failedState);

      expect(find.bySemanticsIdentifier('firmware-retry'), findsOneWidget,
          reason: 'the retry button must be locatable by id');

      handle.dispose();
    });
  });
}
