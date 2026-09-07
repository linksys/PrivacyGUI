import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/cloud_const.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
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

  /// Guardian API origin — the host every USP-over-Guardian call must use:
  /// USP requests, subscriptions and SSE notifications.
  ///
  /// Must NOT be confused with the origin the web app is served from; the
  /// Guardian API lives on a different host (e.g. `qa.guardian.tools`).
  ///
  /// The session REST API ends up on the same host by construction — both this
  /// config ([RemoteAssistanceConfig.guardianBaseUrl], set from
  /// `cloudEnvironmentConfig[kCloudBase]`) and `GuardianApiClient._buildUrl`
  /// read that same entry — but it builds its URL independently.
  String get guardianOrigin {
    // Kept as an assert rather than a constructor assert: the constructor is
    // const, and const asserts only accept potentially-constant expressions.
    assert(!guardianBaseUrl.contains('://'),
        'guardianBaseUrl must be a bare host, without a scheme');
    return 'https://$guardianBaseUrl';
  }

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

  /// Activates Remote Assistance mode by pointing the app's [UspClient] at a
  /// Guardian-proxied connection.
  ///
  /// The connection is pre-authenticated via [config.temporaryAccessToken],
  /// so no password-based login is needed.
  ///
  /// **Idempotent by construction, and #1322 is why it has to be.** The first
  /// call registers the singleton; every later one re-points that same instance
  /// (`UspClient.rebindTransport`) rather than replacing it. A second
  /// `activate()` is reachable without any mode switch — an idle timeout or a
  /// `forceLogout` logs the user out while the Guardian session is still alive,
  /// the `/usp*` redirect rebuilds the confirm URL from `remoteAccessProvider`
  /// state, and one tap on Connect gets here again.
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

    // Swap the connection atomically with the mutation lock to prevent races
    await ref.read(uspMutationLockProvider).withLock(() async {
      if (getIt.isRegistered<UspClient>()) {
        // #1322: re-point the registered façade, do NOT free it. `dispose()`
        // reaches `free()` on the wasm-bindgen object and zeroes its
        // `__wbg_ptr`, and 41 call sites resolve this singleton with
        // `ref.read(uspClientProvider)` inside a non-autoDispose provider body —
        // bound into a service constructor once, never re-read. Replacing the
        // instance left all 41 pointed at freed memory, and every USP call
        // through them failed with `null pointer passed to rust` until the
        // browser was refreshed. Only the 11 `ref.watch` consumers followed the
        // swap.
        logger.d('[RA] Rebinding UspClient to the new Guardian session');
        getIt<UspClient>()
            .rebindFromBuilder(jsClient, baseUrl: config.guardianOrigin);
      } else {
        getIt.registerSingleton<UspClient>(
            UspClient.fromBuilder(jsClient, baseUrl: config.guardianOrigin));
        logger.i('[RA] Guardian-proxied UspClient registered');
      }

      // Invalidated in the same critical section as the swap, so "connection
      // changed" and "cache dropped" can never drift apart.
      //
      // uspClientProvider caches whatever GetIt held when it was FIRST read,
      // and authProvider.init() reads it during app boot — long before RA
      // activates. In a Remote build that first read now yields null
      // ([canUseAppOriginUspClient] keeps the boot slot empty), and this drops
      // that cached null so watchers pick the session client up.
      //
      // On a re-activation the rebuilt value is the *same* instance, so
      // `Provider` will not notify watchers — nothing here depends on it doing
      // so. SSE reconnect is driven by the new `config` object below, which
      // `uspBridgeClientProvider` watches; this invalidate exists for the
      // null → client transition and to re-attach the throttler.
      ref.invalidate(uspClientProvider);
    });

    // The credential was just replaced, so whatever the auth machinery cached
    // about the *previous* one has to go. Acceptance 9 of #1323: this is a
    // second activation's problem, and a second activation is reachable without
    // any mode switch (see the doc comment above). Asked of the mode rather than
    // done here, because the answer differs — a local re-login keeps its refresh
    // window, a new Guardian token invalidates it. See
    // `CredentialStrategy.onCredentialRebound`.
    ref.read(appModeProfileProvider).credential.onCredentialRebound(ref);

    // Set login type to remote so auth checks pass
    ref.read(authProvider.notifier).setLoginType(LoginType.remote);

    state = RemoteAssistanceState(
      isActive: true,
      config: config,
    );
  }

  // NO `deactivate()`. Removed by #1323 (phase 5), acceptance 10, and the
  // deletion is the fix rather than a tidy-up.
  //
  // It did `getIt.unregister<UspClient>()` then `client.dispose()`, which is
  // precisely the sequence #1322 had just been fixed for: `dispose()` reaches
  // `free()` on the wasm-bindgen object and zeroes its `__wbg_ptr`, while 41 call
  // sites hold the façade by value inside non-autoDispose provider bodies. Every
  // USP call through them then fails with `null pointer passed to rust` until the
  // browser is refreshed. `activate()` above was rewritten to *rebind* for exactly
  // that reason; leaving a public method that still frees it kept the loaded gun
  // on the table.
  //
  // It had **zero production callers** — measured across `lib/` — and its only
  // three references were tests that exercised it because `activate()` throws off
  // the web platform, so it was the one method reachable in the VM. Nothing
  // replaces it:
  //
  //   - *ending* a session is `RemoteSessionStrategy.end`, which clears
  //     `remoteAccessProvider` and lets `logout()` clear app auth. Neither touches
  //     the façade, and neither needs to: a dead Guardian token in a live client
  //     is harmless because nothing is authorised to use it;
  //   - *starting the next* session is `activate()`, which rebinds the same
  //     instance. So there is no state that a deactivate would have to reach
  //     first — the idempotence #1322 introduced is what made this method
  //     redundant, not just dangerous.
  //
  // The guard is `test/core/usp/providers/remote_assistance_provider_test.dart`'s
  // "no production path frees the registered UspClient façade", which scans `lib/`
  // rather than trusting this comment.
}

/// Provider for Remote Assistance state.
final remoteAssistanceProvider =
    NotifierProvider<RemoteAssistanceNotifier, RemoteAssistanceState>(
        RemoteAssistanceNotifier.new);
