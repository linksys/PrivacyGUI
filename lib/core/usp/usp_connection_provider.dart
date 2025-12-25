/// USP Connection Providers
///
/// Riverpod providers for managing USP/gRPC connection state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:usp_client_core/usp_client_core.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Provider for USP connection configuration.
///
/// This is a StateProvider so that UI can update the config.
final uspConnectionConfigProvider = StateProvider<UspConnectionConfig?>((ref) {
  return null;
});

/// Provider for the USP gRPC client service.
///
/// This is a singleton service instance.
final uspGrpcServiceProvider = Provider<UspGrpcClientService>((ref) {
  final service = UspGrpcClientService();

  // Cleanup on dispose
  ref.onDispose(() {
    service.disconnect();
  });

  return service;
});

/// Provider for USP connection state.
///
/// Manages the lifecycle of the gRPC connection.
final uspConnectionStateProvider =
    StateNotifierProvider<UspConnectionNotifier, AsyncValue<bool>>((ref) {
  return UspConnectionNotifier(ref);
});

/// Notifier for managing USP connection state.
class UspConnectionNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;

  UspConnectionNotifier(this._ref) : super(const AsyncValue.data(false));

  /// Connects to the USP Agent with the given configuration.
  Future<void> connect(UspConnectionConfig config) async {
    state = const AsyncValue.loading();

    try {
      final service = _ref.read(uspGrpcServiceProvider);
      await service.connect(config);

      // Update the config provider
      _ref.read(uspConnectionConfigProvider.notifier).state = config;

      state = const AsyncValue.data(true);
      logger.i('🔌 USP: Connection state updated to connected');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      logger.e('❌ USP: Connection state error: $e');
    }
  }

  /// Disconnects from the USP Agent.
  Future<void> disconnect() async {
    try {
      final service = _ref.read(uspGrpcServiceProvider);
      await service.disconnect();

      _ref.read(uspConnectionConfigProvider.notifier).state = null;

      state = const AsyncValue.data(false);
      logger.i('🔌 USP: Connection state updated to disconnected');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Whether the client is currently connected.
  bool get isConnected => state.valueOrNull ?? false;
}
