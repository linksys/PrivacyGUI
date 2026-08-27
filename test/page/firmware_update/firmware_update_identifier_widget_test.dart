import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
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

  Widget wrap({required bool withSelectedFile}) {
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
          updateState:
              withSelectedFile ? idleFileSelectedState : idleNoFileState,
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
  });
}
