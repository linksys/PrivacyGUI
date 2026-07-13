import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// Single source of truth for "is the USP layer authorized to serve data".
///
/// - Local login: `usp.isAuthenticated` is true.
/// - Remote Assistance: the client is pre-authorized via authToken, so
///   `usp.isAuthenticated` stays false by design; RA counts as ready via
///   [AuthState.isRemoteAssistance].
///
/// IMPORTANT: read this at the decision point (`ref.read` at fetch/guard time).
/// [UspClient.isAuthenticated] is a plain getter that does NOT trigger Riverpod
/// invalidation when it flips, so this provider is only recomputed when the
/// auth state or the client *instance* changes — not when `isAuthenticated`
/// flips underneath a stable client. Consumers that themselves mutate auth
/// state (e.g. the dashboard orchestrator's `restoreSession`) must re-read
/// `usp.isAuthenticated` directly rather than rely on this provider's cache.
final uspAuthReadyProvider = Provider<bool>((ref) {
  final isRemoteAssistance =
      ref.watch(authProvider).value?.isRemoteAssistance ?? false;
  if (isRemoteAssistance) return true;
  return ref.watch(uspClientProvider)?.isAuthenticated ?? false;
});
