const String cacheFileName = "dataCache";

abstract class CacheManager {
  Future<String?> get();
  Future<void> set(String value);
}