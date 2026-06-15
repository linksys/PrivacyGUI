import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';

import 'health_dimension.dart';
import 'dimensions/devices_dimension.dart';
import 'dimensions/firmware_dimension.dart';
import 'dimensions/internet_dimension.dart';
import 'dimensions/security_dimension.dart';
import 'dimensions/system_dimension.dart';
import 'dimensions/wifi_dimension.dart';

/// Static registry of all available health dimensions.
///
/// Provides access to dimension instances without the overhead of
/// Provider/singleton patterns — dimensions are stateless and can
/// be instantiated on demand.
abstract final class HealthDimensions {
  /// All registered dimensions.
  static List<HealthDimension> get all => [
        InternetHealthDimension(),
        WifiHealthDimension(),
        DevicesHealthDimension(),
        SecurityHealthDimension(),
        SystemHealthDimension(),
        FirmwareHealthDimension(),
      ];

  /// Get dimension by type.
  static HealthDimension? byType(HealthDimensionType type) {
    for (final dim in all) {
      if (dim.type == type) return dim;
    }
    return null;
  }

  /// All SSE domains that any dimension watches.
  static Set<InvalidationDomain> get allWatchedDomains {
    final domains = <InvalidationDomain>{};
    for (final dim in all) {
      domains.addAll(dim.watchedDomains);
    }
    return domains;
  }

  /// Get dimensions that watch a specific SSE domain.
  static List<HealthDimension> getDimensionsWatching(
      InvalidationDomain domain) {
    return all.where((d) => d.watchedDomains.contains(domain)).toList();
  }
}
