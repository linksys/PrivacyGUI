import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart';

import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../../common/di.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../common/testable_router.dart';
import '../../../../../../test_data/device_info_test_data.dart';
import '../../../../../../test_data/internet_settings_state_data.dart';
import '../../../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import '../../../../../../mocks/internet_settings_notifier_mocks.dart';

void main() async {
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  late Mock.MockPnpNotifier mockPnpNotifier;
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();

    // The card is gated on the advertised AutoIPoE service as well as on the
    // supported WAN types, and the fixture's services omit it. Every case here
    // gets the service so the screenshots turn on the WAN-type half alone.
    final deviceInfo =
        NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']);
    when(mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo: deviceInfo.copyWith(
            services: [...deviceInfo.services, JNAPService.autoIPoE.value]),
        isUnconfigured: true));
    when(mockServiceHelper.isSupportAutoIPoE(any)).thenAnswer((invocation) {
      final services =
          invocation.positionalArguments.first as List<String>? ?? const [];
      return services.contains(JNAPService.autoIPoE.value);
    });
    when(mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });

    final mockInternetSettingsState =
        InternetSettingsState.fromJson(internetSettingsStateData);
    when(mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
    when(mockInternetSettingsNotifier.fetch(fetchRemote: true))
        .thenAnswer((_) async {
      return mockInternetSettingsState;
    });
  });

  tearDown(() {
    reset(mockServiceHelper);
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

  // The list as a router that can actually do IPoE shows it. The default
  // screenshot above is a router whose supported WAN types omit IPoE, so the
  // card is gated out of it -- without this case no golden renders the card or
  // its description at all.
  testLocalizations('Troubleshooter - PnP ISP type selection: IPoE offered',
      (tester, locale) async {
    final ipoeCapable =
        InternetSettingsState.fromMap(internetSettingsStateIpoe);
    // Supports IPoE while currently on DHCP, so IPoE reads as an option rather
    // than as what is already applied.
    final mockInternetSettingsState = ipoeCapable.copyWith(
      ipv4Setting: ipoeCapable.ipv4Setting.copyWith(
        ipv4ConnectionType: WanType.dhcp.type,
      ),
    );
    when(mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
    when(mockInternetSettingsNotifier.fetch(fetchRemote: true))
        .thenAnswer((_) async => mockInternetSettingsState);
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
        InternetSettingsState.fromJson(internetSettingsStateData2);
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
