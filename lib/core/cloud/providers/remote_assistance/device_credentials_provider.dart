import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';

/// Provides [DeviceCredentials] for Remote Assistance API calls.
///
/// Returns null if required data is not available (session not ready,
/// devices not loaded, or master node not found).
final deviceCredentialsProvider = Provider<DeviceCredentials?>((ref) {
  final session = ref.watch(sessionProvider);
  final devicesData = ref.watch(devicesDataProvider).valueOrNull;

  if (devicesData == null) return null;

  final deviceInfo = session.deviceInfo;
  if (deviceInfo == null) return null;

  // Get master node for MAC address (from nodeModels)
  final masterNode =
      devicesData.nodeModels.where((n) => n.isMaster).firstOrNull;
  if (masterNode == null) return null;

  // Get master device for hostsDeviceId (UUID) (from deviceModels)
  final masterDevice = devicesData.deviceModels.masterNode;
  if (masterDevice?.hostsDeviceId == null) return null;

  return DeviceCredentials(
    serialNumber: deviceInfo.serialNumber,
    macAddress: masterNode.deviceId,
    deviceUUID: masterDevice!.hostsDeviceId!,
  );
});
