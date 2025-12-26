import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:usp_client_core/usp_client_core.dart';

/// Riverpod provider for PollingManager.
///
/// The App layer controls the lifecycle of the PollingManager.
/// This provider should be accessed to pause/resume polling globally.
final pollingManagerProvider = Provider<PollingManager>((ref) {
  final manager = PollingManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});
