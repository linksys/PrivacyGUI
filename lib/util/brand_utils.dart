import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:privacy_gui/core/utils/logger.dart';

enum BrandAsset {
  logo('brand_logo'),
  imgSup('brand_img_sup');

  final String filename;
  const BrandAsset(this.filename);
}

class BrandUtils {
  static Set<String>? _manifestAssets;

  static const Map<String, String> _modelSuffixMap = {
    'TB-': '_tb',
    'CF-': '_cf',
    'DU-': '_du',
  };

  static Future<void> _loadManifest() async {
    if (_manifestAssets != null) return;
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      logger.d('[Util]: Loaded AssetManifest.json: ${manifestMap.keys}');
      _manifestAssets = manifestMap.keys.toSet();
    } catch (e) {
      logger.e('[Util]: Failed to load AssetManifest.json', error: e);
      _manifestAssets = {};
    }
  }

  static Future<String?> getAssetPath(
      String modelNumber, BrandAsset asset) async {
    for (final entry in _modelSuffixMap.entries) {
      if (modelNumber.toUpperCase().contains(entry.key)) {
        return resolveAsset('assets/brand/${asset.filename}${entry.value}');
      }
    }
    return null;
  }

  static Future<String?> getBrandLogoAssetPath(String modelNumber) =>
      getAssetPath(modelNumber, BrandAsset.logo);

  static Future<String?> getBrandImgSupAssetPath(String modelNumber) =>
      getAssetPath(modelNumber, BrandAsset.imgSup);

  static Future<String?> resolveAsset(String basePath) async {
    await _loadManifest();

    final isDark = basePath.endsWith('_dark');
    final webp = '$basePath.webp';
    if (_manifestAssets!.contains(webp)) {
      return webp;
    }

    final png = '$basePath.png';
    if (_manifestAssets!.contains(png)) {
      return png;
    }

    if (isDark) {
      return resolveAsset(basePath.replaceFirst('_dark', ''));
    }
    return null;
  }
}
