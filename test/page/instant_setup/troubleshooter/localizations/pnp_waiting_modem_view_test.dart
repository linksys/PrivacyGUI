import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_waiting_modem_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../common/di.dart';
import '../../../../test_data/device_info_test_data.dart';
import '../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    when(mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: true));
    when(mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
  });

  testLocalizations('Troubleshooter - PnP waiting modem: counting',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpWaitingModemView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testLocalizations(
      'Troubleshooter - PnP waiting modem: plug your modem back in',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpWaitingModemView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
  });
  testLocalizations('Troubleshooter - PnP waiting modem: wait to start up',
      (tester, locale) async {
    final router = testableRouter(
      router: GoRouter(routes: [
        LinksysRoute(
            path: '/',
            builder: (context, state) => const PnpWaitingModemView()),
        pnpTroubleshootingRoute,
        pnpRoute,
      ], initialLocation: '/'),
      locale: locale,
      overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
    );
    await tester.pumpWidget(router);
    await tester.pumpAndSettle();
    final btnFinder = find.byType(AppFilledButton);
    await tester.tap(btnFinder);
    await tester.pump(const Duration(seconds: 3));
  });

  testLocalizations('Troubleshooter - PnP waiting modem: checking for internet',
      (tester, locale) async {
    final router = testableRouter(
      router: GoRouter(routes: [
        LinksysRoute(
            path: '/',
            builder: (context, state) => const PnpWaitingModemView()),
        pnpTroubleshootingRoute,
        pnpRoute,
      ], initialLocation: '/'),
      locale: locale,
      overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
    );
    await tester.pumpWidget(router);
    await tester.pumpAndSettle();
    final btnFinder = find.byType(AppFilledButton);
    await tester.tap(btnFinder);
    await tester.pump(const Duration(seconds: 5));
  });
}
