import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/active_ipv4_connection.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/services/auto_ipoe_service.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_isp_settings_view.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../mocks/provider_overrides/mock_common.dart';
import '../internet_settings/providers/usp_internet_ipoe_test.dart'
    show IPoEFixture;
import '../internet_settings/views/sections/usp_ipv4_ipoe_test.dart' show host;

class _Client extends Mock implements UspClient {}

Iterable<String?> _names(RouteBase route) sync* {
  if (route is GoRoute) yield route.name;
  for (final child in route.routes) {
    yield* _names(child);
  }
}

void main() {
  test('IPoE routes follow the build option in both setup and settings', () {
    expect(_names(pnpNoInternetRoute).contains(RouteNamed.pnpAutoIPoE),
        BuildConfig.autoIPoEEnabled);
    expect(_names(uspDashboardRoute).contains(RouteNamed.uspAutoIPoE),
        BuildConfig.autoIPoEEnabled);
    expect(
        _names(pnpNoInternetRoute),
        containsAll([
          RouteNamed.pnpPPPOE,
          RouteNamed.pnpStaticIp,
        ]));
  });

  group('Auto-IPoE disabled build', () {
    setUpAll(() {
      registerFallbackValue(const AutoIPoESubmission('fixture', reset: false));
      registerFallbackValue(const AutoIPoESettings.init());
      registerFallbackValue(const UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp));
    });

    test('service rejects reads, writes and recovery before using USP or login',
        () async {
      final client = _Client();
      var sessionRequests = 0;
      final service = AutoIPoEService(client, ensureSession: () async {
        sessionRequests++;
      });
      const apply = AutoIPoESubmission('apply', reset: false);
      const reset = AutoIPoESubmission('reset', reset: true);
      for (final call in <Future<dynamic> Function()>[
        service.fetch,
        () => service.submit(apply, settings: const AutoIPoESettings.init()),
        () => service.submit(reset),
        () => service.resolvePending(apply),
        service.loadSubmission,
        () => service.storeSubmission(apply),
        service.clearSubmission,
      ]) {
        await expectLater(call(), throwsA(isA<ResourceNotFoundError>()));
      }
      expect(sessionRequests, 0);
      verifyZeroInteractions(client);
    });

    test('shared WAN and diagnostics do not query the Auto-IPoE connection',
        () async {
      final client = _Client();
      expect(await ActiveIpv4Connection.fetch(client), isNull);
      verifyZeroInteractions(client);
    });

    testWidgets('provider never opens service or resumes polling when disabled',
        (tester) async {
      final container = ProviderContainer(overrides: [
        autoIPoEServiceProvider.overrideWith(
            (_) => throw StateError('disabled service must not be opened')),
      ]);
      addTearDown(container.dispose);
      final snapshot = await container.read(autoIPoEDataProvider.future);
      expect(snapshot.capabilities.isSupported, isFalse);
      final notifier = container.read(autoIPoEDataProvider.notifier);
      expect(await notifier.refresh(), isNull);
      notifier.continueChecking();
      await expectLater(notifier.apply(const AutoIPoESettings.init()),
          throwsA(isA<ResourceNotFoundError>()));
      await expectLater(
          notifier.reset(), throwsA(isA<ResourceNotFoundError>()));
      await expectLater(
          notifier.resolvePending(), throwsA(isA<ResourceNotFoundError>()));
      await tester.pump(const Duration(seconds: 20));
      expect(container.read(autoIPoESubmissionProvider), isNull);
      expect(container.read(autoIPoEDataProvider).requireValue, snapshot);
    });

    testWidgets('PnP retains DHCP and PPPoE without showing IPoE',
        (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const PnpIspSettingsView()),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...commonOverrides(),
          autoIPoEServiceProvider.overrideWith(
              (_) => throw StateError('disabled service must not be opened')),
        ],
        child: MaterialApp.router(
          theme: AppTheme.create(brightness: Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(AppLoader), findsNothing);
      expect(find.text('DHCP'), findsOneWidget);
      expect(find.text('PPPoE'), findsOneWidget);
      expect(find.text('IPoE'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Internet Settings retains ordinary WAN choices without IPoE',
        (tester) async {
      final fixture = IPoEFixture();
      addTearDown(fixture.dispose);
      await fixture.ready();
      await tester.pumpWidget(host(fixture));
      await tester.pumpAndSettle();
      final selector = find.byWidgetPredicate((widget) =>
          widget is AppDropdown<UspWanConnectionType> &&
          widget.identifier == 'internet-connection-type');
      final dropdown =
          tester.widget<AppDropdown<UspWanConnectionType>>(selector);
      expect(
          dropdown.items,
          containsAll([
            UspWanConnectionType.dhcp,
            UspWanConnectionType.pppoe,
          ]));
      expect(dropdown.items, isNot(contains(UspWanConnectionType.ipoe)));
      verifyZeroInteractions(fixture.ipoe);
      expect(fixture.calls, isEmpty);
    });
  }, skip: BuildConfig.autoIPoEEnabled);
}
