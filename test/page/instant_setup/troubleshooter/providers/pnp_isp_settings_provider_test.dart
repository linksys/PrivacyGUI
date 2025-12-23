import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';

import '../../../../mocks/internet_settings_notifier_mocks.dart';
import '../../../../mocks/pnp_isp_service_notifier_mocks.dart';
import '../../../../mocks/pnp_service_mocks.dart';

void main() {
  group('PnpIspSettingsNotifier', () {
    late MockInternetSettingsNotifier mockInternetSettingsNotifier;
    late MockPnpIspService mockPnpIspService;
    late MockPnpService mockPnpService;
    late ProviderContainer container;
    late List<PnpIspSettingsStatus> states;

    setUp(() {
      mockInternetSettingsNotifier = MockInternetSettingsNotifier();
      mockPnpIspService = MockPnpIspService();
      mockPnpService = MockPnpService();
      states = [];

      container = ProviderContainer(
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
          pnpIspServiceProvider.overrideWithValue(mockPnpIspService),
          pnpServiceProvider.overrideWithValue(mockPnpService),
        ],
      );

      container.listen<PnpIspSettingsStatus>(
        pnpIspSettingsProvider,
        (previous, next) {
          states.add(next);
        },
        fireImmediately: true,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('saveAndVerifySettings success flow updates state correctly',
        () async {
      // ARRANGE
      final mockSettings = InternetSettings.init().copyWith(
        ipv4Setting: const Ipv4Setting(ipv4ConnectionType: 'DHCP', mtu: 1500),
      );
      when(mockInternetSettingsNotifier.savePnpIpv4(any))
          .thenAnswer((_) async {});
      when(mockPnpIspService.verifyNewSettings(WanType.dhcp))
          .thenAnswer((_) async => true);

      when(mockPnpService.checkInternetConnection(any)).thenAnswer((_) async {
        return true;
      });

      // ACT
      await container
          .read(pnpIspSettingsProvider.notifier)
          .saveAndVerifySettings(mockSettings);

      // ASSERT
      expect(states, [
        PnpIspSettingsStatus.initial,
        PnpIspSettingsStatus.saving,
        PnpIspSettingsStatus.checkSettings,
        PnpIspSettingsStatus.checkInternetConnection,
        PnpIspSettingsStatus.success,
      ]);

      verify(mockInternetSettingsNotifier.savePnpIpv4(mockSettings)).called(1);
      verify(mockPnpIspService.verifyNewSettings(WanType.dhcp)).called(1);
      verify(mockPnpService.checkInternetConnection(30)).called(1);
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('saveAndVerifySettings failure flow updates state correctly',
        () async {
      // ARRANGE
      final mockSettings = InternetSettings.init().copyWith(
        ipv4Setting: const Ipv4Setting(ipv4ConnectionType: 'DHCP', mtu: 1500),
      );
      when(mockInternetSettingsNotifier.savePnpIpv4(any))
          .thenAnswer((_) async {});
      when(mockPnpIspService.verifyNewSettings(WanType.dhcp))
          .thenAnswer((_) async => false); // Simulate verification failure
      when(mockPnpService.checkInternetConnection(any)).thenAnswer((_) async {
        return false;
      }); // This should not be called

      // ACT
      final future = container
          .read(pnpIspSettingsProvider.notifier)
          .saveAndVerifySettings(mockSettings);

      // ASSERT
      await expectLater(future, throwsA(isA<Exception>()));

      expect(states, [
        PnpIspSettingsStatus.initial,
        PnpIspSettingsStatus.saving,
        PnpIspSettingsStatus.checkSettings,
        PnpIspSettingsStatus.error,
      ]);

      verify(mockInternetSettingsNotifier.savePnpIpv4(mockSettings)).called(1);
      verify(mockPnpIspService.verifyNewSettings(WanType.dhcp)).called(1);
      verifyNever(mockPnpService.checkInternetConnection(any));
    });

    test(
        'saveAndVerifySettings throws when verification succeeds but internet check fails',
        () async {
      // ARRANGE
      final mockSettings = InternetSettings.init().copyWith(
        ipv4Setting: const Ipv4Setting(ipv4ConnectionType: 'DHCP', mtu: 1500),
      );
      when(mockInternetSettingsNotifier.savePnpIpv4(any))
          .thenAnswer((_) async {});
      when(mockPnpIspService.verifyNewSettings(WanType.dhcp))
          .thenAnswer((_) async => true);
      when(mockPnpService.checkInternetConnection(any)).thenThrow(
          ExceptionNoInternetConnection()); // Simulate internet check failure

      // ACT
      final future = container
          .read(pnpIspSettingsProvider.notifier)
          .saveAndVerifySettings(mockSettings);

      // ASSERT
      await expectLater(future, throwsA(isA<ExceptionNoInternetConnection>()));

      verify(mockInternetSettingsNotifier.savePnpIpv4(mockSettings)).called(1);
      verify(mockPnpIspService.verifyNewSettings(WanType.dhcp)).called(1);
      verify(mockPnpService.checkInternetConnection(30)).called(1);
    });

    test('saveAndVerifySettings fails when savePnpIpv4 throws', () async {
      // ARRANGE
      final mockSettings = InternetSettings.init().copyWith(
        ipv4Setting: const Ipv4Setting(ipv4ConnectionType: 'DHCP', mtu: 1500),
      );
      final exception = Exception('Save failed');
      when(mockInternetSettingsNotifier.savePnpIpv4(any)).thenThrow(exception);

      // ACT
      final future = container
          .read(pnpIspSettingsProvider.notifier)
          .saveAndVerifySettings(mockSettings);

      // ASSERT
      await expectLater(future, throwsA(isA<Exception>()));

      expect(states, [
        PnpIspSettingsStatus.initial,
        PnpIspSettingsStatus.saving,
        PnpIspSettingsStatus.error,
      ]);

      verify(mockInternetSettingsNotifier.savePnpIpv4(mockSettings)).called(1);
      verifyNever(mockPnpIspService.verifyNewSettings(any));
      verifyNever(mockPnpService.checkInternetConnection(any));
    });
  });
}
