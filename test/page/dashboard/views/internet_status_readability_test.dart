import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/screen.dart';
import '../../../common/theme_data.dart';
import '../../../layout_gate/fully_shown.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/gelocation_notifier_mocks.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../test_data/_index.dart';
import '../../../test_data/geolocation_test_state.dart';

// Constitution 3.4. The router's serial number and firmware version are
// useless when cut. They are the topology test data's master node, at the
// narrowest mobile and desktop page, in every locale. #1802 P4 measured at
// least 98px to spare on one line for each, so the guard was proven by
// capping the value at one line in a 60px box: every case went red.
const _serial = '65G10M27E03041';
const _firmware = '1.0.4.216421';

void main() {
  late MockDashboardHomeNotifier mockDashboardHomeNotifier;
  late MockDashboardManagerNotifier mockDashboardManagerNotifier;
  late MockFirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;
  late MockInstantTopologyNotifier mockInstantTopologyNotifier;
  late MockGeolocationNotifier mockGeolocationNotifer;
  late MockPollingNotifier mockPollingNotifier;
  late TopologyTestData topologyTestData;

  mockDependencyRegister();
  final mockServiceHelper = getIt.get<ServiceHelper>();

  List<Override> overrides() => [
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
        dashboardManagerProvider
            .overrideWith(() => mockDashboardManagerNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        internetStatusProvider.overrideWith((ref) => InternetStatus.online),
        instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
        instantTopologyProvider.overrideWith(() => mockInstantTopologyNotifier),
        geolocationProvider.overrideWith(() => mockGeolocationNotifer),
        pollingProvider.overrideWith(() => mockPollingNotifier),
      ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    topologyTestData = TopologyTestData();
    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    mockInstantTopologyNotifier = MockInstantTopologyNotifier();
    mockGeolocationNotifer = MockGeolocationNotifier();
    mockPollingNotifier = MockPollingNotifier();

    when(mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeCherry7TestState));
    when(mockDashboardManagerNotifier.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockInstantTopologyNotifier.build())
        .thenReturn(topologyTestData.testTopology2SlavesDaisyState);
    when(mockGeolocationNotifer.build()).thenAnswer(
        (_) async => GeolocationState.fromMap(geolocationTestState));
    when(mockServiceHelper.isSupportLedMode()).thenReturn(true);
    when(mockPollingNotifier.build()).thenReturn(
        CoreTransactionData(lastUpdate: 0, isReady: true, data: const {}));
  });

  tearDown(() {
    topologyTestData.cleanup();
  });

  for (final (name, value) in [
    ('serial number', find.text(_serial)),
    ('firmware version', find.text(_firmware)),
  ]) {
    for (final screen in const [
      ScreenSize('480', 480, 900, 1),
      ScreenSize('1241', 1241, 900, 1),
    ]) {
      for (final locale in AppLocalizations.supportedLocales) {
        testWidgets(
            'internet status shows the $name in full at ${screen.name} in '
            '${locale.toLanguageTag()}', (tester) async {
          await loadTestFonts();
          await tester.setScreenSize(screen);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(testableRouteShellWidget(
            child: const DashboardHomeView(),
            locale: locale,
            overrides: overrides(),
          ));
          await tester.pumpAndSettle();
          await tester.ensureVisible(value);
          await tester.pumpAndSettle();

          expect(value, isFullyShown);
        });
      }
    }
  }
}
