import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../golden_test/golden_framework/mocks/mock_firmware_update.dart';
import '../../golden_test/page/firmware_update/fixtures/firmware_update_test_data.dart';
import '../../mocks/provider_overrides/mock_common.dart';

/// Verifies the E2E identifier hooks added to uspFirmwareUpdate for
/// PrivacyGUI#1391 (unblocks PrivacyGUI-USP-E2E#85). This is the highest-value
/// page: it has an `onExit` route guard that only manifests through real
/// navigation, so the check/pick/install controls must be addressable.
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
          builder: (context, state) => const FirmwareUpdateView(),
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

  Widget wrap({required bool withSelectedFile}) =>
      wrapState(withSelectedFile ? idleFileSelectedState : idleNoFileState);

  group('uspFirmwareUpdate identifiers', () {
    testWidgets('anchor + check + pick controls are hooked in idle',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(withSelectedFile: false));
      await tester.pumpAndSettle();

      for (final id in const [
        'firmware-update',
        'firmware-check',
        'firmware-pick-file'
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget,
            reason: 'firmware control "$id" must be locatable');
      }

      handle.dispose();
    });

    testWidgets('the install-confirm control appears once a file is selected',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(withSelectedFile: true));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('firmware-install-confirm'),
          findsOneWidget,
          reason: 'the install-confirm button must be hooked when a file is '
              'selected — it is what drives the guarded update');

      handle.dispose();
    });

    testWidgets('the uploading Cancel button is hooked (B1 — guard release)',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapState(uploadingState));
      // The uploading card shows an indeterminate linear loader, so
      // pumpAndSettle would never settle; a couple of frames is enough to
      // build the semantics tree.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Cancel is a click target — lint:ids Rules 1/2 forbid driving it by
      // localized text, so it must carry a stable identifier. It is the only
      // exit from `isUpdating`, i.e. the release side of the onExit guard.
      expect(
          find.bySemanticsIdentifier('firmware-upload-cancel'), findsOneWidget,
          reason: 'the uploading Cancel button must be locatable by id');

      handle.dispose();
    });

    testWidgets('each firmware bank row is anchored per instance (B2)',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapState(idleNoFileState));
      await tester.pumpAndSettle();

      // testBanksData renders bank instances 1 (Active) and 2 (Standby); each
      // row must be independently addressable so "slot N became Active" is
      // expressible rather than "the word Active appears somewhere".
      for (final instance in const [1, 2]) {
        expect(find.bySemanticsIdentifier('firmware-bank-$instance'),
            findsOneWidget,
            reason: 'bank row "firmware-bank-$instance" must be locatable');
      }

      handle.dispose();
    });

    // Phase anchors (B3). Each phase gets its own test so the widget binding
    // starts clean — re-pumping a fresh tree into one test after an animating
    // phase does not reliably rebuild the semantics subtree.
    Future<void> runPhaseTest(
        WidgetTester tester, FirmwareUpdateState state, String anchor) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapState(state));
      // uploading animates an indeterminate loader; done/failed are static.
      // Pump a couple of frames rather than settle so all phases work.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.bySemanticsIdentifier(anchor), findsOneWidget,
          reason: 'phase anchor "$anchor" must be locatable');

      handle.dispose();
    }

    testWidgets('the uploading phase card is anchored (B3)', (tester) async {
      await runPhaseTest(tester, uploadingState, 'firmware-phase-uploading');
    });

    testWidgets('the done phase card is anchored (B3 — success verdict)',
        (tester) async {
      // The whole-flow verdict must be structurally distinguishable from
      // `failed` rather than only by which localized sentence appears.
      await runPhaseTest(tester, doneState, 'firmware-phase-done');
    });

    testWidgets('the failed phase card is anchored (B3 — failure verdict)',
        (tester) async {
      await runPhaseTest(tester, failedState, 'firmware-phase-failed');
    });
  });
}
