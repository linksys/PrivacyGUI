import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';

import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/device_manager_notifier_mocks.dart';
import '../../../../mocks/jnap_service_supported_mocks.dart';
import '../../../../test_data/device_filter_config_test_state.dart';
import '../../../../test_data/device_filtered_list_test_data.dart';
import '../../../../test_data/device_manager_test_state.dart';
import '../../../../mocks/device_filter_config_notifier_mocks.dart';

void main() {
  late DeviceFilterConfigNotifier mockDeviceFilterConfigNotifier;
  late DeviceManagerNotifier mockDeviceManagerNotifier;
  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    mockDeviceFilterConfigNotifier = MockDeviceFilterConfigNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerTestData));
    when(mockServiceHelper.isSupportClientDeauth())
        .thenReturn(true);
  });

  testLocalizations('Instant device view', (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        deviceFilterConfigProvider
            .overrideWith(() => mockDeviceFilterConfigNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
            .map((e) => DeviceListItem.fromMap(e))
            .toList())
      ],
      locale: locale,
      child: const InstantDeviceView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('Instant device view - offline devices',
      (tester, locale) async {
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(connectionFilter: false));
    final widget = testableSingleRoute(
      overrides: [
        deviceFilterConfigProvider
            .overrideWith(() => mockDeviceFilterConfigNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        filteredDeviceListProvider.overrideWith((ref) =>
            deviceFilteredOfflineTestData
                .map((e) => DeviceListItem.fromMap(e))
                .toList())
      ],
      locale: locale,
      child: const InstantDeviceView(),
    );
    await tester.pumpWidget(widget);
  });
}
