import 'package:privacy_gui/page/dashboard/utils/template_directives.dart';
import 'package:test/test.dart';

/// Stub resolve function — mimics `_resolveValue` with a simple data map.
dynamic _resolve(Map<String, dynamic> dataMap) {
  dynamic resolver(dynamic value) {
    if (value is Map<String, dynamic> && value.containsKey(r'$bind')) {
      return dataMap[value[r'$bind']]?.toString() ?? '--';
    }
    return value;
  }

  return resolver;
}

void main() {
  // -----------------------------------------------------------------------
  // $transform — Function mode
  // -----------------------------------------------------------------------
  group(r'$transform — function mode', () {
    test('formatBandwidth — Mbps', () {
      final result = evaluateTransform(
        {'input': '150', 'fn': 'formatBandwidth'},
        (v) => v,
      );
      expect(result, '150.00 Mbps');
    });

    test('formatBandwidth — Gbps', () {
      final result = evaluateTransform(
        {'input': '2400', 'fn': 'formatBandwidth'},
        (v) => v,
      );
      expect(result, '2.40 Gbps');
    });

    test('formatBandwidth — custom precision', () {
      final result = evaluateTransform(
        {'input': '150', 'fn': 'formatBandwidth', 'precision': 0},
        (v) => v,
      );
      expect(result, '150 Mbps');
    });

    test('formatBytes', () {
      final result = evaluateTransform(
        {'input': 1073741824, 'fn': 'formatBytes'},
        (v) => v,
      );
      expect(result, '1.0 GB');
    });

    test('formatDuration', () {
      final result = evaluateTransform(
        {'input': 5445, 'fn': 'formatDuration'},
        (v) => v,
      );
      expect(result, '1h 30m 45s');
    });

    test('formatPercent', () {
      final result = evaluateTransform(
        {'input': '85.67', 'fn': 'formatPercent'},
        (v) => v,
      );
      expect(result, '85.7%');
    });

    test('formatNumber', () {
      final result = evaluateTransform(
        {'input': '1234567', 'fn': 'formatNumber'},
        (v) => v,
      );
      expect(result, '1,234,567');
    });

    test('formatSpeed — Kbps', () {
      final result = evaluateTransform(
        {'input': '500', 'fn': 'formatSpeed'},
        (v) => v,
      );
      expect(result, '500.00 Kbps');
    });

    test('cidrToNetmask', () {
      final result = evaluateTransform(
        {'input': 24, 'fn': 'cidrToNetmask'},
        (v) => v,
      );
      expect(result, '255.255.255.0');
    });

    test('unknown fn returns input string', () {
      final result = evaluateTransform(
        {'input': 'hello', 'fn': 'nonExistentFn'},
        (v) => v,
      );
      expect(result, 'hello');
    });

    test(r'resolves nested $bind for input', () {
      final resolve = _resolve({'Device.WiFi.Radio.1.MaxBitRate': '600'});
      final result = evaluateTransform(
        {
          'input': {r'$bind': 'Device.WiFi.Radio.1.MaxBitRate'},
          'fn': 'formatBandwidth',
        },
        resolve,
      );
      expect(result, '600.00 Mbps');
    });
  });

  // -----------------------------------------------------------------------
  // $transform — Pipeline mode
  // -----------------------------------------------------------------------
  group(r'$transform — pipeline mode', () {
    test('divide → round → suffix', () {
      final result = evaluateTransform(
        {
          'input': '2097152',
          'ops': [
            {'type': 'divide', 'by': 1048576},
            {'type': 'round', 'precision': 0},
            {'type': 'suffix', 'value': ' MB'},
          ],
        },
        (v) => v,
      );
      expect(result, '2.0 MB');
    });

    test('multiply', () {
      final result = evaluateTransform(
        {
          'input': 5,
          'ops': [
            {'type': 'multiply', 'by': 3},
          ],
        },
        (v) => v,
      );
      expect(result, 15.0);
    });

    test('add', () {
      final result = evaluateTransform(
        {
          'input': 10,
          'ops': [
            {'type': 'add', 'value': 5},
          ],
        },
        (v) => v,
      );
      expect(result, 15.0);
    });

    test('floor and ceil', () {
      final floor = evaluateTransform(
        {
          'input': 3.7,
          'ops': [
            {'type': 'floor'},
          ],
        },
        (v) => v,
      );
      expect(floor, 3);

      final ceil = evaluateTransform(
        {
          'input': 3.2,
          'ops': [
            {'type': 'ceil'},
          ],
        },
        (v) => v,
      );
      expect(ceil, 4);
    });

    test('prefix', () {
      final result = evaluateTransform(
        {
          'input': '42',
          'ops': [
            {'type': 'prefix', 'value': 'Count: '},
          ],
        },
        (v) => v,
      );
      expect(result, 'Count: 42');
    });

    test('map — matched key', () {
      final result = evaluateTransform(
        {
          'input': '1',
          'ops': [
            {
              'type': 'map',
              'mappings': {'0': 'Off', '1': 'On'},
              'default': 'Unknown',
            },
          ],
        },
        (v) => v,
      );
      expect(result, 'On');
    });

    test('map — unmatched uses default', () {
      final result = evaluateTransform(
        {
          'input': '99',
          'ops': [
            {
              'type': 'map',
              'mappings': {'0': 'Off', '1': 'On'},
              'default': 'Unknown',
            },
          ],
        },
        (v) => v,
      );
      expect(result, 'Unknown');
    });

    test('threshold — within range', () {
      final result = evaluateTransform(
        {
          'input': 75,
          'ops': [
            {
              'type': 'threshold',
              'ranges': [
                {'min': 0, 'max': 50, 'label': 'Low'},
                {'min': 51, 'max': 80, 'label': 'Medium'},
                {'min': 81, 'max': 100, 'label': 'High'},
              ],
              'default': 'Unknown',
            },
          ],
        },
        (v) => v,
      );
      expect(result, 'Medium');
    });

    test('threshold — no match uses default', () {
      final result = evaluateTransform(
        {
          'input': 200,
          'ops': [
            {
              'type': 'threshold',
              'ranges': [
                {'min': 0, 'max': 100, 'label': 'Normal'},
              ],
              'default': 'Out of range',
            },
          ],
        },
        (v) => v,
      );
      expect(result, 'Out of range');
    });

    test('divide by zero returns NaN', () {
      final result = evaluateTransform(
        {
          'input': 10,
          'ops': [
            {'type': 'divide', 'by': 0},
          ],
        },
        (v) => v,
      );
      expect((result as double).isNaN, isTrue);
    });

    test('fn op in pipeline', () {
      final result = evaluateTransform(
        {
          'input': '85.6',
          'ops': [
            {'type': 'fn', 'name': 'formatPercent'},
          ],
        },
        (v) => v,
      );
      expect(result, '85.6%');
    });

    test('unknown op type passes value through', () {
      final result = evaluateTransform(
        {
          'input': 42,
          'ops': [
            {'type': 'unknownOp'},
          ],
        },
        (v) => v,
      );
      expect(result, 42);
    });
  });

  // -----------------------------------------------------------------------
  // $compute — percent_used
  // -----------------------------------------------------------------------
  group(r'$compute — percent_used', () {
    test('normal values', () {
      final result = evaluateCompute(
        {'op': 'percent_used', 'total': 1000, 'free': 150},
        (v) => v,
      );
      expect(result, '85.0');
    });

    test('zero total returns --', () {
      final result = evaluateCompute(
        {'op': 'percent_used', 'total': 0, 'free': 0},
        (v) => v,
      );
      expect(result, '--');
    });

    test(r'resolves nested $bind', () {
      final resolve = _resolve({
        'Device.DeviceInfo.MemoryStatus.Total': '1048576',
        'Device.DeviceInfo.MemoryStatus.Free': '524288',
      });
      final result = evaluateCompute(
        {
          'op': 'percent_used',
          'total': {r'$bind': 'Device.DeviceInfo.MemoryStatus.Total'},
          'free': {r'$bind': 'Device.DeviceInfo.MemoryStatus.Free'},
        },
        resolve,
      );
      expect(result, '50.0');
    });
  });

  // -----------------------------------------------------------------------
  // $compute — subtract
  // -----------------------------------------------------------------------
  group(r'$compute — subtract', () {
    test('basic subtraction', () {
      final result = evaluateCompute(
        {'op': 'subtract', 'a': 100, 'b': 30},
        (v) => v,
      );
      expect(result, 70.0);
    });
  });

  // -----------------------------------------------------------------------
  // $compute — ratio
  // -----------------------------------------------------------------------
  group(r'$compute — ratio', () {
    test('basic ratio', () {
      final result = evaluateCompute(
        {'op': 'ratio', 'numerator': 75, 'denominator': 100},
        (v) => v,
      );
      expect(result, 0.75);
    });

    test('zero denominator returns --', () {
      final result = evaluateCompute(
        {'op': 'ratio', 'numerator': 75, 'denominator': 0},
        (v) => v,
      );
      expect(result, '--');
    });
  });

  // -----------------------------------------------------------------------
  // $compute — template
  // -----------------------------------------------------------------------
  group(r'$compute — template', () {
    test('WiFi QR code string', () {
      final resolve = _resolve({
        'Device.WiFi.SSID.1.SSID': 'MyNetwork',
        'Device.WiFi.AccessPoint.1.Security.KeyPassphrase': 'secret123',
        'Device.WiFi.AccessPoint.1.Security.ModeEnabled': 'WPA2-Personal',
      });
      final result = evaluateCompute(
        {
          'op': 'template',
          'format': 'WIFI:T:{mode};S:{ssid};P:{pass};;',
          'values': {
            'ssid': {r'$bind': 'Device.WiFi.SSID.1.SSID'},
            'pass': {
              r'$bind': 'Device.WiFi.AccessPoint.1.Security.KeyPassphrase'
            },
            'mode': {
              r'$bind': 'Device.WiFi.AccessPoint.1.Security.ModeEnabled'
            },
          },
        },
        resolve,
      );
      expect(result, 'WIFI:T:WPA2-Personal;S:MyNetwork;P:secret123;;');
    });

    test('missing variable resolves to empty', () {
      final result = evaluateCompute(
        {
          'op': 'template',
          'format': 'Hello {name}!',
          'values': {
            'name': {r'$bind': 'some.path'},
          },
        },
        _resolve({}),
      );
      expect(result, 'Hello --!');
    });

    test('empty format returns empty string', () {
      final result = evaluateCompute(
        {'op': 'template', 'format': '', 'values': <String, dynamic>{}},
        (v) => v,
      );
      expect(result, '');
    });

    test(r'static values without $bind', () {
      final result = evaluateCompute(
        {
          'op': 'template',
          'format': '{a} + {b} = result',
          'values': {'a': '10', 'b': '20'},
        },
        (v) => v,
      );
      expect(result, '10 + 20 = result');
    });
  });

  // -----------------------------------------------------------------------
  // $compute — unknown op
  // -----------------------------------------------------------------------
  group(r'$compute — unknown op', () {
    test('returns --', () {
      final result = evaluateCompute(
        {'op': 'nonExistent'},
        (v) => v,
      );
      expect(result, '--');
    });
  });

  // -----------------------------------------------------------------------
  // $visible — truthy check
  // -----------------------------------------------------------------------
  group(r'$visible — truthy', () {
    test('null → false', () {
      expect(evaluateVisible(null, (v) => v), isFalse);
    });

    test('empty string → false', () {
      expect(evaluateVisible('', (v) => v), isFalse);
    });

    test('"false" → false', () {
      expect(evaluateVisible('false', (v) => v), isFalse);
    });

    test('"0" → false', () {
      expect(evaluateVisible('0', (v) => v), isFalse);
    });

    test('"--" → false', () {
      expect(evaluateVisible('--', (v) => v), isFalse);
    });

    test('0 (num) → false', () {
      expect(evaluateVisible(0, (v) => v), isFalse);
    });

    test('"true" → true', () {
      expect(evaluateVisible('true', (v) => v), isTrue);
    });

    test('"1" → true', () {
      expect(evaluateVisible('1', (v) => v), isTrue);
    });

    test('non-empty string → true', () {
      expect(evaluateVisible('hello', (v) => v), isTrue);
    });

    test('non-zero number → true', () {
      expect(evaluateVisible(42, (v) => v), isTrue);
    });

    test('true (bool) → true', () {
      expect(evaluateVisible(true, (v) => v), isTrue);
    });

    test('false (bool) → false', () {
      expect(evaluateVisible(false, (v) => v), isFalse);
    });

    test(r'resolves $bind then checks truthy', () {
      final resolve =
          _resolve({'Device.X.Enabled': 'true'});
      final result = evaluateVisible(
        {r'$bind': 'Device.X.Enabled'},
        resolve,
      );
      expect(result, isTrue);
    });

    test(r'$bind to missing path → "--" → false', () {
      final result = evaluateVisible(
        {r'$bind': 'Device.Missing.Path'},
        _resolve({}),
      );
      expect(result, isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // $visible — condition mode
  // -----------------------------------------------------------------------
  group(r'$visible — conditions', () {
    test('eq — match', () {
      final result = evaluateVisible(
        {'condition': 'eq', 'value': 'WPA2', 'expected': 'WPA2'},
        (v) => v,
      );
      expect(result, isTrue);
    });

    test('eq — no match', () {
      final result = evaluateVisible(
        {'condition': 'eq', 'value': 'WPA3', 'expected': 'WPA2'},
        (v) => v,
      );
      expect(result, isFalse);
    });

    test('neq', () {
      final result = evaluateVisible(
        {'condition': 'neq', 'value': 'WPA3', 'expected': 'WPA2'},
        (v) => v,
      );
      expect(result, isTrue);
    });

    test('gt', () {
      expect(
        evaluateVisible(
          {'condition': 'gt', 'value': 10, 'expected': 5},
          (v) => v,
        ),
        isTrue,
      );
      expect(
        evaluateVisible(
          {'condition': 'gt', 'value': 5, 'expected': 10},
          (v) => v,
        ),
        isFalse,
      );
    });

    test('gte', () {
      expect(
        evaluateVisible(
          {'condition': 'gte', 'value': 10, 'expected': 10},
          (v) => v,
        ),
        isTrue,
      );
    });

    test('lt', () {
      expect(
        evaluateVisible(
          {'condition': 'lt', 'value': 3, 'expected': 5},
          (v) => v,
        ),
        isTrue,
      );
    });

    test('lte', () {
      expect(
        evaluateVisible(
          {'condition': 'lte', 'value': 5, 'expected': 5},
          (v) => v,
        ),
        isTrue,
      );
    });

    test('contains', () {
      expect(
        evaluateVisible(
          {'condition': 'contains', 'value': 'hello world', 'expected': 'world'},
          (v) => v,
        ),
        isTrue,
      );
      expect(
        evaluateVisible(
          {'condition': 'contains', 'value': 'hello', 'expected': 'xyz'},
          (v) => v,
        ),
        isFalse,
      );
    });

    test('in — value in list', () {
      expect(
        evaluateVisible(
          {
            'condition': 'in',
            'value': 'WPA2',
            'expected': ['WPA2', 'WPA3'],
          },
          (v) => v,
        ),
        isTrue,
      );
    });

    test('in — value not in list', () {
      expect(
        evaluateVisible(
          {
            'condition': 'in',
            'value': 'WEP',
            'expected': ['WPA2', 'WPA3'],
          },
          (v) => v,
        ),
        isFalse,
      );
    });

    test('in — expected not a list → false', () {
      expect(
        evaluateVisible(
          {'condition': 'in', 'value': 'WPA2', 'expected': 'WPA2'},
          (v) => v,
        ),
        isFalse,
      );
    });

    test('unknown condition defaults to true', () {
      expect(
        evaluateVisible(
          {'condition': 'unknownCond', 'value': 'a', 'expected': 'b'},
          (v) => v,
        ),
        isTrue,
      );
    });

    test(r'condition with nested $bind', () {
      final resolve = _resolve({'Device.X.Mode': 'WPA2'});
      final result = evaluateVisible(
        {
          'condition': 'eq',
          'value': {r'$bind': 'Device.X.Mode'},
          'expected': 'WPA2',
        },
        resolve,
      );
      expect(result, isTrue);
    });
  });
}
