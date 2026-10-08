import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/active_ipv4_connection.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/auto_ipoe_section.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/services/auto_ipoe_service.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_isp_settings_view.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../mocks/provider_overrides/mock_common.dart';
import 'providers/usp_internet_ipoe_test.dart' show IPoEFixture;
import 'views/sections/usp_ipv4_ipoe_test.dart' show host;

class _Client extends Mock implements UspClient {}

Iterable<String?> _names(RouteBase route) sync* {
  if (route is GoRoute) yield route.name;
  for (final child in route.routes) {
    yield* _names(child);
  }
}

void main() {
  test('IPoE is integrated into Internet Settings with a guarded PnP route',
      () {
    expect(_names(pnpNoInternetRoute), contains(RouteNamed.pnpAutoIPoE));
    expect(_names(uspDashboardRoute), isNot(contains('uspAutoIPoE')));
    expect(
        _names(pnpNoInternetRoute),
        containsAll([
          RouteNamed.pnpPPPOE,
          RouteNamed.pnpStaticIp,
        ]));
  });

  for (final supported in [false, true]) {
    testWidgets('PnP deep link follows device capability: $supported',
        (tester) async {
      final ipoeRoute = pnpNoInternetRoute.routes
          .singleWhere((route) =>
              route is GoRoute && route.name == RouteNamed.pnpIspTypeSelection)
          .routes
          .whereType<GoRoute>()
          .singleWhere((route) => route.name == RouteNamed.pnpAutoIPoE);
      late BuildContext routeContext;
      late GoRouterState routeState;
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (context, state) {
              routeContext = context;
              routeState = state;
              return const SizedBox.shrink();
            }),
        pnpNoInternetRoute,
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          deviceCapabilitiesProvider.overrideWithValue(supported
              ? DeviceCapabilities({DeviceCapability.autoIPoE})
              : DeviceCapabilities.empty),
          autoIPoEServiceProvider.overrideWith(
              (_) => throw StateError('route must not initialize the service')),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();
      expect(
          await ipoeRoute.redirect!(routeContext, routeState),
          supported
              ? null
              : router.namedLocation(RouteNamed.pnpIspTypeSelection));
      if (!supported)
        expect(await ipoeRoute.onExit!(routeContext, routeState), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  group('Device without Auto-IPoE', () {
    setUpAll(() {
      registerFallbackValue(const AutoIPoESubmission('fixture', reset: false));
      registerFallbackValue(const AutoIPoESettings.init());
      registerFallbackValue(const UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp));
    });

    test(
        'service composition rejects unsupported devices before client initialization',
        () {
      final container = ProviderContainer(overrides: [
        deviceCapabilitiesProvider.overrideWithValue(DeviceCapabilities.empty),
        uspClientProvider
            .overrideWith((_) => throw StateError('must not initialize USP')),
      ]);
      addTearDown(container.dispose);
      expect(() => container.read(autoIPoEServiceProvider),
          throwsA(isA<ResourceNotFoundError>()));
    });

    testWidgets('a previous IPoE draft cannot stay editable without capability',
        (tester) async {
      final fixture = IPoEFixture(supported: false);
      addTearDown(fixture.dispose);
      await fixture.ready();
      fixture.notifier.updateConnectionType(UspWanConnectionType.ipoe);
      await tester.pumpWidget(host(fixture));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) => w is AppDropdown<UspWanConnectionType>),
          findsNothing);
      expect(
          tester
              .widget<AutoIPoESection>(find.byType(AutoIPoESection))
              .isEditing,
          isFalse);
      verifyZeroInteractions(fixture.ipoe);
      expect(fixture.calls, isEmpty);
      expect(tester.takeException(), isNull);
    });

    test('service rejects reads, writes and recovery before using USP or login',
        () async {
      final client = _Client();
      var sessionRequests = 0;
      final service = AutoIPoEService(client,
          isAvailable: () => false,
          ensureSession: () async {
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
      expect(await ActiveIpv4Connection.fetch(client, autoIPoESupported: false),
          isNull);
      verifyZeroInteractions(client);
    });

    testWidgets('provider never opens service or resumes polling when disabled',
        (tester) async {
      final container = ProviderContainer(overrides: [
        deviceCapabilitiesProvider.overrideWithValue(DeviceCapabilities.empty),
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
          deviceCapabilitiesProvider
              .overrideWithValue(DeviceCapabilities.empty),
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
      final fixture = IPoEFixture(supported: false);
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
  });
}
