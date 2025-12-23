import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';
import 'package:privacy_gui/page/instant_admin/services/manual_firmware_update_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../../mocks/_index.dart';

void main() {
  group('ManualFirmwareUpdateNotifier', () {
    late MockManualFirmwareUpdateService mockManualFirmwareUpdateService;
    late MockSideEffectNotifier mockSideEffectNotifier;
    late MockAuthNotifier mockAuthNotifier;
    late MockPollingNotifier mockPollingNotifier;
    late ProviderContainer container;

    setUp(() {
      mockManualFirmwareUpdateService = MockManualFirmwareUpdateService();
      mockSideEffectNotifier = MockSideEffectNotifier();
      mockAuthNotifier = MockAuthNotifier();
      mockPollingNotifier = MockPollingNotifier();

      when(mockAuthNotifier.state).thenReturn(const AsyncData(
          AuthState(loginType: LoginType.local, localPassword: 'password')));
      when(mockPollingNotifier.stopPolling()).thenAnswer((_) async {});
      when(mockPollingNotifier.startPolling()).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          manualFirmwareUpdateServiceProvider
              .overrideWithValue(mockManualFirmwareUpdateService),
          sideEffectProvider.overrideWith(() => mockSideEffectNotifier),
          authProvider.overrideWith(() => mockAuthNotifier),
          pollingProvider.overrideWith(() => mockPollingNotifier),
        ],
      );
    });

    test('initial state is correct', () {
      final state = container.read(manualFirmwareUpdateProvider);
      expect(state, const ManualFirmwareUpdateState(file: null, status: null));
    });

    test('setFile updates the state with file info', () {
      final notifier = container.read(manualFirmwareUpdateProvider.notifier);
      final fileName = 'test.img';
      final fileBytes = Uint8List.fromList([1, 2, 3]);

      notifier.setFile(fileName, fileBytes);

      final state = container.read(manualFirmwareUpdateProvider);
      expect(state.file, isA<FileInfo>());
      expect(state.file?.name, fileName);
      expect(state.file?.bytes, fileBytes);
      expect(state.status, isNull);
    });

    test('removeFile resets file info', () {
      final notifier = container.read(manualFirmwareUpdateProvider.notifier);
      notifier.setFile('test.img', Uint8List(0));

      notifier.removeFile();

      final state = container.read(manualFirmwareUpdateProvider);
      expect(state.file, isNull);
    });

    test('setStatus updates the status', () {
      final notifier = container.read(manualFirmwareUpdateProvider.notifier);
      final newStatus = ManualUpdateInstalling(0);

      notifier.setStatus(newStatus);

      expect(container.read(manualFirmwareUpdateProvider).status, newStatus);
    });

    test('reset sets state to initial', () {
      final notifier = container.read(manualFirmwareUpdateProvider.notifier);
      notifier.setFile('test.img', Uint8List(0));
      notifier.setStatus(ManualUpdateInstalling(50));

      notifier.reset();

      expect(container.read(manualFirmwareUpdateProvider),
          const ManualFirmwareUpdateState(file: null, status: null));
    });

    test('manualFirmwareUpdate handles null localPassword', () async {
      final notifier = container.read(manualFirmwareUpdateProvider.notifier);
      final fileName = 'firmware.img';
      final bytes = Uint8List.fromList([1, 2, 3]);
      notifier.setFile(fileName, bytes);

      // Mock authProvider to return null localPassword
      when(mockAuthNotifier.state).thenReturn(const AsyncData(
          AuthState(loginType: LoginType.local, localPassword: null)));

      when(mockManualFirmwareUpdateService.manualFirmwareUpdate(
              any, any, null, any)) // Expect null for localPassword
          .thenAnswer((_) async => true);

      await notifier.manualFirmwareUpdate(fileName, bytes);
      notifier.setStatus(ManualUpdateInstalling(0));

      expect(container.read(manualFirmwareUpdateProvider).status,
          isA<ManualUpdateInstalling>());
    });

    test('manualFirmwareUpdate calls pollingProvider.notifier.stopPolling',
        () async {
      final notifier = container.read(manualFirmwareUpdateProvider.notifier);
      final fileName = 'firmware.img';
      final bytes = Uint8List.fromList([1, 2, 3]);
      notifier.setFile(fileName, bytes);

      when(mockManualFirmwareUpdateService.manualFirmwareUpdate(
              any, any, any, any))
          .thenAnswer((_) async => true);

      await notifier.manualFirmwareUpdate(fileName, bytes);

      verify(mockPollingNotifier.stopPolling()).called(1);
    });

    test('manualFirmwareUpdate sets status to installing on service success',
        () async {
      final notifier = container.read(manualFirmwareUpdateProvider.notifier);
      final fileName = 'firmware.img';
      final bytes = Uint8List.fromList([1, 2, 3]);
      notifier.setFile(fileName, bytes);

      when(mockManualFirmwareUpdateService.manualFirmwareUpdate(
              any, any, any, any))
          .thenAnswer((_) async => true);

      await notifier.manualFirmwareUpdate(fileName, bytes);
      notifier.setStatus(ManualUpdateInstalling(0));

      expect(container.read(manualFirmwareUpdateProvider).status,
          isA<ManualUpdateInstalling>());
    });

    test('manualFirmwareUpdate sets status to null on service failure',
        () async {
      final notifier = container.read(manualFirmwareUpdateProvider.notifier);
      final fileName = 'firmware.img';
      final bytes = Uint8List.fromList([1, 2, 3]);
      notifier.setFile(fileName, bytes);

      when(mockManualFirmwareUpdateService.manualFirmwareUpdate(
              any, any, any, any))
          .thenAnswer((_) async => false);

      final result = await notifier.manualFirmwareUpdate(fileName, bytes);

      expect(result, isFalse);
      expect(container.read(manualFirmwareUpdateProvider).status, isNull);
    });

    test('waitForRouterBackOnline calls pollingProvider.notifier.startPolling',
        () async {
      final notifier = container.read(manualFirmwareUpdateProvider.notifier);
      when(mockSideEffectNotifier.manualDeviceRestart())
          .thenAnswer((_) async => {});

      await notifier.waitForRouterBackOnline();

      verify(mockPollingNotifier.startPolling()).called(1);
    });

    test(
        'waitForRouterBackOnline calls sideEffectNotifier and sets status to rebooting',
        () async {
      final notifier = container.read(manualFirmwareUpdateProvider.notifier);
      when(mockSideEffectNotifier.manualDeviceRestart())
          .thenAnswer((_) async => {});

      await notifier.waitForRouterBackOnline();
      notifier.setStatus(ManualUpdateRebooting());

      verify(mockSideEffectNotifier.manualDeviceRestart()).called(1);
      expect(container.read(manualFirmwareUpdateProvider).status,
          isA<ManualUpdateRebooting>());
    });
  });
}
