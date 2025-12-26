import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/device_feature.dart';
import 'repositories/capability_repository.dart';

/// Riverpod provider for CapabilityRepository.
///
/// This provider must be overridden at app startup with the appropriate
/// repository implementation (UspCapabilityRepository or LocalCapabilityRepository).
///
/// Example:
/// ```dart
/// runApp(
///   ProviderScope(
///     overrides: [
///       capabilityRepositoryProvider.overrideWithValue(myRepository),
///     ],
///     child: MyApp(),
///   ),
/// );
/// ```
final capabilityRepositoryProvider = Provider<CapabilityRepository>((ref) {
  throw UnimplementedError(
    'capabilityRepositoryProvider must be overridden at app startup',
  );
});

/// Convenience provider for checking feature support.
///
/// Usage:
/// ```dart
/// final hasWifi = ref.watch(hasFeatureProvider(DeviceFeature.wifi5Hz));
/// ```
///
/// NOTE: When capabilityRepositoryProvider is not overridden (normal/demo mode),
/// this returns `true` for all features (unrestricted mode).
final hasFeatureProvider = Provider.family<bool, DeviceFeature>((ref, feature) {
  try {
    return ref.watch(capabilityRepositoryProvider).hasFeature(feature);
  } catch (_) {
    // Repository not overridden - assume all features are available (unrestricted mode)
    return true;
  }
});

/// Convenience provider for checking path support.
///
/// NOTE: When capabilityRepositoryProvider is not overridden,
/// this returns `true` for all paths (unrestricted mode).
final hasPathProvider = Provider.family<bool, String>((ref, path) {
  try {
    return ref.watch(capabilityRepositoryProvider).hasPath(path);
  } catch (_) {
    // Repository not overridden - assume all paths are available
    return true;
  }
});
