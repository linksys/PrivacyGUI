import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/cloud_const.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// Configuration for Remote Assistance mode.
class RemoteAssistanceConfig {
  final String guardianBaseUrl;
  final String sessionId;
  final String temporaryAccessToken;
  final String? clientTypeId;

  const RemoteAssistanceConfig({
    required this.guardianBaseUrl,
    required this.sessionId,
    required this.temporaryAccessToken,
    this.clientTypeId,
  });

  /// Guardian API origin — the single host for ALL Remote Assistance traffic
  /// (session REST, USP requests, subscriptions, SSE notifications).
  ///
  /// Must NOT be confused with the origin the web app is served from; the
  /// Guardian API lives on a different host (e.g. `qa.guardian.tools`).
  String get guardianOrigin => 'https://$guardianBaseUrl';

  /// Constructs the Guardian USP endpoint path.
  String get uspEndpoint =>
      '/v1/guardians/remote-assistances/sessions/$sessionId/actions/usp';

  @override
  String toString() =>
      'RemoteAssistanceConfig(session=$sessionId, url=$guardianBaseUrl)';
}

/// State for Remote Assistance mode.
class RemoteAssistanceState {
  final bool isActive;
  final RemoteAssistanceConfig? config;

  const RemoteAssistanceState({
    this.isActive = false,
    this.config,
  });

  RemoteAssistanceState copyWith({
    bool? isActive,
    RemoteAssistanceConfig? config,
  }) =>
      RemoteAssistanceState(
        isActive: isActive ?? this.isActive,
        config: config ?? this.config,
      );

  @override
  String toString() =>
      'RemoteAssistanceState(active=$isActive, config=$config)';
}

/// Notifier for Remote Assistance mode.
///
/// Manages the lifecycle of a Remote Assistance session:
/// 1. Creates a UspClient configured for Guardian proxy
/// 2. Replaces the default UspClient singleton in GetIt
/// 3. Tracks session state for UI and routing decisions
class RemoteAssistanceNotifier extends Notifier<RemoteAssistanceState> {
  @override
  RemoteAssistanceState build() => const RemoteAssistanceState();

  /// Activates Remote Assistance mode by creating and registering
  /// a Guardian-proxied UspClient.
  ///
  /// The client is pre-authenticated via [config.temporaryAccessToken],
  /// so no password-based login is needed.
  Future<void> activate(RemoteAssistanceConfig config) async {
    if (!kIsWeb) {
      throw UnsupportedError('Remote Assistance is only supported on Web');
    }

    logger.i('[RA] Activating Remote Assistance: ${config.sessionId}');
    logger.d('[RA] Guardian URL: ${config.guardianOrigin}');
    logger.d('[RA] USP Endpoint: ${config.uspEndpoint}');

    // Build the client using UspClientBuilder
    var builder = UspClientBuilderJS(config.guardianOrigin)
        .endpoint(config.uspEndpoint)
        .authToken(config.temporaryAccessToken);

    // Add client type ID header if provided
    if (config.clientTypeId != null && config.clientTypeId!.isNotEmpty) {
      builder = builder.extraHeader(kHeaderClientTypeId, config.clientTypeId!);
    }

    final jsClient = builder.build();
    final raClient =
        UspClient.fromBuilder(jsClient, baseUrl: config.guardianOrigin);

    // Swap UspClient atomically with mutation lock to prevent races
    await ref.read(uspMutationLockProvider).withLock(() async {
      if (getIt.isRegistered<UspClient>()) {
        logger.d('[RA] Unregistering existing UspClient');
        final oldClient = getIt<UspClient>();
        getIt.unregister<UspClient>();
        oldClient.dispose();
      }
      getIt.registerSingleton<UspClient>(raClient);
      logger.i('[RA] UspClient replaced with Guardian-proxied client');
    });

    // Set login type to remote so auth checks pass
    ref.read(authProvider.notifier).setLoginType(LoginType.remote);

    state = RemoteAssistanceState(
      isActive: true,
      config: config,
    );

    // uspClientProvider caches whatever GetIt held when it was FIRST read
    // (authProvider.init() reads it during app boot, before RA activates).
    // Without this invalidation, every USP request and every bridge call keeps
    // using the disposed boot-time client — whose baseUrl is the web app's own
    // origin, not the Guardian API host.
    ref.invalidate(uspClientProvider);
  }

  /// Deactivates Remote Assistance mode.
  ///
  /// Disposes and unregisters the Guardian-proxied UspClient.
  /// The app should navigate to login or restart for normal operation.
  Future<void> deactivate() async {
    logger.i('[RA] Deactivating Remote Assistance');

    // Dispose the RA client if registered
    await ref.read(uspMutationLockProvider).withLock(() async {
      if (getIt.isRegistered<UspClient>()) {
        final client = getIt<UspClient>();
        getIt.unregister<UspClient>();
        client.dispose();
        logger.d('[RA] UspClient unregistered and disposed');
      }
    });

    state = const RemoteAssistanceState();

    // Drop the cached (now disposed) client so downstream providers tear down
    // instead of calling into freed WASM memory.
    ref.invalidate(uspClientProvider);
  }
}

/// Provider for Remote Assistance state.
final remoteAssistanceProvider =
    NotifierProvider<RemoteAssistanceNotifier, RemoteAssistanceState>(
        RemoteAssistanceNotifier.new);
