import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/page/wifi_settings/models/mlo_status.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_mesh_mlo_data_service.dart';

/// What the router reports for MLO, `Device.X_LINKSYS_Mesh.MLOStatus`
/// (linksys/FWDEV#201, #1692). Null where the router does not offer MLO
/// (`DeviceCapability.wifiMlo`), which is then never read.
///
/// Layer 1, not part of the WiFi Advanced tab's working copy: the status is
/// read-only, and it changes with what the **WiFi** tab edits — `Inactive`
/// means the bands' SSID, password or security do not allow MLO — so a value
/// held in the Advanced tab's page-entry snapshot would freeze while the user
/// fixes exactly that (constitution Article IV §4.2). The MLO card watches
/// this directly.
///
/// Not autoDispose, like the other L1 providers, and nothing pushes it: every
/// Wi-Fi write that can move it invalidates it once the write settles (the
/// WiFi tab's and Advanced tab's saves, the dashboard's network toggle and
/// channel change), and so does the Advanced tab's refresh. Invalidating is
/// also what clears a failed read, which would otherwise stay for the session.
final mloStatusProvider = FutureProvider<MloStatus?>((ref) async {
  if (!ref.watch(deviceCapabilitiesProvider).has(DeviceCapability.wifiMlo)) {
    return null;
  }
  return ref.read(uspMeshMloDataServiceProvider).fetchStatus();
});
