/// Transport seam for the USP data channel.
///
/// [UspTransport] is the low-level contract that [UspClient] talks to. It is
/// deliberately platform-agnostic (pure Dart types, no `dart:js_interop`) so it
/// can be imported unconditionally on every platform and implemented by:
///   - `UspClientWeb` (the real WASM client, on Web),
///   - the non-Web stub (throws), and
///   - alternate data sources (demo mode's in-Dart transport, E2E harnesses)
///     that swap the router for a local model without touching the production
///     WASM path.
///
/// The 13 members below are exactly the ones [UspClient] invokes on its backing
/// client (`_client.*`). `subscribe`/`unsubscribe` are intentionally excluded —
/// [UspClient] never routes those through the transport (it owns subscription
/// via SSE-or-polling); `free()` is reached only through [dispose].
///
/// Adding a member here forces every implementer to provide it, so the seam
/// cannot silently drift from what [UspClient] actually needs.
abstract interface class UspTransport {
  /// Whether the transport currently holds a valid session.
  bool get isAuthenticated;

  /// The current session token, or null when unauthenticated.
  String? get sessionToken;

  /// Authenticate with the given password.
  Future<void> login(String password);

  /// Drop the current session.
  Future<void> logout();

  /// Refresh the session token (Stage 1 reauth). When [token] is null the
  /// implementation uses its stored token.
  Future<void> refreshToken({String? token});

  /// Read the given TR-181 [paths]. Returns a flat path→value map; missing
  /// paths are simply absent from the result.
  Future<Map<String, String>> get(List<String> paths);

  /// Write the given [parameters] (path→value). Returns the unified USP result
  /// map ({success, result:{data, error?}}).
  Future<Map<String, dynamic>> set(
    Map<String, String> parameters, {
    bool allowPartial,
  });

  /// Write groups of {path, value} entries in sequence. Returns the unified
  /// USP result map.
  Future<Map<String, dynamic>> setOrdered(
    List<List<Map<String, String>>> parameterGroups, {
    bool allowPartial,
  });

  /// Add object instances. Each item is {path, params}. Returns the unified
  /// USP result map (created instance paths under result.data).
  Future<Map<String, dynamic>> add(
    List<Map<String, dynamic>> items, {
    bool allowPartial,
  });

  /// Delete the given object instance [paths]. Returns the unified USP result
  /// map.
  Future<Map<String, dynamic>> delete(
    List<String> paths, {
    bool allowPartial,
  });

  /// Invoke a USP OPERATE [command] with the given [args]. Returns the unified
  /// USP result map.
  Future<Map<String, dynamic>> operate(
    String command, {
    Map<String, String> args,
  });

  /// List the transport's active USP subscriptions.
  Future<List<Map<String, dynamic>>> listSubscriptions();

  /// Release any native resources held by the transport.
  void dispose();
}
