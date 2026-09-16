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

import '../../../../mocks/device_manager_notifier_mocks.dart';
import 'remote_client_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<DeviceCloudService>(),
])
void main() {
  late MockDeviceCloudService mockCloudService;
  late ProviderContainer container;

  // expiredIn is seconds remaining against a one-hour TTL, so with these
  // timestamps the only contract-consistent value is
  // 3600 - (currentTime - createdAt) / 1000 = 2547. These fixtures used
  // negative values before, which is what #1558's inverted guard was built on.
  const testSessionInfo = GRASessionInfo(
    id: 'session-1',
    serialNumber: 'TEST123',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.active,
    expiredIn: 2547,
    createdAt: 1748315872000,
    statusChangedAt: 1748315989000,
    currentTime: 1748316924838,
  );

  const pendingSessionInfo = GRASessionInfo(
    id: 'session-1',
    serialNumber: 'TEST123',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.pending,
    expiredIn: 2547,
    createdAt: 1748315872000,
    statusChangedAt: 1748315989000,
    currentTime: 1748316924838,
  );

  const initiateSessionInfo = GRASessionInfo(
    id: 'session-1',
    serialNumber: 'TEST123',
    modelNumber: 'LN16-EU',
    status: GRASessionStatus.initiate,
    expiredIn: 2547,
    createdAt: 1748315872000,
    statusChangedAt: 1748315989000,
    currentTime: 1748316924838,
  );

  const deviceManagerState = DeviceManagerState(
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

  setUp(() {
    mockCloudService = MockDeviceCloudService();

    final mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    when(mockDeviceManagerNotifier.build()).thenReturn(deviceManagerState);

    container = ProviderContainer(
      overrides: [
        deviceCloudServiceProvider.overrideWithValue(mockCloudService),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
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

  // These replace a group that asserted the old `.abs()` arithmetic inline
  // without calling any production code, and so documented behaviour that #1558
  // removed. They drive the real countdown instead.
  group('expired countdown seeding', () {
    Future<void> seedCountdown(GRASessionInfo sessionInfo) async {
      when(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async => sessionInfo);
      await container
          .read(remoteClientProvider.notifier)
          .fetchSessionInfo(sessionInfo.id, startCountdown: true);
      // The timer ticks once a second; one tick is enough to read the seed back.
      await Future.delayed(const Duration(milliseconds: 1100));
    }

    test('a positive expiredIn is the countdown, with nothing added to it',
        () async {
      await seedCountdown(testSessionInfo);

      expect(container.read(remoteClientProvider).expiredCountdown,
          testSessionInfo.expiredIn - 1);
    });

    test('a non-positive expiredIn floors at zero instead of inverting',
        () async {
      // The old code used `.abs()`, which read an already-expired session as
      // having that many seconds still to run.
      await seedCountdown(const GRASessionInfo(
        id: 'session-1',
        serialNumber: 'TEST123',
        modelNumber: 'LN16-EU',
        status: GRASessionStatus.active,
        expiredIn: -500,
        createdAt: 1748315872000,
        statusChangedAt: 1748315989000,
        currentTime: 1748316924838,
      ));

      expect(container.read(remoteClientProvider).expiredCountdown,
          lessThanOrEqualTo(0));
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

  // #1558: the loop guarded on `expiredIn < 0`, so its body never ran and the
  // stream completed without issuing a single request. These had no coverage at
  // all before.
  group('session info stream', () {
    /// Answers successive `getSessionInfo` calls from [responses], repeating the
    /// last one once exhausted. The first is consumed by the seeding
    /// `fetchSessionInfo`; the rest belong to the stream.
    void queueSessionInfo(List<GRASessionInfo> responses) {
      var index = 0;
      when(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async {
        final response = responses[index];
        if (index < responses.length - 1) index++;
        return response;
      });
    }

    GRASessionInfo sessionWith(
            {required GRASessionStatus status, required int expiredIn}) =>
        GRASessionInfo(
          id: 'session-1',
          serialNumber: 'TEST123',
          modelNumber: 'LN16-EU',
          status: status,
          expiredIn: expiredIn,
          createdAt: 1748315872000,
          statusChangedAt: 1748315989000,
          currentTime: 1748316924838,
        );

    /// An interval of zero keeps each iteration on the event loop rather than a
    /// real clock, so a short settle is enough to run several of them.
    Future<void> runStream() async {
      final notifier = container.read(remoteClientProvider.notifier);
      await notifier.fetchSessionInfo('session-1');
      notifier.startSessionInfoStream(interval: 0);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    test('polls while the session is alive and stops once it goes INVALID',
        () async {
      queueSessionInfo([
        sessionWith(status: GRASessionStatus.active, expiredIn: 2547),
        sessionWith(status: GRASessionStatus.active, expiredIn: 2540),
        sessionWith(status: GRASessionStatus.invalid, expiredIn: 2530),
      ]);

      await runStream();

      // One seeding call plus two from the stream. Before the fix this was one:
      // the seed, and nothing else ever.
      verify(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).called(3);
      expect(container.read(remoteClientProvider).sessionInfo?.status,
          GRASessionStatus.invalid);
    });

    test('stops when the session has no time left', () async {
      queueSessionInfo([
        sessionWith(status: GRASessionStatus.active, expiredIn: 2547),
        sessionWith(status: GRASessionStatus.active, expiredIn: 0),
      ]);

      await runStream();

      verify(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).called(2);
    });

    test('a finished stream releases the guard on initiateRemoteAssistanceCA',
        () async {
      // The subscription used to stay non-null after the stream completed, so
      // the guard treated a dead stream as a live one and refused every later
      // session for the rest of the app's life.
      queueSessionInfo([
        sessionWith(status: GRASessionStatus.active, expiredIn: 2547),
        sessionWith(status: GRASessionStatus.invalid, expiredIn: 2540),
      ]);

      await runStream();

      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => []);
      await container
          .read(remoteClientProvider.notifier)
          .initiateRemoteAssistanceCA();

      // It got past the guard and looked for sessions.
      verify(mockCloudService.getSessions(master: anyNamed('master')))
          .called(1);
    });

    test('a stream error releases the guard rather than dying silently',
        () async {
      when(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenAnswer((_) async =>
          sessionWith(status: GRASessionStatus.active, expiredIn: 2547));
      final notifier = container.read(remoteClientProvider.notifier);
      await notifier.fetchSessionInfo('session-1');

      when(mockCloudService.getSessionInfo(
        master: anyNamed('master'),
        sessionId: anyNamed('sessionId'),
      )).thenThrow(Exception('404 session deleted'));
      notifier.startSessionInfoStream(interval: 0);
      await Future.delayed(const Duration(milliseconds: 50));

      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => []);
      await notifier.initiateRemoteAssistanceCA();

      verify(mockCloudService.getSessions(master: anyNamed('master')))
          .called(1);
    });

    test('concurrent initiateRemoteAssistanceCA calls fetch sessions once',
        () async {
      // The old guard read a field that is only assigned two awaits later, so
      // the CG#209 log shows five calls slipping through within 1.2 s.
      when(mockCloudService.getSessions(master: anyNamed('master')))
          .thenAnswer((_) async => []);

      final notifier = container.read(remoteClientProvider.notifier);
      await Future.wait([
        notifier.initiateRemoteAssistanceCA(),
        notifier.initiateRemoteAssistanceCA(),
        notifier.initiateRemoteAssistanceCA(),
      ]);

      verify(mockCloudService.getSessions(master: anyNamed('master')))
          .called(1);
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
