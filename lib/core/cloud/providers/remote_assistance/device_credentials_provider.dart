import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
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

  // Get master node for MAC address and hostsDeviceId (UUID)
  final master = devicesData.master;
  // Master's hostsDeviceId comes from Hosts table during MeshNetwork build
  // For non-mesh routers, master.deviceId is 'GATEWAY' and no UUID is available
  if (master.deviceId == 'GATEWAY') return null;

  return DeviceCredentials(
    serialNumber: deviceInfo.serialNumber,
    macAddress: master.deviceId,
    deviceUUID: master.deviceId, // fallback - may need refinement
  );
});
