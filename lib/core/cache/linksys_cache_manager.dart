import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cache_manager_base.dart'
    if (dart.library.io) 'cache_manager_mobile.dart'
    if (dart.library.html) 'cache_manager_web.dart';
import 'package:linksys_app/core/utils/logger.dart';

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
  Map<String, dynamic> data = {};
  String cache = "";
  late FlutterCacheManager cacheManager;

  void init() async {
    logger.d('Starting to init linksys cache manager');
    defaultCacheExpiration = 110000;
    cacheManager = FlutterCacheManager();
    cache = await cacheManager.get() ?? "";
    logger.d('linksys cache manager: init cache data: $cache');
  }

  void clearCache(String action) {
    if (action.isNotEmpty) {
      if (data.isNotEmpty && data.keys.contains(action)) {
        logger.d('linksys cache manager: remove cache data: $action');
        data.remove(action);
      }
    } else {
      logger.d('linksys cache manager: remove all cache data');
      data = {};
    }

    if (lastSerialNumber.isNotEmpty) {
      saveCache(lastSerialNumber);
    }
  }

  bool loadCache({required String serialNumber}) {
    logger.d("linksys cache manager: Starting to load cache");
    if (serialNumber != lastSerialNumber) {
      cacheManager.get().then((value) {
        cache = value ?? "";
      });
      if (cache.isEmpty) {
        return false;
      }
      final allCaches = jsonDecode(cache);
      if (allCaches[serialNumber] == null) {
        return false;
      }
      data = allCaches[serialNumber];
      lastSerialNumber = serialNumber;
      logger.d(
          "linksys cache manager: Load cache success for $serialNumber : ${data.toString()}");
    }
    if (data.isEmpty) {
      return false;
    }
    return true;
  }

  void saveCache(String serialNumber) {
    logger.d("linksys cache manager: Save cache for $serialNumber");
    if (serialNumber.isEmpty) {
      return;
    }
    if (cache.isEmpty) {
      cacheManager.get().then((value) {
        cache = value ?? "";
      });
    }
    if (cache.isEmpty) {
      Map<String, dynamic> cache = {serialNumber: data};
      cacheManager.set(jsonEncode(cache));
      return;
    }
    Map<String, dynamic> cacheModel = jsonDecode(cache);
    // has no serial number, init it
    if (cacheModel[serialNumber] == null) {
      cacheModel[serialNumber] = {};
    }
    data.forEach((key, value) {
      cacheModel[serialNumber][key] = value;
    });
    cache = jsonEncode(cacheModel);
    cacheManager.set(cache);
  }

  String? getCache(String? serialNumber) {
    String? sn = serialNumber ?? lastSerialNumber;
    cacheManager.get().then((value) {
      cache = value ?? "";
    });
    logger.d("linksys cache manager: get cache of $serialNumber");
    return jsonDecode(cache)[sn];
  }

  String? getAllCaches() {
    cacheManager.get().then((value) {
      cache = value ?? "";
    });
    return cache;
  }

  bool didCacheExpire(String action) {
    if (data[action] == null ||
        data[action]["cachedAt"] == null ||
        DateTime.now().millisecondsSinceEpoch - data[action]["cachedAt"] >=
            defaultCacheExpiration) {
      return true;
    } else {
      return false;
    }
  }
}
