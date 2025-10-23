import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_save_settings_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_pppoe_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';

import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../common/testable_router.dart';
import '../../../../../../common/di.dart';
import '../../../../../../test_data/device_info_test_data.dart';
import '../../../../../../test_data/internet_settings_state_data.dart';
import '../../../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import '../../../../../../mocks/internet_settings_notifier_mocks.dart';

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

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

  testLocalizations('Troubleshooter - PnP PPPoE: default',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpPPPOEView(),
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
  });

  testLocalizations('Troubleshooter - PnP PPPoE: with Remove VLAN ID',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpPPPOEView(),
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
    final addVLANFinder = find.byType(AppTextButton);
    await tester.tap(addVLANFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'Troubleshooter - PnP PPPoE: wrong account name or password',
      (tester, locale) async {
    final mockInternetSettingsState =
        InternetSettingsState.fromJson(internetSettingsStateData);
    final mockInternetSettings = mockInternetSettingsState.settings.current;
    final pppoeSetting = mockInternetSettings.ipv4Setting.copyWith(
      ipv4ConnectionType: WanType.pppoe.name,
    );
    when(mockInternetSettingsNotifier.build()).thenReturn(
        mockInternetSettingsState.copyWith(
            settings: Preservable(
                original: mockInternetSettings,
                current:
                    mockInternetSettings.copyWith(ipv4Setting: pppoeSetting))));
    when(mockInternetSettingsNotifier.savePnpIpv4(any)).thenAnswer((_) async {
      throw JNAPError(result: '', error: 'error');
    });
    final router = GoRouter(
      navigatorKey: shellNavigatorKey,
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          builder: (context, state) => const PnpPPPOEView(),
        ),
        LinksysRoute(
          path: '/$RoutePath.pnpIspSaveSettings',
          name: RouteNamed.pnpIspSaveSettings,
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          builder: (context, state) => PnpIspSaveSettingsView(
            args: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      testableRouter(
        router: router,
        locale: locale,
        overrides: [
          pnpProvider.overrideWith(() => mockPnpNotifier),
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier)
        ],
      ),
    );
    await tester.pumpAndSettle();
    //Tap next
    final nextFinder = find.byType(AppFilledButton);
    await tester.scrollUntilVisible(
      nextFinder,
      10,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();
  });
}
