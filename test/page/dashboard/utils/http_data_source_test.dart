import 'package:privacy_gui/page/dashboard/widgets/package_widget_renderer.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // resolvePath
  // -----------------------------------------------------------------------
  group('resolvePath', () {
    test('resolves top-level key', () {
      final json = {'name': 'Alice'};
      expect(resolvePath(json, 'name'), 'Alice');
    });

    test('resolves nested key', () {
      final json = {
        'data': {'query': '1.2.3.4', 'city': 'Taipei'}
      };
      expect(resolvePath(json, 'data.query'), '1.2.3.4');
      expect(resolvePath(json, 'data.city'), 'Taipei');
    });

    test('resolves deeply nested key', () {
      final json = {
        'a': {
          'b': {
            'c': {'value': 42}
          }
        }
      };
      expect(resolvePath(json, 'a.b.c.value'), 42);
    });

    test('returns null for missing key', () {
      final json = {
        'data': {'city': 'Taipei'}
      };
      expect(resolvePath(json, 'data.missing'), isNull);
    });

    test('returns null for missing intermediate key', () {
      final json = {
        'data': {'city': 'Taipei'}
      };
      expect(resolvePath(json, 'missing.city'), isNull);
    });

    test('returns null when traversing non-map value', () {
      final json = {'data': 'not a map'};
      expect(resolvePath(json, 'data.nested'), isNull);
    });

    test('handles numeric values', () {
      final json = {
        'stats': {'speed': 100.5, 'count': 3}
      };
      expect(resolvePath(json, 'stats.speed'), 100.5);
      expect(resolvePath(json, 'stats.count'), 3);
    });

    test('handles boolean values', () {
      final json = {
        'status': {'enabled': true}
      };
      expect(resolvePath(json, 'status.enabled'), true);
    });

    test('handles list values', () {
      final json = {
        'data': {
          'items': [1, 2, 3]
        }
      };
      expect(resolvePath(json, 'data.items'), [1, 2, 3]);
    });
  });

  // -----------------------------------------------------------------------
  // applyMapping
  // -----------------------------------------------------------------------
  group('applyMapping', () {
    test('maps top-level keys', () {
      final json = {'ip': '1.2.3.4', 'city': 'Taipei'};
      final mapping = {'address': 'ip', 'location': 'city'};
      final result = applyMapping(json, mapping);
      expect(result, {'address': '1.2.3.4', 'location': 'Taipei'});
    });

    test('maps nested keys via dot-notation', () {
      final json = {
        'data': {'query': '1.2.3.4', 'city': 'Taipei', 'country': 'TW'}
      };
      final mapping = {
        'ip': 'data.query',
        'city': 'data.city',
        'country': 'data.country',
      };
      final result = applyMapping(json, mapping);
      expect(result, {
        'ip': '1.2.3.4',
        'city': 'Taipei',
        'country': 'TW',
      });
    });

    test('returns null for missing paths', () {
      final json = {
        'data': {'a': 1}
      };
      final mapping = {'x': 'data.a', 'y': 'data.missing'};
      final result = applyMapping(json, mapping);
      expect(result, {'x': 1, 'y': null});
    });

    test('handles empty mapping', () {
      final json = {'data': 'value'};
      final mapping = <String, String>{};
      final result = applyMapping(json, mapping);
      expect(result, isEmpty);
    });

    test('handles deeply nested paths', () {
      final json = {
        'response': {
          'result': {
            'speed': {'download': 95.5, 'upload': 42.1}
          }
        }
      };
      final mapping = {
        'download': 'response.result.speed.download',
        'upload': 'response.result.speed.upload',
      };
      final result = applyMapping(json, mapping);
      expect(result, {'download': 95.5, 'upload': 42.1});
    });

    test('preserves value types', () {
      final json = {
        'str': 'text',
        'num': 42,
        'dbl': 3.14,
        'flag': true,
        'arr': [1, 2],
        'obj': {'k': 'v'},
      };
      final mapping = {
        's': 'str',
        'n': 'num',
        'd': 'dbl',
        'f': 'flag',
        'a': 'arr',
        'o': 'obj',
      };
      final result = applyMapping(json, mapping);
      expect(result['s'], isA<String>());
      expect(result['n'], isA<int>());
      expect(result['d'], isA<double>());
      expect(result['f'], isA<bool>());
      expect(result['a'], isA<List>());
      expect(result['o'], isA<Map>());
    });
  });
}
