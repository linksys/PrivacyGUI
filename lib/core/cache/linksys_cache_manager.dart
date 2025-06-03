import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
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

  /// cache system can cache multiple devices via serial number.
  /// data variable is specific device cache map data.
  /// cache is plain text for data that used for saving in file.
  String lastSerialNumber = "";
  late int defaultCacheExpiration;
  Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => _data;
  String _cache = "";
  late FlutterCacheManager cacheManager;

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
    if (serialNumber != lastSerialNumber) {
    logger.d("[CacheManager] SN changed. Starting to load cache");
      final value = await cacheManager.get();
      _cache = value ?? "";
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
      lastSerialNumber = serialNumber;
      logger.d(
          "[CacheManager] Load cache success for $serialNumber : ${data.toString()}");
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
    // has no serial number, init it
    if (cacheModel[serialNumber] == null) {
      cacheModel[serialNumber] = {};
    }
    data.forEach((key, value) {
      cacheModel[serialNumber][key] = value;
    });
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
