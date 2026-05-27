import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/turbo_session_manager.dart';

/// Provides [TurboSessionManager] for exclusive WebSocket access.
///
/// The turbo session manager handles:
/// - Starting/releasing turbo channel locks
/// - Automatic heartbeat maintenance
/// - SSE suspension during turbo operations
///
/// ## Usage
/// ```dart
/// final manager = ref.read(turboSessionManagerProvider);
/// if (manager != null) {
///   await manager.start();
///   try {
///     // Perform WebSocket operations
///   } finally {
///     await manager.release();
///   }
/// }
/// ```
final turboSessionManagerProvider = Provider<TurboSessionManager?>((ref) {
  final bridge = ref.watch(uspBridgeClientProvider);
  if (bridge == null) return null;

  final manager = TurboSessionManager(bridge);

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});
