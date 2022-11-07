import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_util;
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/cloud_const.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/util/storage.dart';
import 'dart:typed_data';
import '../util/logger.dart';

class AppIconManager {
  static const defaultIconSize = 96;

  WeakReference<image_util.Image>? _cached;
  final Map<String, Point> _iconKeys = {};
  final Map<String, image_util.Image> _iconCache = {};

  factory AppIconManager() {
    _singleton ??= AppIconManager._();
    return _singleton!;
  }

  AppIconManager._();

  static AppIconManager? _singleton;

  static AppIconManager instance() {
    return AppIconManager();
  }

  loadFullImage() async {
    if (_cached?.target == null) {
      File iconFile = File.fromUri(Storage.iconsFileUri);
      if (!iconFile.existsSync()) {
        await CloudEnvironmentManager().downloadResources(CloudResourceType.appIcons);
      }
      final image = image_util.decodeImage(iconFile.readAsBytesSync());
      if (image == null) {
        throw Exception('Cannot find icon data');
      }
      _cached = WeakReference(image);
    }
  }

  _loadIconKeys() async {
    if (_iconKeys.isNotEmpty) {
      logger.d('icon keys is not empty, ${_iconKeys.length}');
      return;
    }
    logger.d('icon keys is empty, check file cache...');
    await CloudEnvironmentManager().downloadResources(CloudResourceType.appIconKeys);
    File keyFile = File.fromUri(Storage.iconKeysFileUri);
    logger.d('icon keys is empty, start loading...');
    final keyStr = keyFile.readAsStringSync();
    Map<String, dynamic> appPosJson = jsonDecode(keyStr);
    _iconKeys
      ..clear()
      ..addAll(appPosJson
          .map((key, value) => MapEntry(key, Point(value['x'], value['y']))));
    logger.d('icon keys loaded! ${_iconKeys.length}');
  }

  Future<List<String>> getAppIds() async {
    await _loadIconKeys();
    return List.from(_iconKeys.keys);
  }

  bool isDefaultIcon(String appId) {
    if (!_iconKeys.containsKey(appId)) {
      return true;
    }
    final pt = _iconKeys[appId]!;
    return pt.x == 0 && pt.y == 0;
  }


  Future<Uint8List> getIconByte(String appId, {bool force = false}) async {
    if (!force && _iconCache.containsKey(appId)) {
      logger.d('found app icon on cache! $appId');
      return Uint8List.fromList(image_util.encodePng(_iconCache[appId]!));
    }
    Point pos = const Point(0, 0);
    await _loadIconKeys();
    if (_iconKeys.containsKey(appId)) {
      logger.d('get key on icon key map! $appId');
      pos = _iconKeys[appId]!;
    }

    await loadFullImage();
    if (_cached?.target == null) {
      throw Exception('Icon map image loading failed!');
    }
    final iconMapImage = _cached?.target;
    final cropped = image_util.copyCrop(iconMapImage!, pos.x.toInt(),
        pos.y.toInt(), defaultIconSize, defaultIconSize);
    logger.d('found app icon on icon Map! id:$appId, $pos, (${cropped.width},${cropped.height})');
    _iconCache[appId] = cropped;
    return Uint8List.fromList(image_util.encodePng(cropped));
  }
}
