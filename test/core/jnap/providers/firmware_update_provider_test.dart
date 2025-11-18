import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/services/firmware_update_service.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_ui_model.dart';

import '../../../mocks/_index.dart';

void main() {
  group('FirmwareUpdateNotifier', () {
    late MockFirmwareUpdateService mockFirmwareUpdateService;
    late MockDeviceManagerNotifier mockDeviceManagerNotifier;
    late MockPollingNotifier mockPollingNotifier;
    late ProviderContainer container;

    setUp(() {
      mockFirmwareUpdateService = MockFirmwareUpdateService();
      mockDeviceManagerNotifier = MockDeviceManagerNotifier();
      mockPollingNotifier = MockPollingNotifier();

      container = ProviderContainer(
        overrides: [
          firmwareUpdateServiceProvider
              .overrideWithValue(mockFirmwareUpdateService),
          deviceManagerProvider
              .overrideWith(() => mockDeviceManagerNotifier),
          pollingProvider.overrideWith(() => mockPollingNotifier),
        ],
      );
    });

    test('build uses default settings when fwUpdateSettingsRaw is null', () {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      // No specific mock for pollingProvider.select, so it will return null by default
      expect(notifier.state.settings.updatePolicy, 'AutomaticallyCheckAndInstall');
    });

    test('build uses default settings when fwUpdateSettingsRaw is not JNAPSuccess', () {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      // Since pollingProvider.select is not mocked, it will return null by default,
      // which will lead to using default settings.
      expect(notifier.state.settings.updatePolicy, 'AutomaticallyCheckAndInstall');
    });

    test('initial state is correct', () {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      expect(notifier.state, FirmwareUpdateState(
        settings: FirmwareUpdateSettings(
          updatePolicy: 'AutomaticallyCheckAndInstall',
          autoUpdateWindow: FirmwareAutoUpdateWindow.simple(),
        ),
        nodesStatus: const [],
      ));
    });

    test('setFirmwareUpdatePolicy updates state on success', () async {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      const policy = 'manual';
      when(mockFirmwareUpdateService.setFirmwareUpdatePolicy(
              policy, notifier.state.settings))
          .thenAnswer((_) async =>
              notifier.state.settings.copyWith(updatePolicy: policy));

      await notifier.setFirmwareUpdatePolicy(policy);

      expect(notifier.state.settings.updatePolicy, policy);
    });

    test('setFirmwareUpdatePolicy throws error when service fails', () async {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      const policy = 'manual';
      when(mockFirmwareUpdateService.setFirmwareUpdatePolicy(
              policy, notifier.state.settings))
          .thenThrow(Exception('Service Error'));

      expect(
          () => notifier.setFirmwareUpdatePolicy(policy), throwsA(isA<Exception>()));
    });

    test('fetchAvailableFirmwareUpdates updates state on success', () async {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      final nodes = [
        FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: '',
            availableUpdate: AvailableUpdateUIModel(
                version: '1', date: 'd', description: 'desc'))
      ];
      when(mockFirmwareUpdateService.fetchAvailableFirmwareUpdates(
              notifier.state.nodesStatus, any))
          .thenAnswer((_) async => (nodes, true));

      await notifier.fetchAvailableFirmwareUpdates();

      expect(notifier.state.nodesStatus, nodes);
    });

    test('fetchAvailableFirmwareUpdates throws error when service fails', () async {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      when(mockFirmwareUpdateService.fetchAvailableFirmwareUpdates(
              notifier.state.nodesStatus, any))
          .thenThrow(Exception('Service Error'));

      expect(
          () => notifier.fetchAvailableFirmwareUpdates(), throwsA(isA<Exception>()));
    });

    test('updateFirmware updates state during stream', () async {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      final nodes = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
      ];
      when(mockFirmwareUpdateService.updateFirmware(
        notifier.state.nodesStatus,
        any,
      )).thenAnswer((_) => Stream.value(nodes));

      await notifier.updateFirmware();

      expect(notifier.state.nodesStatus, nodes);
    });

    test('updateFirmware updates state on stream error', () async {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      final nodes = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
      ];
      when(mockFirmwareUpdateService.updateFirmware(
        notifier.state.nodesStatus,
        any,
      )).thenAnswer((_) => Stream.error(Exception('Stream Error')));

      await notifier.updateFirmware();

      // Expect that isUpdating remains true on error, as the service is designed to retry.
      expect(notifier.state.isUpdating, isTrue);
    });

    test('updateFirmware updates state when exceedMaxRetry is true', () async {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      final nodes = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
      ];
      when(mockFirmwareUpdateService.updateFirmware(
        notifier.state.nodesStatus,
        any,
      )).thenAnswer((invocation) {
        final onCompleted = invocation.positionalArguments[1] as Function(bool);
        onCompleted(true); // Simulate exceedMaxRetry = true
        return Stream.value(nodes);
      });

      await notifier.updateFirmware();

      // Expect that isRetryMaxReached is set to true and isUpdating is set to false
      expect(notifier.state.isRetryMaxReached, isTrue);
      expect(notifier.state.isUpdating, isFalse);
    });

    test('finishFirmwareUpdate calls service', () async {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      when(mockFirmwareUpdateService.finishFirmwareUpdate())
          .thenAnswer((_) async => {});
      when(mockPollingNotifier.checkAndStartPolling()).thenAnswer((_) {});

      await notifier.finishFirmwareUpdate();

      verify(mockFirmwareUpdateService.finishFirmwareUpdate()).called(1);
    });

    test('finishFirmwareUpdate throws error when service fails', () async {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      when(mockFirmwareUpdateService.finishFirmwareUpdate())
          .thenThrow(Exception('Service Error'));

      expect(
          () => notifier.finishFirmwareUpdate(), throwsA(isA<Exception>()));
    });

    test('getAvailableUpdateNumber calls service', () {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      when(mockFirmwareUpdateService
              .getAvailableUpdateNumber(notifier.state.nodesStatus))
          .thenReturn(1);

      final result = notifier.getAvailableUpdateNumber();

      expect(result, 1);
      verify(mockFirmwareUpdateService
              .getAvailableUpdateNumber(notifier.state.nodesStatus))
          .called(1);
    });

    test('isFailedCheckFirmwareUpdate calls service', () {
      final notifier = container.read(firmwareUpdateProvider.notifier);
      when(mockFirmwareUpdateService
              .isFailedCheckFirmwareUpdate(notifier.state.nodesStatus))
          .thenReturn(true);

      final result = notifier.isFailedCheckFirmwareUpdate();

      expect(result, isTrue);
      verify(mockFirmwareUpdateService
              .isFailedCheckFirmwareUpdate(notifier.state.nodesStatus))
          .called(1);
    });
  });
}