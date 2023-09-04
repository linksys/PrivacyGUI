import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/cache/cache_manager.dart';
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
  String lastSerialNumber = "";
  late int defaultCacheExpiration;
  Map<String, dynamic> data = {};
  String cache = "";
  late FlutterCacheManager cacheManager;

  void init() async {
    logger.d('Starting to init linksys cache manager');
    defaultCacheExpiration = 120000;
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
      data = jsonDecode(allCaches[serialNumber]);
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
      Map<String, String> cache = {serialNumber: jsonEncode(data)};
      cacheManager.set(jsonEncode(cache));
      return;
    }
    Map<String, dynamic> cacheModel = jsonDecode(cache);
    // has no serial number
    if (cacheModel[serialNumber] == null) {
      cacheModel[serialNumber] = '{}';
    }
    data.forEach((key, value) {
      jsonDecode(cacheModel[serialNumber])[key] = value;
    });
    cache = jsonEncode(cacheModel);
    // logger.d("linksys cache manager: save cache of $serialNumber : $cache");
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

  void cacheTransacationResults(
      Map<String, dynamic> result, String? serialNumber) {
    if (serialNumber == null) {
      result.forEach((key, value) {
        if (key == '/core/GetDeviceInfo') {
          serialNumber = jsonDecode(value)['serialNumber'];
        }
      });
    }
    if (serialNumber != null) {
      result.forEach((key, value) {
        var tmp = jsonDecode(value);
        tmp['cacheAt'] = DateTime.now().millisecondsSinceEpoch;
        data[key] = jsonEncode(tmp);
      });
    }
  }

  bool didCacheExpire(String action) {
    if (jsonDecode(data[action]) == null ||
        jsonDecode(data[action])["cachedAt"] == null ||
        DateTime.now().millisecondsSinceEpoch -
                int.parse(jsonDecode(data[action])["cachedAt"]) >=
            defaultCacheExpiration) {
      return true;
    } else {
      return false;
    }
  }

  Map<String, dynamic>? buildTransacationCachedResult(
      Map<String, dynamic> results) {
    Map<String, dynamic> result = {"result": "OK", "responses": ""};
    var expired = false;
    results.forEach((key, value) {
      if (data[key] != null) {
        var cachedResult = didCacheExpire(key);
        if (cachedResult != null) {
          expired = true;
        }
      }
      if (data[key] == null || expired) {
        return;
      }
      var temp = (result["responses"] as String) + jsonEncode(data[key]);
      result["responses"] = temp;
    });
    return result;
  }

  // Future<String> send(String action, String data, Map<String, String> options,
  //     String originalAction) async {
  //   if (options["serialNumber"] != null) {
  //     loadCache(serialNumber: options["serialNumber"]!);
  //   }
  //   String cachedResult = "";

  //   if (action == "/core/Transacation") {
  //     cachedResult = jsonEncode(buildTransacationCachedResult(data, data));
  //   }
  //   return cachedResult;
  // }
}
