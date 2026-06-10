import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/cloud_const.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/di.dart';

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
    logger.d('[RA] Guardian URL: https://${config.guardianBaseUrl}');
    logger.d('[RA] USP Endpoint: ${config.uspEndpoint}');

    // Build the client using UspClientBuilder
    var builder = UspClientBuilderJS('https://${config.guardianBaseUrl}')
        .endpoint(config.uspEndpoint)
        .authToken(config.temporaryAccessToken);

    // Add client type ID header if provided
    if (config.clientTypeId != null && config.clientTypeId!.isNotEmpty) {
      builder = builder.extraHeader(kHeaderClientTypeId, config.clientTypeId!);
    }

    final jsClient = builder.build();
    final raClient = UspClient.fromBuilder(jsClient);

    // Replace the existing UspClient singleton
    if (getIt.isRegistered<UspClient>()) {
      logger.d('[RA] Unregistering existing UspClient');
      final oldClient = getIt<UspClient>();
      getIt.unregister<UspClient>();
      oldClient.dispose();
    }

    getIt.registerSingleton<UspClient>(raClient);
    logger.i('[RA] UspClient replaced with Guardian-proxied client');

    state = RemoteAssistanceState(
      isActive: true,
      config: config,
    );
  }

  /// Deactivates Remote Assistance mode.
  ///
  /// Note: This does NOT restore the original local UspClient.
  /// The app should navigate to login or restart for normal operation.
  void deactivate() {
    logger.i('[RA] Deactivating Remote Assistance');
    state = const RemoteAssistanceState();
  }
}

/// Provider for Remote Assistance state.
final remoteAssistanceProvider =
    NotifierProvider<RemoteAssistanceNotifier, RemoteAssistanceState>(
        RemoteAssistanceNotifier.new);
