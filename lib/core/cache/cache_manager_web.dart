// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:privacy_gui/core/cache/cache_manager.dart';

class FlutterCacheManager implements CacheManager {
  final Storage _localStorage = window.localStorage;
  static const _key = 'cached_data';
  @override
  Future<String?> get() {
    final data = Future.value(
        _localStorage.containsKey(_key) ? _localStorage[_key] : null);
    return data;
  }

  @override
  Future<void> set(String value) async {
    _localStorage[_key] = value;
  }
}
