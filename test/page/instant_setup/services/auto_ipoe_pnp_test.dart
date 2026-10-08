import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/internet_settings/services/auto_ipoe_service.dart';

import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class MockPnpClient extends Mock implements UspClient {}

class MockAutoIPoEService extends Mock implements AutoIPoEService {}

void stubOrdinaryWan(MockPnpClient client) {
  when(() => client.get(any())).thenAnswer((_) async => {
        'Device.IP.Interface.2.Alias': 'wan',
        'Device.IP.Interface.2.Status': 'Up',
        'Device.IP.Interface.2.IPv4Address.1.IPAddress': '192.0.2.2',
        'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
        'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
        'Device.IP.Interface.2.MaxMTUSize': '1500',
        'Device.IP.Interface.2.IPv6Enable': true,
      });
}

void main() {
  group('PnpService - injected Auto-IPoE snapshot', () {
    test('accepts verified connectivity from the injected reader', () async {
      final client = MockPnpClient();
      var reads = 0;
      final service = PnpService(client, fetchAutoIPoE: () async {
        reads++;
        return AutoIPoETestData.snapshot(
          requestId: AutoIPoETestData.id,
          exitCode: 0,
          verified: true,
        );
      });

      expect(await service.checkInternetConnected(), isTrue);
      expect(reads, 1);
      verifyZeroInteractions(client);
    });

    for (final sample in [
      (
        name: 'accepted Apply',
        snapshot: AutoIPoETestData.snapshot(requestId: AutoIPoETestData.id),
      ),
      (
        name: 'unverified connection',
        snapshot: AutoIPoETestData.snapshot(
            requestId: AutoIPoETestData.id, exitCode: 0),
      ),
      (
        name: 'busy operation',
        snapshot: AutoIPoETestData.snapshot(
            requestId: AutoIPoETestData.id,
            exitCode: 0,
            verified: true,
            busy: true),
      ),
    ]) {
      test('does not promote ${sample.name} to connected', () async {
        final client = MockPnpClient();
        final service =
            PnpService(client, fetchAutoIPoE: () async => sample.snapshot);

        expect(await service.checkInternetConnected(), isFalse);
        verifyZeroInteractions(client);
      });
    }

    test('uses ordinary WAN when no optional reader is injected', () async {
      final client = MockPnpClient();
      stubOrdinaryWan(client);

      expect(await PnpService(client).checkInternetConnected(), isTrue);
      verify(() => client.get(any())).called(2);
      verifyNoMoreInteractions(client);
    });

    test('uses ordinary WAN when the optional object is absent', () async {
      final client = MockPnpClient();
      stubOrdinaryWan(client);
      final service = PnpService(client, fetchAutoIPoE: () async {
        throw const ResourceNotFoundError();
      });

      expect(await service.checkInternetConnected(), isTrue);
      verify(() => client.get(any())).called(2);
      verifyNoMoreInteractions(client);
    });

    test('uses ordinary WAN when the snapshot does not support Auto-IPoE',
        () async {
      final client = MockPnpClient();
      stubOrdinaryWan(client);
      final service = PnpService(client,
          fetchAutoIPoE: () async =>
              AutoIPoETestData.recoverySnapshot(capabilitiesAvailable: true));

      expect(await service.checkInternetConnected(), isTrue);
      verify(() => client.get(any())).called(2);
      verifyNoMoreInteractions(client);
    });

    test('uses ordinary WAN when Auto-IPoE is not the current connection',
        () async {
      final client = MockPnpClient();
      stubOrdinaryWan(client);
      final snapshot = AutoIPoETestData.snapshot();
      final service = PnpService(client,
          fetchAutoIPoE: () async => snapshot
              .withRuntime(snapshot.runtime.copyWith(isCurrentWANType: false)));

      expect(await service.checkInternetConnected(), isTrue);
      verify(() => client.get(any())).called(2);
      verifyNoMoreInteractions(client);
    });
  });

  group('pnpServiceProvider - device capability composition', () {
    test('unsupported devices do not initialize the Auto-IPoE service',
        () async {
      final client = MockPnpClient();
      stubOrdinaryWan(client);
      final container = ProviderContainer(overrides: [
        uspClientProvider.overrideWithValue(client),
        deviceCapabilitiesProvider.overrideWithValue(DeviceCapabilities.empty),
        autoIPoEServiceProvider.overrideWith(
            (_) => throw StateError('Unsupported service must not be opened')),
      ]);
      addTearDown(container.dispose);

      expect(await container.read(pnpServiceProvider).checkInternetConnected(),
          isTrue);
      verify(() => client.get(any())).called(2);
      verifyNoMoreInteractions(client);
    });

    test('supported devices use the injected Auto-IPoE service provider',
        () async {
      final client = MockPnpClient();
      final ipoe = MockAutoIPoEService();
      when(() => ipoe.fetch()).thenAnswer((_) async =>
          AutoIPoETestData.snapshot(
              requestId: AutoIPoETestData.id, exitCode: 0, verified: true));
      final container = ProviderContainer(overrides: [
        uspClientProvider.overrideWithValue(client),
        deviceCapabilitiesProvider
            .overrideWithValue(DeviceCapabilities({DeviceCapability.autoIPoE})),
        autoIPoEServiceProvider.overrideWithValue(ipoe),
      ]);
      addTearDown(container.dispose);

      expect(await container.read(pnpServiceProvider).checkInternetConnected(),
          isTrue);
      verify(() => ipoe.fetch()).called(1);
      verifyNoMoreInteractions(ipoe);
      verifyZeroInteractions(client);
    });

    test('capability loss switches the provider back to ordinary WAN',
        () async {
      final client = MockPnpClient();
      stubOrdinaryWan(client);
      final ipoe = MockAutoIPoEService();
      when(() => ipoe.fetch()).thenAnswer((_) async =>
          AutoIPoETestData.snapshot(
              requestId: AutoIPoETestData.id, exitCode: 0, verified: true));
      final capabilities = StateProvider<DeviceCapabilities>(
          (_) => DeviceCapabilities({DeviceCapability.autoIPoE}));
      final container = ProviderContainer(overrides: [
        uspClientProvider.overrideWithValue(client),
        deviceCapabilitiesProvider
            .overrideWith((ref) => ref.watch(capabilities)),
        autoIPoEServiceProvider.overrideWithValue(ipoe),
      ]);
      addTearDown(container.dispose);

      expect(await container.read(pnpServiceProvider).checkInternetConnected(),
          isTrue);
      container.read(capabilities.notifier).state = DeviceCapabilities.empty;
      await container.pump();
      expect(await container.read(pnpServiceProvider).checkInternetConnected(),
          isTrue);

      verify(() => ipoe.fetch()).called(1);
      verifyNoMoreInteractions(ipoe);
      verify(() => client.get(any())).called(2);
      verifyNoMoreInteractions(client);
    });
  });
}
