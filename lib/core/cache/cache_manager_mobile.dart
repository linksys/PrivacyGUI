import 'dart:io';

import 'package:linksys_app/core/cache/cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class FlutterCacheManager implements CacheManager {
  Directory? _cacheDir;

  @override
  Future<String?> get() async {
    final file = await _getFile();
    if (await file.exists()) {
      return file.readAsString();
    } else {
      return null;
    }
  }

  @override
  Future<void> set(String value) async {
    final file = await _getFile();
    await file.writeAsString(value);
  }

  Future<File> _getFile() async {
    _cacheDir ??= await getTemporaryDirectory();
    Uri uri = Uri.parse("${_cacheDir!.path}/$cacheFileName");
    File file = File.fromUri(uri);
    if (!file.existsSync()) {
      file.createSync();
    }
    return file;
  }
}
