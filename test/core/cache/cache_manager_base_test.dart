// The fallback of the conditional import in linksys_cache_manager.dart, for a
// platform with neither dart:io nor dart:html. Every real build picks
// cache_manager_mobile.dart or cache_manager_web.dart instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cache/cache_manager_base.dart';

void main() {
  test('a platform without io or html has no cache', () {
    final cache = FlutterCacheManager();

    expect(cache.get, throwsUnimplementedError);
    expect(() => cache.set('{}'), throwsUnimplementedError);
  });
}
