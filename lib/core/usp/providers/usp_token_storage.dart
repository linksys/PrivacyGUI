import 'package:flutter/foundation.dart';

import 'usp_token_storage_stub.dart'
    if (dart.library.js_interop) 'usp_token_storage_web.dart';

/// Storage for USP session tokens.
///
/// On Web: uses sessionStorage (cleared when browser tab/window closes)
/// On other platforms: no-op (USP is only available on Web)
///
/// sessionStorage is preferred over localStorage because:
/// - Cleared when browser tab/window closes (security)
/// - Not shared across tabs (prevents session conflicts)
/// - Sufficient for page refresh recovery (main use case)
abstract class UspTokenStorage {
  factory UspTokenStorage() {
    if (kIsWeb) {
      return createUspTokenStorage();
    }
    return _StubTokenStorage();
  }

  /// Saves the token to storage.
  void save(String token);

  /// Loads the token from storage.
  /// Returns null if not found.
  String? load();

  /// Clears the token from storage.
  void clear();
}

/// No-op implementation for non-Web platforms.
class _StubTokenStorage implements UspTokenStorage {
  @override
  void save(String token) {}

  @override
  String? load() => null;

  @override
  void clear() {}
}
