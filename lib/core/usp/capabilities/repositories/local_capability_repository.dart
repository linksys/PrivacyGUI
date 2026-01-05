import 'package:flutter/foundation.dart';
import '../models/device_feature.dart';
import 'capability_repository.dart';

class LocalCapabilityRepository implements CapabilityRepository {
  final Set<DeviceFeature> _enabledFeatures;

  LocalCapabilityRepository({
    Set<DeviceFeature>? features,
  }) : _enabledFeatures = features ??
            {
              DeviceFeature.wifi5Hz,
              DeviceFeature.guestNetwork,
              DeviceFeature.parentalControl,
              DeviceFeature.firewall,
              DeviceFeature.diagnostics,
              // Reboot event not supported in local/mock usually? Or maybe yes.
            };

  @override
  Future<void> initialize() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint(
        '✅ LocalCapabilityRepository: Initialized with ${_enabledFeatures.length} features.');
  }

  @override
  bool hasFeature(DeviceFeature feature) {
    return _enabledFeatures.contains(feature);
  }

  @override
  bool hasPath(String path) {
    // Mock implementation: return true for standard paths
    if (path.startsWith('Device.WiFi.')) return true;
    if (path.startsWith('Device.Firewall.')) return true;
    if (path.startsWith('Device.DeviceInfo.')) return true;
    return false;
  }
}
