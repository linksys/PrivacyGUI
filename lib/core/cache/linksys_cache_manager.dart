import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'cache_manager.dart';
import 'cache_manager_base.dart'
    if (dart.library.io) 'cache_manager_mobile.dart'
    if (dart.library.html) 'cache_manager_web.dart';
import 'package:privacy_gui/core/utils/logger.dart';

enum DataSource { fromCache, fromRemote }

final linksysCacheManagerProvider = Provider((ref) => LinksysCacheManager());

class LinksysCacheManager {
  static LinksysCacheManager? _instance;
  LinksysCacheManager._() {
    init();
  }
  factory LinksysCacheManager() {
    _instance ??= LinksysCacheManager._();
    return _instance!;
  }

  /// An instance backed by [cacheManager] so tests can drive the cache without
  /// touching the platform file system. It is deliberately not installed as the
  /// singleton: each test gets its own instance and no state leaks between them.
  @visibleForTesting
  factory LinksysCacheManager.forTesting(CacheManager cacheManager) =>
      LinksysCacheManager._withBackend(cacheManager);

  LinksysCacheManager._withBackend(this.cacheManager) {
    defaultCacheExpiration = (BuildConfig.refreshTimeInterval * 1000) - 10000;
  }

  /// cache system can cache multiple devices via serial number.
  /// data variable is specific device cache map data.
  /// cache is plain text for data that used for saving in file.
  String lastSerialNumber = "";
  late int defaultCacheExpiration;
  Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => _data;
  String _cache = "";
  late CacheManager cacheManager;

  void init() async {
    logger.d('Starting to init linksys cache manager');
    defaultCacheExpiration = (BuildConfig.refreshTimeInterval * 1000) - 10000;
    cacheManager = FlutterCacheManager();
    _cache = await cacheManager.get() ?? "";
    logger.d('[CacheManager] init cache data: ${_cache.isNotEmpty}');
  }

  void clearCache(String action) {
    if (action.isNotEmpty) {
      if (data.isNotEmpty && data.keys.contains(action)) {
        logger.d('[CacheManager] remove cache data: $action');
        _data.remove(action);
      }
    } else {
      logger.d('[CacheManager] remove all cache data');
      _data = {};
    }

    if (lastSerialNumber.isNotEmpty) {
      saveCache(lastSerialNumber);
    }
  }

  Future<bool> loadCache({required String serialNumber}) async {
    logger.d("[CacheManager] load Cache with SN: $serialNumber");
    if (serialNumber.isEmpty) {
      // No device selected, so no cache belongs in memory either.
      logger.d("[CacheManager] No SN given. Drop the in-memory cache data");
      _data = {};
      lastSerialNumber = "";
      return false;
    }
    if (serialNumber != lastSerialNumber) {
      logger.d("[CacheManager] SN changed. Starting to load cache");
      final value = await cacheManager.get();
      _cache = value ?? "";
      // Claim the device as soon as its cache is in hand, whether or not it has
      // an entry yet - saveCache/clearCache rely on it to persist against the
      // right device. Claiming it any earlier would make a save that lands
      // while the read above is in flight write this device's entry with the
      // previous device's data.
      lastSerialNumber = serialNumber;
      if (_cache.isEmpty) {
        _data = {};
        return false;
      }
      final allCaches = jsonDecode(_cache);
      if (allCaches[serialNumber] == null) {
        _data = {};
        return false;
      }
      _data = allCaches[serialNumber];
      logger.d("[CacheManager] Load cache success for $serialNumber");
    }
    if (data.isEmpty) {
      return false;
    }
    return true;
  }

  void saveCache(String serialNumber) {
    logger.d("[CacheManager] Save cache for $serialNumber");
    if (serialNumber.isEmpty) {
      return;
    }
    if (lastSerialNumber.isNotEmpty && serialNumber != lastSerialNumber) {
      // The in-memory data belongs to lastSerialNumber, so writing it as
      // another device's entry would replace that device's cache with this
      // one's. Callers that take the serial number from the preferences can ask
      // for a device whose cache is not loaded yet, so drop the write instead.
      logger.d(
          "[CacheManager] Skip saving $serialNumber, cache belongs to $lastSerialNumber");
      return;
    }
    // From here on the serial number is either the loaded device or no device
    // has been loaded at all, which is what the write paths below tell apart.
    if (_cache.isEmpty) {
      cacheManager.get().then((value) {
        _cache = value ?? "";
      });
    }
    if (_cache.isEmpty) {
      Map<String, dynamic> cache = {serialNumber: data};
      cacheManager.set(jsonEncode(cache));
      return;
    }
    Map<String, dynamic> cacheModel = jsonDecode(_cache);
    if (serialNumber == lastSerialNumber) {
      // The in-memory data is the whole cache of this device, so replace its
      // entry instead of merging - a merge can never persist a removal made by
      // clearCache. Other devices keep their own entries.
      cacheModel[serialNumber] = data;
    } else {
      // No cache has been loaded, so the in-memory data is only part of this
      // device's cache: add to the stored entry instead of dropping whatever is
      // not in memory.
      final stored = Map<String, dynamic>.from(cacheModel[serialNumber] ?? {});
      stored.addAll(data);
      cacheModel[serialNumber] = stored;
    }
    _cache = jsonEncode(cacheModel);
    cacheManager.set(_cache);
  }

  Future<Map<String, dynamic>?> getCache(String? serialNumber) async {
    String sn = serialNumber ?? lastSerialNumber;
    final tempCache = await cacheManager.get();
    if (tempCache == null || tempCache.isEmpty) {
      logger.d('[CacheManager] no cache from $serialNumber');
      return null;
    }
    logger.d("[CacheManager] get cache of $serialNumber");
    return jsonDecode(tempCache)[sn];
  }

  String? getAllCaches() {
    cacheManager.get().then((value) {
      _cache = value ?? "";
    });
    return _cache;
  }

  bool didCacheExpire(String action, [int? expirationOverride]) {
    if (data[action] == null ||
        data[action]["cachedAt"] == null ||
        DateTime.now().millisecondsSinceEpoch - data[action]["cachedAt"] >=
            (expirationOverride ?? defaultCacheExpiration)) {
      return true;
    } else {
      return false;
    }
  }

  void handleJNAPCached(
    Map<String, dynamic> record,
    String action,
    String? serialNumber,
  ) {
    final dataResult = {
      "target": action,
      "cachedAt": DateTime.now().millisecondsSinceEpoch,
    };
    dataResult["data"] = record;
    data[action] = dataResult;
    if (serialNumber != null) {
      saveCache(serialNumber);
    }
  }

  bool checkCacheDataValid(String action, [int? expirationOverride]) {
    if (data.containsKey(action) &&
        data[action] != null &&
        !didCacheExpire(action, expirationOverride)) {
      return true;
    } else {
      return false;
    }
  }
}
