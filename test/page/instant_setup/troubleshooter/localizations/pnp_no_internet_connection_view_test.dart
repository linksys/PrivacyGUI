import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../common/di.dart';
import '../../../../test_data/device_info_test_data.dart';
import '../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';

import '../../../../mocks/pnp_troubleshooter_notifier_mocks.dart';

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;
  late MockPnpTroubleshooterNotifier mockPnpTroubleshooterNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    mockPnpTroubleshooterNotifier = MockPnpTroubleshooterNotifier();

    when(mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: true));
    when(mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
  });

  testLocalizations('Troubleshooter - PnP no internet connection: no SSID',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpNoInternetConnectionView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - PnP no internet connection: has SSID',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpNoInternetConnectionView(
          args: {'ssid': 'AwesomeSSID'},
        ),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'Troubleshooter - PnP no internet connection: has SSID and need help',
      (tester, locale) async {
    when(mockPnpTroubleshooterNotifier.build())
        .thenReturn(PnpTroubleshooterState(hasResetModem: true));
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpNoInternetConnectionView(
          args: {'ssid': 'AwesomeSSID'},
        ),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [
          pnpProvider.overrideWith(() => mockPnpNotifier),
          pnpTroubleshooterProvider
              .overrideWith(() => mockPnpTroubleshooterNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
}
