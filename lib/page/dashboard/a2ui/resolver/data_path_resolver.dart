import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract interface for resolving data paths to values.
///
/// This abstraction layer allows different data sources (JNAP, USP, etc.)
/// to be used interchangeably for A2UI data binding.
abstract class DataPathResolver {
  /// Resolves a data path and returns the current value.
  ///
  /// [path] - Dot-separated path (e.g., 'router.deviceCount')
  ///
  /// Returns null if the path is not recognized or the value is unavailable.
  dynamic resolve(String path);

  /// Returns a provider that can be watched for reactive updates.
  ///
  /// [path] - Dot-separated path (e.g., 'router.deviceCount')
  ///
  /// Returns null if the path doesn't support watching.
  ProviderListenable<dynamic>? watch(String path);
}
