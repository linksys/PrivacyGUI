import '../models/device_feature.dart';

abstract class CapabilityRepository {
  /// Initializes capabilities by querying the device or loading local config.
  Future<void> initialize();

  /// Checks if a specific feature is supported.
  bool hasFeature(DeviceFeature feature);

  /// Checks if a raw TR-181 path is supported.
  bool hasPath(String path);
}
