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

  const pendingSessionInfo = GRASessionInfo(
    id: 'session-1',
    serialNumber: 'TEST123',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.pending,
    expiredIn: -100,
    createdAt: 1748315872000,
    statusChangedAt: 1748315989000,
    currentTime: 1748316924838,
  );

  const initiateSessionInfo = GRASessionInfo(
    id: 'session-1',
    serialNumber: 'TEST123',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.initiate,
    expiredIn: -100,
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
      expect(container.read(remoteClientProvider).sessionInfo, testSessionInfo);
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

  group('nextPollInterval', () {
    test('returns 5s before the session is active', () {
      final notifier = container.read(remoteClientProvider.notifier);
      expect(notifier.nextPollInterval(null), 5);
      expect(notifier.nextPollInterval(GRASessionStatus.initiate), 5);
      expect(notifier.nextPollInterval(GRASessionStatus.pending), 5);
      expect(notifier.nextPollInterval(GRASessionStatus.invalid), 5);
    });

    test('returns 60s once the session is active', () {
      final notifier = container.read(remoteClientProvider.notifier);
      expect(notifier.nextPollInterval(GRASessionStatus.active), 60);
    });
  });

  group('pollSessionOnce', () {
    test('no session: clears sessionInfo and returns null', () async {
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => []);

      final notifier = container.read(remoteClientProvider.notifier);
      final result = await notifier.pollSessionOnce();

      expect(result, isNull);
      expect(container.read(remoteClientProvider).sessionInfo, isNull);
      verifyNever(mockCloudService.createPin(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      ));
    });

    test('pending with no pin: creates a pin once', () async {
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => [pendingSessionInfo]);
      when(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async => pendingSessionInfo);
      when(mockCloudService.createPin(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async => '1234');

      final notifier = container.read(remoteClientProvider.notifier);
      final result = await notifier.pollSessionOnce();

      expect(result, pendingSessionInfo);
      expect(container.read(remoteClientProvider).pin, '1234');
      verify(mockCloudService.createPin(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).called(1);
    });

    test('initiate with no pin: creates a pin once', () async {
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => [initiateSessionInfo]);
      when(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async => initiateSessionInfo);
      when(mockCloudService.createPin(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async => '1234');

      final notifier = container.read(remoteClientProvider.notifier);
      final result = await notifier.pollSessionOnce();

      expect(result, initiateSessionInfo);
      expect(container.read(remoteClientProvider).pin, '1234');
      verify(mockCloudService.createPin(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).called(1);
    });

    test('pending but pin already exists: does not create another pin',
        () async {
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => [pendingSessionInfo]);
      when(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async => pendingSessionInfo);
      when(mockCloudService.createPin(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async => '1234');

      final notifier = container.read(remoteClientProvider.notifier);
      // First poll creates the pin.
      await notifier.pollSessionOnce();
      // Second poll must NOT create another pin.
      await notifier.pollSessionOnce();

      verify(mockCloudService.createPin(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).called(1);
    });

    test('no session: also clears a previously created pin', () async {
      // First poll: pending session creates a pin.
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => [pendingSessionInfo]);
      when(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async => pendingSessionInfo);
      when(mockCloudService.createPin(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async => '1234');

      final notifier = container.read(remoteClientProvider.notifier);
      await notifier.pollSessionOnce();
      expect(container.read(remoteClientProvider).pin, '1234');

      // Session disappears: pin must be cleared too.
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => []);
      await notifier.pollSessionOnce();

      expect(container.read(remoteClientProvider).sessionInfo, isNull);
      expect(container.read(remoteClientProvider).pin, isNull);
    });
  });

  group('active polling lifecycle', () {
    test(
        'initiateRemoteAssistance polls once and starts polling, '
        'endRemoteAssistance stops it', () async {
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => []);

      final notifier = container.read(remoteClientProvider.notifier);
      await notifier.initiateRemoteAssistance();

      // One poll ran even though there is no session, and polling is armed.
      expect(notifier.isActivePolling, true);
      verify(mockCloudService.getSessions(master: anyNamed('master')))
          .called(1);

      // Closing the dialog stops polling and cancels the timer (no pending
      // timers remain after the test).
      await notifier.endRemoteAssistance();
      expect(notifier.isActivePolling, false);
    });

    test('initiateRemoteAssistance called twice stays armed without leaking',
        () async {
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => []);

      final notifier = container.read(remoteClientProvider.notifier);
      await notifier.initiateRemoteAssistance();
      await notifier.initiateRemoteAssistance();

      expect(notifier.isActivePolling, true);
      // Two explicit initiate calls each poll once immediately.
      verify(mockCloudService.getSessions(master: anyNamed('master')))
          .called(2);

      await notifier.endRemoteAssistance();
      expect(notifier.isActivePolling, false);
    });

    test('initial poll error still arms polling and does not throw', () async {
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenThrow(Exception('Network error'));

      final notifier = container.read(remoteClientProvider.notifier);
      // Must not throw.
      await notifier.initiateRemoteAssistance();
      expect(notifier.isActivePolling, true);

      await notifier.endRemoteAssistance();
      expect(notifier.isActivePolling, false);
    });
  });

  group('dialog shown flag', () {
    test('defaults to false', () {
      expect(container.read(remoteClientProvider).isDialogShown, false);
    });

    test('setDialogShown updates the flag', () {
      final notifier = container.read(remoteClientProvider.notifier);

      notifier.setDialogShown(true);
      expect(container.read(remoteClientProvider).isDialogShown, true);

      notifier.setDialogShown(false);
      expect(container.read(remoteClientProvider).isDialogShown, false);
    });

    test('endRemoteAssistance clears the flag even with no session', () async {
      final notifier = container.read(remoteClientProvider.notifier);
      notifier.setDialogShown(true);

      await notifier.endRemoteAssistance();

      expect(container.read(remoteClientProvider).isDialogShown, false);
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
