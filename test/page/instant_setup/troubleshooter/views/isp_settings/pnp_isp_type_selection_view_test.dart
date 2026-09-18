// Behavioural tests for the troubleshooter's ISP-type list.
//
// The IPoE card used to be emitted unconditionally, so a router whose firmware
// does not offer IPoE still advertised it here: firmware testing found that
// dropping `ipoe` from `linksys.network.wan_supported_conn_types` removed IPoE
// from Advanced Settings but left it in PnP, where tapping it leads to a page
// whose Apply can only fail. The card is now gated on the same supported-WAN-
// types list Advanced Settings filters on, and on the advertised AutoIPoE
// service. The two are independent: the supported-types list is UCI config the
// router module reads per request, while the service reflects whether the JNAP
// module is built in at all, so dropping ipoe from the config leaves the
// service advertised. These tests pin every combination that changes the
// answer.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/di.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../mocks/internet_settings_notifier_mocks.dart';
import '../../../../../mocks/pnp_notifier_mocks.dart' as Mock;
import '../../../../../test_data/device_info_test_data.dart';
import '../../../../../test_data/internet_settings_state_data.dart';

void main() {
  late Mock.MockPnpNotifier mockPnpNotifier;
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;

  mockDependencyRegister();
  final ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

  /// The view sits on a full-screen spinner until its own fetch answers, so
  /// every test has to stub the remote fetch as well as the built state.
  void stubInternetSettings(InternetSettingsState state) {
    when(mockInternetSettingsNotifier.build()).thenReturn(state);
    when(mockInternetSettingsNotifier.fetch(fetchRemote: true))
        .thenAnswer((_) async => state);
  }

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpIspTypeSelectionView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        overrides: [
          pnpProvider.overrideWith(() => mockPnpNotifier),
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The fixture's services do not include AutoIPoE, so the supported case has
  /// to add it. PnP hands the list to the support check itself, which is why it
  /// has to be right here rather than in the JNAP cache.
  void stubPnp({required bool advertisesAutoIPoE}) {
    final deviceInfo =
        NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']);
    when(mockPnpNotifier.build()).thenReturn(PnpState(
      deviceInfo: advertisesAutoIPoE
          ? deviceInfo.copyWith(
              services: [...deviceInfo.services, JNAPService.autoIPoE.value])
          : deviceInfo,
      isUnconfigured: true,
    ));
  }

  /// The registered ServiceHelper is a mock, so answer the way the real
  /// predicate does: from the list the caller passed. That way these tests fail
  /// if the view stops handing over PnP's own services.
  void stubServiceHelperFromArgument() {
    when(mockServiceHelper.isSupportAutoIPoE(any)).thenAnswer((invocation) {
      final services =
          invocation.positionalArguments.first as List<String>? ?? const [];
      return services.contains(JNAPService.autoIPoE.value);
    });
  }

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();
    stubPnp(advertisesAutoIPoE: true);
    stubServiceHelperFromArgument();
  });

  tearDown(() {
    reset(mockServiceHelper);
  });

  testWidgets(
      'hides the IPoE card when the router does not list IPoE '
      'among its supported WAN types', (tester) async {
    // This state's supportedIPv4ConnectionType is DHCP/Static/PPPoE/PPTP/L2TP/
    // Bridge -- the shape of a router without the AutoIPoE runtime.
    stubInternetSettings(
        InternetSettingsState.fromJson(internetSettingsStateData));

    await pumpView(tester);

    expect(find.text('IPoE'), findsNothing);
    // The list itself rendered, so the absence above is the gate and not a
    // page that failed to build. Counts are a floor rather than an equality
    // because the ListView builds lazily and the last card can sit off-screen.
    expect(find.byType(ISPTypeCard), findsAtLeastNWidgets(4));
  });

  testWidgets(
      'offers the IPoE card when the router lists IPoE among its '
      'supported WAN types', (tester) async {
    final ipoeCapable =
        InternetSettingsState.fromMap(internetSettingsStateIpoe);
    // Supports IPoE but is currently on DHCP, which is the state a user reaches
    // the troubleshooter in: IPoE is an option rather than what is applied.
    stubInternetSettings(ipoeCapable.copyWith(
      ipv4Setting: ipoeCapable.ipv4Setting.copyWith(
        ipv4ConnectionType: WanType.dhcp.type,
      ),
    ));

    await pumpView(tester);

    expect(find.text('IPoE'), findsOneWidget);
    expect(find.byType(ISPTypeCard), findsAtLeastNWidgets(4));
  });

  testWidgets(
      'hides the IPoE card when the router lists IPoE but does not advertise '
      'the AutoIPoE service', (tester) async {
    // The inverse mismatch: config offers IPoE, firmware has no AutoIPoE
    // module. Offering the card here leads to a page whose capabilities fetch
    // cannot succeed.
    stubPnp(advertisesAutoIPoE: false);
    final ipoeCapable =
        InternetSettingsState.fromMap(internetSettingsStateIpoe);
    stubInternetSettings(ipoeCapable.copyWith(
      ipv4Setting: ipoeCapable.ipv4Setting.copyWith(
        ipv4ConnectionType: WanType.dhcp.type,
      ),
    ));

    await pumpView(tester);

    expect(find.text('IPoE'), findsNothing);
    expect(find.byType(ISPTypeCard), findsAtLeastNWidgets(4));
  });
}
