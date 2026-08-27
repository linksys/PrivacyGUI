import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/apps/models/app_info_ui_model.dart';
import 'package:privacy_gui/page/apps/providers/usp_apps_notifier.dart';
import 'package:privacy_gui/page/apps/views/usp_apps_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../mocks/provider_overrides/mock_common.dart';

/// Verifies the E2E identifier hooks added to uspApps for PrivacyGUI#1391
/// (unblocks PrivacyGUI-USP-E2E#88): the arrival anchor, the store + retry
/// controls, and per-app cards keyed by a STABLE name slug (never the grid
/// index).
///
/// Not tagged `ui`: gated in `run_tests.sh` (the repo's only CI test job).
class _FixedAppsNotifier extends UspAppsNotifier {
  _FixedAppsNotifier(this._state);
  final UspAppsState _state;
  @override
  Future<UspAppsState> build() async => _state;
}

class _ErrorAppsNotifier extends UspAppsNotifier {
  @override
  Future<UspAppsState> build() async => throw Exception('boom');
}

void main() {
  const twoApps = [
    AppInfoUIModel(
      name: 'Media Server',
      description: 'Stream media',
      link: 'http://media.local',
      version: '1.0',
      iconData: Icons.play_circle,
      color: Colors.blue,
      category: AppCategory.system,
    ),
    AppInfoUIModel(
      name: 'File Share',
      description: 'Share files',
      link: 'http://files.local',
      version: '2.0',
      iconData: Icons.folder,
      color: Colors.green,
      category: AppCategory.user,
    ),
  ];

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

  Widget wrap(List<Override> appsOverride) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const UspAppsView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [...commonOverrides(), ...appsOverride],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  group('uspApps identifiers', () {
    testWidgets('anchor + store + per-app cards carry stable name-slug keys',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap([
        uspAppsProvider.overrideWith(
            () => _FixedAppsNotifier(const UspAppsState(apps: twoApps))),
      ]));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('apps-page'), findsOneWidget,
          reason: 'the arrival anchor must be locatable');
      expect(find.bySemanticsIdentifier('apps-store'), findsOneWidget);

      final matched = <Element>{};
      for (final id in const [
        'apps-open-media-server',
        'apps-open-file-share'
      ]) {
        final finder = find.bySemanticsIdentifier(id);
        expect(finder, findsOneWidget,
            reason: 'app card "$id" must resolve to exactly one node');
        matched.add(finder.evaluate().single);
      }
      expect(matched, hasLength(2),
          reason: 'app cards must target distinct widgets by name slug');

      handle.dispose();
    });

    testWidgets('the retry control is hooked in the error state',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap([
        uspAppsProvider.overrideWith(() => _ErrorAppsNotifier()),
      ]));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('apps-retry'), findsOneWidget,
          reason: 'the retry control must be locatable when apps fail to load');

      handle.dispose();
    });
  });
}
