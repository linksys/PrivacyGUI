import 'package:privacy_gui/page/dashboard/utils/bind_resolver.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // $bind — existing behaviour (regression)
  // -----------------------------------------------------------------------
  group(r'$bind', () {
    test('resolves single value', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          'properties': {
            'text': {r'$bind': 'Device.WiFi.SSID.1.SSID'},
          },
        },
        {'Device.WiFi.SSID.1.SSID': 'MyNetwork'},
      );
      expect(result['props']?['text'], 'MyNetwork');
    });

    test('missing path returns --', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          'properties': {
            'text': {r'$bind': 'Device.Missing.Path'},
          },
        },
        {},
      );
      expect(result['props']?['text'], '--');
    });
  });

  // -----------------------------------------------------------------------
  // properties → props rename
  // -----------------------------------------------------------------------
  group('properties → props rename', () {
    test('renames properties to props', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          'properties': {'text': 'hello'},
        },
        {},
      );
      expect(result.containsKey('props'), isTrue);
      expect(result.containsKey('properties'), isFalse);
      expect(result['props']?['text'], 'hello');
    });
  });

  // -----------------------------------------------------------------------
  // children merge into props
  // -----------------------------------------------------------------------
  group('children merge into props', () {
    test('sibling children merged into props', () {
      final result = resolveBindings(
        {
          'type': 'AppCard',
          'properties': {'padding': 16},
          'children': [
            {'type': 'AppText', 'properties': {'text': 'Hello'}},
          ],
        },
        {},
      );
      expect(result.containsKey('children'), isFalse);
      final props = result['props'] as Map<String, dynamic>;
      expect(props['children'], isList);
      expect((props['children'] as List).length, 1);
    });
  });

  // -----------------------------------------------------------------------
  // $transform dispatch
  // -----------------------------------------------------------------------
  group(r'$transform dispatch', () {
    test('pipeline op in value position', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          'properties': {
            'text': {
              r'$transform': {
                'input': {r'$bind': 'Device.DeviceInfo.MemoryStatus.Total'},
                'ops': [
                  {'type': 'divide', 'by': 1048576},
                  {'type': 'round', 'precision': 0},
                  {'type': 'suffix', 'value': ' MB'},
                ],
              },
            },
          },
        },
        {'Device.DeviceInfo.MemoryStatus.Total': '2097152'},
      );
      expect(result['props']?['text'], '2.0 MB');
    });

    test('function mode in value position', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          'properties': {
            'text': {
              r'$transform': {
                'input': {r'$bind': 'Device.WiFi.Radio.1.MaxBitRate'},
                'fn': 'formatBandwidth',
              },
            },
          },
        },
        {'Device.WiFi.Radio.1.MaxBitRate': '600'},
      );
      expect(result['props']?['text'], '600.00 Mbps');
    });
  });

  // -----------------------------------------------------------------------
  // $compute dispatch
  // -----------------------------------------------------------------------
  group(r'$compute dispatch', () {
    test('percent_used', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          'properties': {
            'text': {
              r'$compute': {
                'op': 'percent_used',
                'total': {r'$bind': 'Device.Mem.Total'},
                'free': {r'$bind': 'Device.Mem.Free'},
              },
            },
          },
        },
        {'Device.Mem.Total': '1000', 'Device.Mem.Free': '250'},
      );
      expect(result['props']?['text'], '75.0');
    });

    test('template — WiFi QR string', () {
      final result = resolveBindings(
        {
          'type': 'AppQrCode',
          'properties': {
            'data': {
              r'$compute': {
                'op': 'template',
                'format': 'WIFI:T:{mode};S:{ssid};P:{pass};;',
                'values': {
                  'ssid': {r'$bind': 'Device.WiFi.SSID.1.SSID'},
                  'pass': {r'$bind': 'Device.WiFi.AP.1.Key'},
                  'mode': {r'$bind': 'Device.WiFi.AP.1.Mode'},
                },
              },
            },
          },
        },
        {
          'Device.WiFi.SSID.1.SSID': 'MyNetwork',
          'Device.WiFi.AP.1.Key': 'secret123',
          'Device.WiFi.AP.1.Mode': 'WPA2-Personal',
        },
      );
      expect(
        result['props']?['data'],
        'WIFI:T:WPA2-Personal;S:MyNetwork;P:secret123;;',
      );
    });
  });

  // -----------------------------------------------------------------------
  // $visible — node filtering
  // -----------------------------------------------------------------------
  group(r'$visible', () {
    test('visible=true keeps node', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          r'$visible': 'true',
          'properties': {'text': 'Shown'},
        },
        {},
      );
      expect(result.containsKey('_hidden'), isFalse);
      expect(result['type'], 'AppText');
    });

    test('visible=false returns _hidden sentinel', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          r'$visible': '',
          'properties': {'text': 'Hidden'},
        },
        {},
      );
      expect(result['_hidden'], isTrue);
      expect(result.containsKey('type'), isFalse);
    });

    test(r'visible with $bind — truthy value', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          r'$visible': {r'$bind': 'Device.X.Enabled'},
          'properties': {'text': 'Visible'},
        },
        {'Device.X.Enabled': 'true'},
      );
      expect(result.containsKey('_hidden'), isFalse);
      expect(result['type'], 'AppText');
    });

    test(r'visible with $bind — missing path → "--" → hidden', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          r'$visible': {r'$bind': 'Device.Missing'},
          'properties': {'text': 'Invisible'},
        },
        {},
      );
      expect(result['_hidden'], isTrue);
    });

    test('visible with condition — neq', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          r'$visible': {
            'condition': 'neq',
            'value': {r'$bind': 'Device.X.Status'},
            'expected': 'Disabled',
          },
          'properties': {'text': 'Active'},
        },
        {'Device.X.Status': 'Enabled'},
      );
      expect(result.containsKey('_hidden'), isFalse);
    });

    test(r'$visible stripped from output', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          r'$visible': 'true',
          'properties': {'text': 'Hello'},
        },
        {},
      );
      expect(result.containsKey(r'$visible'), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // List filtering — hidden children removed
  // -----------------------------------------------------------------------
  group('list filtering', () {
    test('hidden children filtered from list', () {
      final result = resolveBindings(
        {
          'type': 'Column',
          'properties': <String, dynamic>{},
          'children': [
            {
              'type': 'AppText',
              r'$visible': 'true',
              'properties': {'text': 'Shown'},
            },
            {
              'type': 'AppText',
              r'$visible': '',
              'properties': {'text': 'Hidden'},
            },
            {
              'type': 'AppText',
              'properties': {'text': 'Also shown'},
            },
          ],
        },
        {},
      );
      final children =
          (result['props'] as Map<String, dynamic>)['children'] as List;
      expect(children.length, 2);
      expect((children[0] as Map)['type'], 'AppText');
      expect((children[0] as Map)['props']?['text'], 'Shown');
      expect((children[1] as Map)['type'], 'AppText');
      expect((children[1] as Map)['props']?['text'], 'Also shown');
    });
  });

  // -----------------------------------------------------------------------
  // Nested directives
  // -----------------------------------------------------------------------
  group('nested directives', () {
    test(r'$compute containing $bind + $transform', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          'properties': {
            'text': {
              r'$compute': {
                'op': 'template',
                'format': '{mem} used',
                'values': {
                  'mem': {
                    r'$transform': {
                      'input': {r'$bind': 'Device.Mem.Used'},
                      'ops': [
                        {'type': 'suffix', 'value': ' MB'},
                      ],
                    },
                  },
                },
              },
            },
          },
        },
        {'Device.Mem.Used': '512'},
      );
      expect(result['props']?['text'], '512 MB used');
    });
  });

  // -----------------------------------------------------------------------
  // Edge cases
  // -----------------------------------------------------------------------
  group('edge cases', () {
    test('empty template — no bindings', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          'properties': {'text': 'Static text'},
        },
        {},
      );
      expect(result['props']?['text'], 'Static text');
    });

    test('primitives pass through unchanged', () {
      final result = resolveBindings(
        {
          'type': 'AppIcon',
          'properties': {
            'name': 'wifi',
            'size': 24,
            'filled': true,
          },
        },
        {},
      );
      final props = result['props'] as Map<String, dynamic>;
      expect(props['name'], 'wifi');
      expect(props['size'], 24);
      expect(props['filled'], isTrue);
    });

    test('null data map value returns --', () {
      final result = resolveBindings(
        {
          'type': 'AppText',
          'properties': {
            'text': {r'$bind': 'Device.X.Y'},
          },
        },
        {'Device.X.Y': null},
      );
      expect(result['props']?['text'], '--');
    });
  });
}
