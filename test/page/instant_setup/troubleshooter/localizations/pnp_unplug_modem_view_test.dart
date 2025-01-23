import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_unplug_modem_view.dart';
import 'package:privacy_gui/route/route_model.dart';
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

  testLocalizations('Troubleshooter - PnP unplug modem',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpUnplugModemView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - PnP unplug modem: show tips',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpUnplugModemView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
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
