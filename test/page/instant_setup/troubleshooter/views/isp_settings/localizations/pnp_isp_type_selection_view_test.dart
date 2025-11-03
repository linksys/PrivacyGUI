import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart';

import 'package:privacy_gui/route/route_model.dart';

import '../../../../../../common/di.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../common/testable_router.dart';
import '../../../../../../test_data/internet_settings_state_data.dart';
import '../../../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import '../../../../../../mocks/internet_settings_notifier_mocks.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';

void main() async {
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  late Mock.MockPnpNotifier mockPnpNotifier;
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();

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

    final mockInternetSettingsState =
        InternetSettingsState.fromMap(jsonDecode(internetSettingsStateData));
    when(mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
    when(mockInternetSettingsNotifier.fetch(forceRemote: true))
        .thenAnswer((_) async {
      return mockInternetSettingsState;
    });
  });

  testLocalizations('Troubleshooter - PnP ISP type selection: default',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpIspTypeSelectionView(),
        locale: locale,
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        overrides: [
          pnpProvider.overrideWith(() => mockPnpNotifier),
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Troubleshooter - PnP ISP type selection: DHCP Alert',
      (tester, locale) async {
    final mockInternetSettingsState =
        InternetSettingsState.fromMap(jsonDecode(internetSettingsStateData2));
    when(mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpIspTypeSelectionView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [
          pnpProvider.overrideWith(() => mockPnpNotifier),
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
    final dhcpFinder = find.byType(ISPTypeCard).first;
    await tester.tap(dhcpFinder);
    await tester.pumpAndSettle();
  });
}
