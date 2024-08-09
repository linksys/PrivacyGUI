import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/pnp/data/pnp_exception.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart';

import 'package:privacy_gui/page/pnp/data/pnp_state.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../common/testable_router.dart';
import '../../../../../../test_data/device_info_test_data.dart';
import '../../../../../../test_data/internet_settings_state_data.dart';
import '../../../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import '../../../../../../mocks/internet_settings_notifier_mocks.dart';

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();

    when(mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: true));
    when(mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });

    final mockInternetSettingsState =
        InternetSettingsState.fromJson(internetSettingsStateData);
    when(mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
    when(mockInternetSettingsNotifier.fetch()).thenAnswer((_) async {
      return mockInternetSettingsState;
    });
  });

  testLocalizations('pnp isp type selection view - default',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpIspTypeSelectionView(),
        locale: locale,
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        overrides: [
          pnpProvider.overrideWith(() => mockPnpNotifier),
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('pnp isp type selection view - DHCP Alert',
      (tester, locale) async {
    final mockInternetSettingsState =
        InternetSettingsState.fromJson(internetSettingsStateData2);
    when(mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpIspTypeSelectionView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
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
