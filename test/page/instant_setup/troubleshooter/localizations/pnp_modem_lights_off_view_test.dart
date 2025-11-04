import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_modem_lights_off_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../common/di.dart';
import '../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    when(mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo: PnpDeviceInfoUIModel(
          modelName: 'LN16',
          image: 'routerLn16',
          serialNumber: 'serialNumber',
          firmwareVersion: 'firmwareVersion',
        ),
        isUnconfigured: true));
    when(mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
  });

  testLocalizations('Troubleshooter - PnP modem lights off',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpModemLightsOffView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - PnP modem lights off: show tips',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpModemLightsOffView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
    final tipFinder = find.byType(TextButton);
    await tester.tap(tipFinder);
    await tester.pumpAndSettle();
  });
}
