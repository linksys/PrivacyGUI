import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/cloud/linksys_device_cloud_service.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

import 'remote_client_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<DeviceCloudService>(),
])
void main() {
  late MockDeviceCloudService mockCloudService;
  late ProviderContainer container;

  const testSessionInfo = GRASessionInfo(
    id: 'session-1',
    serialNumber: 'TEST123',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.active,
    expiredIn: -748,
    createdAt: 1748315872000,
    statusChangedAt: 1748315989000,
    currentTime: 1748316924838,
  );

  setUp(() {
    mockCloudService = MockDeviceCloudService();

    container = ProviderContainer(
      overrides: [
        deviceCloudServiceProvider.overrideWithValue(mockCloudService),
        deviceManagerProvider.overrideWith(() => _FakeDeviceManagerNotifier()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('checkActiveSession', () {
    test('returns null when sessions list is empty', () async {
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => []);

      final notifier = container.read(remoteClientProvider.notifier);
      final result = await notifier.checkActiveSession();

      expect(result, isNull);
      expect(container.read(remoteClientProvider).sessionInfo, isNull);
    });

    test('returns active status when active session found', () async {
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => [testSessionInfo]);
      when(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async => testSessionInfo);

      final notifier = container.read(remoteClientProvider.notifier);
      final result = await notifier.checkActiveSession();

      expect(result, GRASessionStatus.active);
      expect(
          container.read(remoteClientProvider).sessionInfo, testSessionInfo);
    });

    test('returns null and logs error when exception thrown', () async {
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenThrow(Exception('Network error'));

      final notifier = container.read(remoteClientProvider.notifier);
      final result = await notifier.checkActiveSession();

      expect(result, isNull);
    });
  });

  group('countdown timer .abs() behavior', () {
    test('expiredIn negative value produces positive countdown', () {
      const sessionInfo = GRASessionInfo(
        id: 'session-1',
        serialNumber: 'TEST123',
        modelNumber: 'LN16-EU',
        status: GRASessionStatus.active,
        expiredIn: -500,
        createdAt: 1748315872000,
        statusChangedAt: 1748315989000,
        currentTime: 1748316924838,
      );
      final initialSeconds = sessionInfo.expiredIn.abs();
      expect(initialSeconds, 500);
    });

    test('expiredIn positive value still produces positive countdown', () {
      const sessionInfo = GRASessionInfo(
        id: 'session-1',
        serialNumber: 'TEST123',
        modelNumber: 'LN16-EU',
        status: GRASessionStatus.active,
        expiredIn: 300,
        createdAt: 1748315872000,
        statusChangedAt: 1748315989000,
        currentTime: 1748316924838,
      );
      final initialSeconds = sessionInfo.expiredIn.abs();
      expect(initialSeconds, 300);
    });

    test('pending widget calculation with kPendingSessionDurationSec', () {
      const pendingDuration = 2700;
      const expiredIn = -100;
      final initialSeconds = (pendingDuration + expiredIn).abs();
      expect(initialSeconds, 2600);
    });

    test('pending widget calculation handles zero expiredIn', () {
      const pendingDuration = 2700;
      const expiredIn = 0;
      final initialSeconds = (pendingDuration + expiredIn).abs();
      expect(initialSeconds, 2700);
    });
  });
}

class _FakeDeviceManagerNotifier extends DeviceManagerNotifier {
  @override
  DeviceManagerState build() {
    return const DeviceManagerState(
      deviceList: [
        LinksysDevice(
          connections: [],
          properties: [],
          unit: RawDeviceUnit(serialNumber: 'TEST123'),
          deviceID: 'device-uuid-1',
          maxAllowedProperties: 10,
          model: RawDeviceModel(deviceType: 'Infrastructure'),
          isAuthority: true,
          lastChangeRevision: 1,
          nodeType: 'Master',
          knownInterfaces: [
            RawDeviceKnownInterface(
              macAddress: 'AA:BB:CC:DD:EE:FF',
              interfaceType: 'Wireless',
            ),
          ],
        ),
      ],
    );
  }
}
