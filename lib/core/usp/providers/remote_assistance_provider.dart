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

    // Built outside the lock on purpose — wasm construction does not race with
    // anything — but from here on the handle has exactly one reference, so
    // [installTransport] owns getting rid of it if installation fails.
    await installTransport(builder.build(), config.guardianOrigin);

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

  /// Point the app's `UspClient` singleton at [jsClient], or release [jsClient] if
  /// that fails.
  ///
  /// **The release half is #1322's remaining edge, folded in here by #1474 phase
  /// 9.** `activate()` builds the wasm client before taking the mutation lock, so
  /// the only reference to a live wasm-bindgen object is the local variable it
  /// hands over. If the critical section threw, that variable went out of scope
  /// with the object still allocated and nothing left to call `free()` on — a leak
  /// per failed attempt, on the exact path a user retries. #1322 fixed the
  /// *opposite* mistake (freeing a handle 41 services still held); this is the same
  /// ownership question read the other way.
  ///
  /// Extracted from `activate()` rather than inlined so the discipline is testable:
  /// `activate()` refuses to run off the web platform on its first line, and the
  /// ownership rule is platform-independent. In the VM both installation paths fail
  /// at their own `kIsWeb` guard, which is a truthful "installation threw" without
  /// a mock.
  ///
  /// [baseUrl] is the Guardian origin, kept as a parameter because the release path
  /// needs it too.
  ///
  /// Two signature details, both of which read as mistakes without their reason.
  /// `@visibleForTesting` is about **visibility, not callers** — this is a
  /// production step, called from [activate] above, and the annotation says only
  /// that it would otherwise be private. And `jsClient` is `dynamic` because it is:
  /// the wasm-bindgen type exists only on the web, so `UspClient.fromBuilder` and
  /// `rebindFromBuilder` both already declare it that way and this signature
  /// matches theirs rather than inventing a third shape. A stricter type here would
  /// have to be a conditional export, which is a bigger change than this phase.
  @visibleForTesting
  Future<void> installTransport(dynamic jsClient, String baseUrl) async {
    // Ownership of [jsClient] passes to a `UspClient` the moment one wraps it, and
    // "the call returned" is exactly that moment — for the rebind path *because
    // `rebindTransport` guarantees it*, not because its body happens to look safe.
    // It assigns the new transport on its first line and every call-out after that
    // assignment is inside a `catch`, so it cannot both take the handle and throw.
    // That guarantee is stated on `rebindTransport`'s doc as a contract, and it was
    // made one by this phase: before, only the final `previous.dispose()` was
    // guarded, so a throw from the reauth gate or the throttler would have landed
    // here as `handleOwned == false` and freed the handle the registered façade had
    // just taken. Do not weaken either side without reading the other.
    var handleOwned = false;

    // A façade that owns the handle but that nothing else can reach yet. Only the
    // registration path can produce one, and only between constructing it and
    // handing it to GetIt.
    // Named to avoid the substring `unregister`, which
    // `remote_assistance_swap_guard_test.dart` bans outright in this file — and
    // rightly: `unregister` + `registerSingleton` is exactly the swap #1322 was.
    UspClient? pendingFacade;

    try {
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
          getIt<UspClient>().rebindFromBuilder(jsClient, baseUrl: baseUrl);
          handleOwned = true;
        } else {
          final client = UspClient.fromBuilder(jsClient, baseUrl: baseUrl);
          handleOwned = true;
          pendingFacade = client;
          getIt.registerSingleton<UspClient>(client);
          pendingFacade = null;
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
        // so. SSE reconnect is driven by the new `config` object, which
        // `uspBridgeClientProvider` watches; this invalidate exists for the
        // null → client transition and to re-attach the throttler.
        ref.invalidate(uspClientProvider);
      });
    } catch (_) {
      // Exactly one of these can fire, and at most once: either no façade ever
      // took the handle, or one did and is unreachable. A rebind that succeeded and
      // then failed later needs neither — the registered façade owns the handle and
      // is still the one 41 services hold.
      //
      // Guarded, because the cleanup must not become the error the caller sees.
      // Both branches reach interop — `UspClient.fromBuilder` and `dispose()` — so a
      // handle that is already dead, or that was never a wasm object, throws from in
      // here. The confirm view turns whatever comes out of this into its "Connection
      // failed" copy, and a `NoSuchMethodError` from the tidy-up in place of the
      // Guardian's actual rejection is a support call about the wrong thing. A leaked
      // handle is the lesser failure and it is already the one we are recovering
      // from.
      try {
        if (!handleOwned) {
          releaseOrphanedHandle(jsClient, baseUrl);
        } else {
          pendingFacade?.dispose();
        }
      } catch (e) {
        logger.w('[RA] Failed to release the unused Guardian client: $e');
      }
      rethrow;
    }
  }

  /// Free a wasm handle that no `UspClient` ever took ownership of.
  ///
  /// Wrapping it in a throwaway façade is how a caller outside
  /// `lib/core/usp/services/` frees one at all: `UspClientWeb` is private to that
  /// library by design ("transport construction has to happen inside this
  /// library"), and `dispose()` is the public route to its `free()`.
  ///
  /// Overridable so a test can count the releases without a wasm runtime — the
  /// property under test is "exactly once", not "via interop". A subclass plus a
  /// provider override, not a mutable static: #1474's criterion 2 is that a mode or
  /// lifecycle test needs no global and no `tearDown`.
  @visibleForTesting
  @protected
  void releaseOrphanedHandle(dynamic jsClient, String baseUrl) {
    logger.w('[RA] Installation failed; releasing the unused Guardian client');
    UspClient.fromBuilder(jsClient, baseUrl: baseUrl).dispose();
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
