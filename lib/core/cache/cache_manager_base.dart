import 'cache_manager.dart';

class FlutterCacheManager implements CacheManager {
  @override
  Future<String?> get() => throw UnimplementedError('Unsupported Platform!');

  @override
  Future<void> set(String value) =>
      throw UnimplementedError('Unsupported Platform!');
}
