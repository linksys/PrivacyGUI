import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/unified_diagnostics_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../golden_test/golden_framework/mocks/mock_unified_diagnostics.dart';
import '../../golden_test/page/unified_diagnostics/fixtures/unified_diagnostics_test_data.dart';
import '../../mocks/provider_overrides/mock_common.dart';

/// Verifies the E2E identifier hooks added to uspUnifiedDiagnostics for
/// PrivacyGUI#1391 (unblocks PrivacyGUI-USP-E2E#91). Before this card the only
/// hook was `diagnostic-result-close` — the exit — so a test could close a
/// panel it had no way to open. This adds what STARTS a diagnostic and the
/// result surface.
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

  Widget wrap(UnifiedDiagnosticsState state) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const UnifiedDiagnosticsView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...unifiedDiagnosticsOverrides(state),
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

  group('uspUnifiedDiagnostics identifiers', () {
    testWidgets('anchor + the controls that START a diagnostic are hooked',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(idleState));
      await tester.pumpAndSettle();

      for (final id in const [
        'unified-diagnostics',
        'diagnostic-run-full',
        'diagnostic-choose-issue',
        'diagnostic-manual-tools',
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget,
            reason: 'start-flow control "$id" must be locatable');
      }

      handle.dispose();
    });

    testWidgets('the result surface + its actions are hooked once results show',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(internetResultsState));
      await tester.pumpAndSettle();

      for (final id in const [
        'unified-diagnostics',
        'diagnostic-results',
        'diagnostic-run-again',
        'diagnostic-done',
        'diagnostic-export',
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget,
            reason: 'result-surface control "$id" must be locatable');
      }

      handle.dispose();
    });
  });
}
