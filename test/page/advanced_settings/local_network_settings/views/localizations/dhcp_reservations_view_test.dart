import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/local_network_settings_state.dart';
import '../../local_network_settings_view_test_mocks.dart';

@GenerateNiceMocks([MockSpec<LocalNetworkSettingsNotifier>()])
void main() {
  late MockLocalNetworkSettingsNotifier mockLocalNetworkSettingsNotifier;

  setUp(() {
    mockLocalNetworkSettingsNotifier = MockLocalNetworkSettingsNotifier();
  });

  testLocalizations('DHCP reservations view test - Overview',
      (tester, locale) async {
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mocklocalNetworkSettingsState));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
      ],
      locale: locale,
      child: const DHCPReservationsView(),
    );
    await tester.pumpWidget(widget);
  });
}
