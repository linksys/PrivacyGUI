import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_util;
import 'package:linksys_moab/constants/cloud_const.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/util/storage.dart';

import 'logger.dart';

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

  _loadFullImage() async {
    if (_cached?.target == null) {
      String iconFilePath =
          '${Storage.tempDirectory?.path}/sprite-icons-map.png';
      File iconFile = File(iconFilePath);
      if (!iconFile.existsSync()) {
        await _fetchFromCloud();
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
    logger.d('icon keys is empty, start loading...');
    final keyStr =
        await rootBundle.loadString('assets/resources/icon-keys.json');
    Map<String, dynamic> appPosJson = jsonDecode(keyStr);
    _iconKeys
      ..clear()
      ..addAll(appPosJson
          .map((key, value) => MapEntry(key, Point(value['x'], value['y']))));
    logger.d('icon keys loaded! ${_iconKeys.length}');
  }

  _fetchFromCloud() async {
    MoabHttpClient _client = MoabHttpClient();
    await _client.download(Uri.parse(appIconsUrl), Storage.iconFileUri);
  }

  Future<List<String>> getAppIds() async {
    await _loadIconKeys();
    return List.from(_iconKeys.keys);
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

    await _loadFullImage();
    if (_cached?.target == null) {
      throw Exception('Icon map image loading failed!');
    }
    final iconMapImage = _cached?.target;
    final cropped = image_util.copyCrop(iconMapImage!, pos.x.toInt(),
        pos.y.toInt(), defaultIconSize, defaultIconSize);
    logger.d('found app icon on icon Map! $appId, $pos, (${cropped.width},${cropped.height})');
    _iconCache[appId] = cropped;
    return Uint8List.fromList(image_util.encodePng(cropped));
  }
}
