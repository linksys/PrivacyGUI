import 'package:flutter/foundation.dart';
import 'package:usp_client_core/usp_client_core.dart';
import '../models/device_feature.dart';
import 'capability_repository.dart';

class UspCapabilityRepository implements CapabilityRepository {
  // Now we rely on the Core Service from the package
  final UspCapabilityService _capabilityService;

  /// Expects a UspCapabilityService instance.
  /// We can construct it here or pass it in. passing UspGrpcClientService
  /// allows maintaining the same DI signature for now.
  UspCapabilityRepository(UspGrpcClientService grpcService)
      : _capabilityService = UspCapabilityService(grpcService);

  @override
  Future<void> initialize() async {
    debugPrint('🔍 CapabilityDiscovery: Delegating to Core Service...');
    await _capabilityService.initialize();
  }

  @override
  bool hasFeature(DeviceFeature feature) {
    switch (feature) {
      case DeviceFeature.wifi5Hz:
        return hasPath('Device.WiFi.');

      case DeviceFeature.guestNetwork:
        return hasPath('Device.WiFi.SSID.');

      case DeviceFeature.parentalControl:
        return hasPath('Device.X_LINKSYS_ParentalControl.') ||
            hasPath('Device.ParentalControl.');

      case DeviceFeature.rebootEvent:
        return hasPath('Device.Boot!');

      case DeviceFeature.firewall:
        return hasPath('Device.Firewall.');

      case DeviceFeature.mesh:
        return hasPath('Device.WiFi.DataElements.');

      case DeviceFeature.diagnostics:
        return hasPath('Device.IP.Diagnostics.');

      case DeviceFeature.vpn:
        return hasPath('Device.X_LINKSYS_VPN.') || hasPath('Device.VPN.');
    }
  }

  @override
  bool hasPath(String path) {
    return _capabilityService.isPathSupported(path);
  }
}
