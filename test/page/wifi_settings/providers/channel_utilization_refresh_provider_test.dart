import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channel_utilization_refresh_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_data_service.dart';

import '../../../mocks/test_data/wifi_settings_test_data.dart';

class MockUspWifiDataService extends Mock implements UspWifiDataService {}

void main() {
  late MockUspWifiDataService mockService;

  setUpAll(() => registerFallbackValue(WifiCodegenContext.empty));

  setUp(() {
    mockService = MockUspWifiDataService();
    when(() => mockService.fetch()).thenAnswer(
        (_) async => WifiSettingsTestData.createWifiDataFetchResult());
    when(() => mockService.fetchUtilizationByRadioPath(any()))
        .thenAnswer((_) async => const {});
  });

  // #1295: the Channels tab's re-read of channel utilization.
  test(
      'reads on opening, then every 60 s while watched, and stops once '
      'nothing watches it', () {
    fakeAsync((async) {
      final container = ProviderContainer(overrides: [
        uspWifiDataServiceProvider.overrideWithValue(mockService),
      ]);
      container.listen(wifiDataProvider, (_, __) {});
      async.flushMicrotasks();

      // The Channels tab opens.
      final tab =
          container.listen(channelUtilizationRefreshProvider, (_, __) {});
      async.flushMicrotasks();
      verify(() => mockService.fetchUtilizationByRadioPath(any())).called(1);

      async.elapse(const Duration(seconds: 59));
      verifyNever(() => mockService.fetchUtilizationByRadioPath(any()));
      async.elapse(const Duration(seconds: 1));
      verify(() => mockService.fetchUtilizationByRadioPath(any())).called(1);

      // The user leaves the tab: the card stops building it.
      tab.close();
      async.elapse(const Duration(minutes: 5));
      verifyNever(() => mockService.fetchUtilizationByRadioPath(any()));

      container.dispose();
    });
  });
}
