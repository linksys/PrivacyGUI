import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';

import 'health_dimension.dart';
import 'dimensions/devices_dimension.dart';
import 'dimensions/firmware_dimension.dart';
import 'dimensions/internet_dimension.dart';
import 'dimensions/security_dimension.dart';
import 'dimensions/system_dimension.dart';
import 'dimensions/wifi_dimension.dart';

/// Registry of all available health dimensions.
///
/// This is the single source of truth for which dimensions are evaluated.
/// To add a new dimension:
/// 1. Create a class extending [HealthDimension]
/// 2. Add an instance to [_defaultDimensions]
final healthDimensionRegistryProvider =
    Provider<HealthDimensionRegistry>((ref) {
  return HealthDimensionRegistry();
});

class HealthDimensionRegistry {
  final List<HealthDimension> _dimensions = [];

  HealthDimensionRegistry() {
    _registerDefaults();
  }

  void _registerDefaults() {
    register(InternetHealthDimension());
    register(WifiHealthDimension());
    register(DevicesHealthDimension());
    register(SecurityHealthDimension());
    register(SystemHealthDimension());
    register(FirmwareHealthDimension());
  }

  /// Register a new dimension.
  void register(HealthDimension dimension) {
    final existing = _dimensions.indexWhere((d) => d.type == dimension.type);
    if (existing >= 0) {
      _dimensions[existing] = dimension;
    } else {
      _dimensions.add(dimension);
    }
  }

  /// Unregister a dimension by type.
  void unregister(HealthDimensionType type) {
    _dimensions.removeWhere((d) => d.type == type);
  }

  /// All registered dimensions.
  List<HealthDimension> get dimensions => List.unmodifiable(_dimensions);

  /// Get dimension by type.
  HealthDimension? getDimension(HealthDimensionType type) {
    try {
      return _dimensions.firstWhere((d) => d.type == type);
    } catch (_) {
      return null;
    }
  }

  /// All SSE domains that any dimension watches.
  Set<InvalidationDomain> get allWatchedDomains {
    final domains = <InvalidationDomain>{};
    for (final dim in _dimensions) {
      domains.addAll(dim.watchedDomains);
    }
    return domains;
  }

  /// Get dimensions that watch a specific SSE domain.
  List<HealthDimension> getDimensionsWatching(InvalidationDomain domain) {
    return _dimensions.where((d) => d.watchedDomains.contains(domain)).toList();
  }
}
