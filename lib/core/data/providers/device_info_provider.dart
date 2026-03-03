import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/jnap_device_info_raw.dart';
import 'package:privacy_gui/core/jnap/models/soft_sku_settings.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_helpers.dart';
import 'package:privacy_gui/core/protocol/protocol_resolver.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';

/// USP async data source for DeviceInfo.
///
/// Returns null when USP is not available or not selected for deviceInfo.
/// Re-triggers on each polling cycle via [pollingProvider] watch.
final uspSystemInfoProvider = FutureProvider<SystemInfo?>((ref) async {
  final resolver = ref.watch(protocolResolverProvider);
  final usp = ref.watch(uspServiceProvider);
  if (!resolver.useUsp(ProtocolFeature.deviceInfo) || usp == null) return null;
  // Watch pollingProvider to re-trigger on each polling cycle
  ref.watch(pollingProvider);
  return SystemInfo.fetch(usp);
});

/// Dual-path device info provider.
///
/// When USP is selected for deviceInfo, reads from [uspSystemInfoProvider].
/// Otherwise falls back to JNAP polling data (unchanged behavior).
/// SKU is always fetched from JNAP polling (no USP equivalent).
final deviceInfoProvider = Provider<DeviceInfoState>((ref) {
  final resolver = ref.watch(protocolResolverProvider);
  NodeDeviceInfo? deviceInfo;

  if (resolver.useUsp(ProtocolFeature.deviceInfo)) {
    // USP path: read from async uspSystemInfoProvider
    final systemInfo = ref.watch(uspSystemInfoProvider).value;
    if (systemInfo != null) {
      deviceInfo = NodeDeviceInfo.fromUsp(systemInfo);
    }
    // When USP data is not yet ready, deviceInfo=null → UI shows '--'
    // (consistent with existing loading behavior)
  } else {
    // JNAP path (unchanged)
    final pollingData = ref.watch(pollingProvider).value;
    final deviceInfoOutput =
        getPollingOutput(pollingData, JNAPAction.getDeviceInfo);
    if (deviceInfoOutput != null) {
      deviceInfo = JnapDeviceInfoRaw.fromJson(deviceInfoOutput).toUIModel();
    }
  }

  // SKU is always fetched from JNAP polling (no USP equivalent)
  String? skuModelNumber;
  final pollingData = ref.watch(pollingProvider).value;
  final skuOutput =
      getPollingOutput(pollingData, JNAPAction.getSoftSKUSettings);
  if (skuOutput != null) {
    final settings = SoftSKUSettings.fromMap(skuOutput);
    skuModelNumber = settings.modelNumber;
  }

  return DeviceInfoState(
    deviceInfo: deviceInfo,
    skuModelNumber: skuModelNumber,
  );
});

class DeviceInfoState extends Equatable {
  final NodeDeviceInfo? deviceInfo;
  final String? skuModelNumber;

  const DeviceInfoState({
    this.deviceInfo,
    this.skuModelNumber,
  });

  @override
  List<Object?> get props => [deviceInfo, skuModelNumber];
}
