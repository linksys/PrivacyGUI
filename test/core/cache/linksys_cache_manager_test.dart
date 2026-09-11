import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cache/cache_manager.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';

/// In-memory stand-in for the platform cache file.
class FakeCacheManager implements CacheManager {
  FakeCacheManager([this.content]);

  String? content;
  int getCount = 0;
  int setCount = 0;

  /// When set, [get] does not complete until the gate does, so a test can run
  /// code while a read is in flight.
  Completer<void>? gate;

  @override
  Future<String?> get() async {
    if (gate != null) {
      await gate!.future;
    }
    getCount++;
    return content;
  }

  @override
  Future<void> set(String value) async {
    setCount++;
    content = value;
  }

  Map<String, dynamic> get decoded =>
      content == null ? {} : jsonDecode(content!);
}

void main() {
  late FakeCacheManager backend;
  late LinksysCacheManager manager;

  setUp(() {
    backend = FakeCacheManager();
    manager = LinksysCacheManager.forTesting(backend);
  });

  group('loadCache', () {
    test('loads the entry that belongs to the given serial number', () async {
      backend.content = jsonEncode({
        'SN-A': {
          'getFoo': {'target': 'getFoo', 'cachedAt': 1, 'data': {}}
        },
        'SN-B': {
          'getBar': {'target': 'getBar', 'cachedAt': 2, 'data': {}}
        },
      });

      expect(await manager.loadCache(serialNumber: 'SN-B'), isTrue);
      expect(manager.data.keys, ['getBar']);
    });

    test('reports a miss and keeps no data when the device has no entry',
        () async {
      expect(await manager.loadCache(serialNumber: 'SN-B'), isFalse);
      expect(manager.data, isEmpty);
    });

    test('does not re-read the backend for a device that has no entry yet',
        () async {
      await manager.loadCache(serialNumber: 'SN-B');
      await manager.loadCache(serialNumber: 'SN-B');

      expect(backend.getCount, 1);
    });

    test('clears the in-memory data and skips the backend for an empty SN',
        () async {
      backend.content = jsonEncode({
        'SN-A': {
          'getFoo': {'target': 'getFoo', 'cachedAt': 1, 'data': {}}
        },
      });
      await manager.loadCache(serialNumber: 'SN-A');
      final readsAfterLoad = backend.getCount;

      expect(await manager.loadCache(serialNumber: ''), isFalse);
      expect(manager.data, isEmpty);
      expect(backend.getCount, readsAfterLoad);
    });
  });

  group('clearCache', () {
    test('persists the removal for a device that had no entry on disk',
        () async {
      await manager.loadCache(serialNumber: 'SN-B');
      manager.handleJNAPCached({'result': 'OK'}, 'getFoo', 'SN-B');
      expect(backend.decoded['SN-B'], contains('getFoo'));

      manager.clearCache('getFoo');

      expect(manager.data, isEmpty);
      expect(backend.decoded['SN-B'], isNot(contains('getFoo')));
    });

    test('leaves the entries of other devices untouched', () async {
      backend.content = jsonEncode({
        'SN-A': {
          'getFoo': {'target': 'getFoo', 'cachedAt': 1, 'data': {}}
        },
      });
      await manager.loadCache(serialNumber: 'SN-B');
      manager.handleJNAPCached({'result': 'OK'}, 'getBar', 'SN-B');

      manager.clearCache('getBar');

      expect(backend.decoded['SN-A'], contains('getFoo'));
      expect(backend.decoded['SN-B'], isNot(contains('getBar')));
    });
  });

  group('saveCache', () {
    test('skips a device whose cache is not the one held in memory', () async {
      backend.content = jsonEncode({
        'SN-A': {
          'getFoo': {'target': 'getFoo', 'cachedAt': 1, 'data': {}}
        },
        'SN-B': {
          'getBar': {'target': 'getBar', 'cachedAt': 2, 'data': {}}
        },
      });
      await manager.loadCache(serialNumber: 'SN-A');

      // Callers that take the serial number from the preferences can ask for a
      // device that has not been loaded yet.
      manager.saveCache('SN-B');

      expect(backend.decoded['SN-B'], contains('getBar'));
      expect(backend.decoded['SN-B'], isNot(contains('getFoo')));
    });

    test('adds to the stored entry when no cache has been loaded', () async {
      backend.content = jsonEncode({
        'SN-A': {
          'getFoo': {'target': 'getFoo', 'cachedAt': 1, 'data': {}},
          'getBaz': {'target': 'getBaz', 'cachedAt': 2, 'data': {}},
        },
      });
      // Logging out drops the in-memory data but keeps the file, and logging
      // back in caches JNAP responses before the device is loaded again.
      await manager.loadCache(serialNumber: 'SN-A');
      await manager.loadCache(serialNumber: '');

      manager.handleJNAPCached({'result': 'OK'}, 'getBar', 'SN-A');

      expect(backend.decoded['SN-A'].keys,
          containsAll(['getFoo', 'getBaz', 'getBar']));
    });

    test('a save made while a load is in flight belongs to the loaded device',
        () async {
      backend.content = jsonEncode({
        'SN-A': {
          'getFoo': {'target': 'getFoo', 'cachedAt': 1, 'data': {}}
        },
        'SN-B': {
          'getBar': {'target': 'getBar', 'cachedAt': 2, 'data': {}}
        },
      });
      await manager.loadCache(serialNumber: 'SN-A');

      final gate = Completer<void>();
      backend.gate = gate;
      final loading = manager.loadCache(serialNumber: 'SN-B');
      // The other device is not loaded yet, so this still belongs to SN-A.
      manager.clearCache('getFoo');
      gate.complete();
      await loading;

      expect(backend.decoded['SN-A'], isNot(contains('getFoo')));
      expect(backend.decoded['SN-B'], contains('getBar'));
    });
  });
}
