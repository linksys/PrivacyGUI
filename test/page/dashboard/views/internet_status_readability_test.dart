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
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../layout_gate/fully_shown.dart';
import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/gelocation_notifier_mocks.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../test_data/_index.dart';
import '../../../test_data/geolocation_test_state.dart';

// Constitution 3.4. The router's serial number and firmware version are
// useless when cut. Each is as long as it gets.
const _serial = '65G10M27E03041';
const _firmware = '1.1.19.215371';

void main() {
  late MockDashboardHomeNotifier mockDashboardHomeNotifier;
  late MockDashboardManagerNotifier mockDashboardManagerNotifier;
  late MockFirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;
  late MockInstantTopologyNotifier mockInstantTopologyNotifier;
  late MockGeolocationNotifier mockGeolocationNotifier;
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
        geolocationProvider.overrideWith(() => mockGeolocationNotifier),
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
    mockGeolocationNotifier = MockGeolocationNotifier();
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
    // The internet status shows the first node under the root.
    final InstantTopologyState topology =
        topologyTestData.testTopology2SlavesDaisyState;
    final master = topology.root.children.first;
    topology.root.children[0] = RouterTopologyNode(
      data: master.data.copyWith(serialNumber: _serial, fwVersion: _firmware),
      children: master.children,
    );
    when(mockInstantTopologyNotifier.build()).thenReturn(topology);
    when(mockGeolocationNotifier.build()).thenAnswer(
        (_) async => GeolocationState.fromMap(geolocationTestState));
    when(mockServiceHelper.isSupportLedMode()).thenReturn(true);
    when(mockPollingNotifier.build()).thenReturn(
        CoreTransactionData(lastUpdate: 0, isReady: true, data: const {}));
  });

  tearDown(() {
    topologyTestData.cleanup();
  });

  testFullyShown(
    'internet status',
    values: {
      'serial number': find.text(_serial),
      'firmware version': find.text(_firmware),
    },
    pump: (tester, locale) => tester.pumpWidget(testableRouteShellWidget(
      child: const DashboardHomeView(),
      locale: locale,
      overrides: overrides(),
    )),
  );
}
