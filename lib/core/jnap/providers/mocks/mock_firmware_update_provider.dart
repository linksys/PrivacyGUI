import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_ui_model.dart';

/// To use this mock for manual testing, you can override the `firmwareUpdateProvider`
/// in the `ProviderScope` at the root of your app.
///
/// Example in your main.dart:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     firmwareUpdateProvider.overrideWith(() => MockFirmwareUpdateNotifier()),
///   ],
///   child: MyApp(),
/// )
/// ```

class MockFirmwareUpdateNotifier extends FirmwareUpdateNotifier {
  @override
  FirmwareUpdateState build() {
    return FirmwareUpdateState(
      settings: FirmwareUpdateSettings(
        updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
        autoUpdateWindow: FirmwareAutoUpdateWindow.simple(),
      ),
      nodesStatus: [
        FirmwareUpdateUIModel(
          deviceId: '1',
          deviceName: 'Mock Master Node',
          isMaster: true,
          lastSuccessfulCheckTime: DateTime.now().toIso8601String(),
          modelNumber: 'MX4200',
          currentFirmwareVersion: '1.0.0.1',
          availableUpdate: const AvailableUpdateUIModel(version: '1.1.0.5', date: '2025-11-18', description: 'New features and bug fixes'),
        ),
        FirmwareUpdateUIModel(
          deviceId: '2',
          deviceName: 'Mock Child Node 1',
          isMaster: false,
          lastSuccessfulCheckTime: DateTime.now().toIso8601String(),
          modelNumber: 'MX4200',
          currentFirmwareVersion: '1.0.0.1',
          availableUpdate: null,
        ),
        FirmwareUpdateUIModel(
          deviceId: '3',
          deviceName: 'Mock Child Node 2',
          isMaster: false,
          lastSuccessfulCheckTime: DateTime.now().toIso8601String(),
          modelNumber: 'MX4200',
          currentFirmwareVersion: '1.0.0.1',
          availableUpdate: const AvailableUpdateUIModel(version: '1.1.0.5', date: '2025-11-18', description: 'New features and bug fixes'),
        ),
      ],
    );
  }

  @override
  Future<void> updateFirmware() async {
    state = state.copyWith(isUpdating: true);
    ref.read(firmwareUpdateCandidateProvider.notifier).state = state.nodesStatus;

    final nodesToUpdate = state.nodesStatus?.where((n) => n.availableUpdate != null).toList() ?? [];

    // Simulate downloading
    for (var i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      final newStatus = state.nodesStatus?.map((node) {
        if (nodesToUpdate.any((n) => n.deviceId == node.deviceId)) {
          return node.copyWith(operation: 'downloading', progressPercent: i);
        }
        return node;
      }).toList();
      state = state.copyWith(nodesStatus: newStatus);
    }

    // Simulate installing
    for (var i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 300));
      final newStatus = state.nodesStatus?.map((node) {
        if (nodesToUpdate.any((n) => n.deviceId == node.deviceId)) {
          return node.copyWith(operation: 'installing', progressPercent: i);
        }
        return node;
      }).toList();
      state = state.copyWith(nodesStatus: newStatus);
    }
    
    // Simulate rebooting
    for (var i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newStatus = state.nodesStatus?.map((node) {
        if (nodesToUpdate.any((n) => n.deviceId == node.deviceId)) {
          return node.copyWith(operation: 'rebooting', progressPercent: i);
        }
        return node;
      }).toList();
      state = state.copyWith(nodesStatus: newStatus);
    }

    // Finish update
    final finalStatus = state.nodesStatus?.map((node) {
      if (nodesToUpdate.any((n) => n.deviceId == node.deviceId)) {
        return node.copyWith(
          currentFirmwareVersion: node.availableUpdate?.version,
          availableUpdate: null,
          operation: null,
          progressPercent: 0,
        );
      }
      return node;
    }).toList();

    state = state.copyWith(
      nodesStatus: finalStatus,
      isUpdating: false,
      isWaitingChildrenAfterUpdating: true,
    );
    
    await Future.delayed(const Duration(seconds: 5));
    state = state.copyWith(isWaitingChildrenAfterUpdating: false);
  }

  @override
  Future<void> fetchAvailableFirmwareUpdates() async {
    // In mock, we don't need to fetch anything.
    return Future.value();
  }
  
  @override
  int getAvailableUpdateNumber() {
    return state.nodesStatus?.where((s) => s.availableUpdate != null).length ?? 0;
  }

  @override
  bool isFailedCheckFirmwareUpdate() {
    return false;
  }

  @override
  Future<void> finishFirmwareUpdate() async {
    state = state.copyWith(isUpdating: false);
    return Future.value();
  }

  @override
  Future<void> setFirmwareUpdatePolicy(String policy) async {
    final newSettings = state.settings.copyWith(updatePolicy: policy);
    state = state.copyWith(settings: newSettings);
    return Future.value();
  }
}
