// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:privacy_gui/core/utils/logger.dart';

import 'usp_token_storage.dart';

/// Creates a Web-based token storage using sessionStorage.
UspTokenStorage createUspTokenStorage() => _WebTokenStorage();

/// Web implementation using browser sessionStorage.
class _WebTokenStorage implements UspTokenStorage {
  static const _key = 'usp_session_token';

  @override
  void save(String token) {
    try {
      _sessionStorage?.setItem(_key, token);
    } catch (e) {
      // sessionStorage may be unavailable (private browsing, quota exceeded, etc.)
      logger.w('[UspTokenStorage]: save failed: $e');
    }
  }

  @override
  String? load() {
    try {
      return _sessionStorage?.getItem(_key);
    } catch (e) {
      logger.w('[UspTokenStorage]: load failed: $e');
      return null;
    }
  }

  @override
  void clear() {
    try {
      _sessionStorage?.removeItem(_key);
    } catch (e) {
      logger.w('[UspTokenStorage]: clear failed: $e');
    }
  }

  /// Accessor for browser's sessionStorage object.
  _SessionStorage? get _sessionStorage {
    try {
      final storage = globalContext['sessionStorage'];
      if (storage == null || storage.isUndefinedOrNull) return null;
      return _SessionStorage(storage as JSObject);
    } catch (e) {
      return null;
    }
  }
}

/// Minimal wrapper around browser sessionStorage API.
class _SessionStorage {
  final JSObject _storage;

  _SessionStorage(this._storage);

  void setItem(String key, String value) {
    _storage.callMethod('setItem'.toJS, key.toJS, value.toJS);
  }

  String? getItem(String key) {
    final result = _storage.callMethod<JSAny?>('getItem'.toJS, key.toJS);
    if (result == null || result.isUndefinedOrNull) return null;
    return (result as JSString).toDart;
  }

  void removeItem(String key) {
    _storage.callMethod('removeItem'.toJS, key.toJS);
  }
}
