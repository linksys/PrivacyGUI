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
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/device_info_test_data.dart';
import '../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;

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

  testLocalizations('pnp waiting modem view - counting',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpWaitingModemView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testLocalizations('pnp waiting modem view - plug your modem back in',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpWaitingModemView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
  });
  testLocalizations('pnp waiting modem view - waiting modem to start up',
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

  testLocalizations('pnp waiting modem view - checking for internet',
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
