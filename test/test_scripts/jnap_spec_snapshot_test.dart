import 'package:test/test.dart';

import '../../test_scripts/jnap_spec_snapshot.dart';

// A cut-down router.hsl, in the format of linksys/JNAP openwrt-jnap/src/spec.
const _routerHsl = '''
#@@ software_copyright
#@ 2019 Belkin International, Inc. and/or its affiliates. All rights reserved.
#@@ end
namespace "http://linksys.com/jnap/router/"

[jnap, xsafe] action GetWANSettings
    output
        wanType : WANType

service Router
    actions
        GetWANSettings
        GetWANStatus

# Added Router13
service Router13
    actions
        GetWANSettings5
        #@ A comment between two actions.
        GetWANStatus3

struct StaticSettings
    ipAddress : IPAddress
''';

void main() {
  group('parseHsl', () {
    test('keys each service by namespace and name, with its actions', () {
      expect(parseHsl(_routerHsl), {
        'http://linksys.com/jnap/router/Router': [
          'GetWANSettings',
          'GetWANStatus',
        ],
        'http://linksys.com/jnap/router/Router13': [
          'GetWANSettings5',
          'GetWANStatus3',
        ],
      });
    });

    test('a file with no service gives an empty map', () {
      expect(
        parseHsl('namespace "http://linksys.com/jnap/core/"\n'
            '[jnap, noauth] action GetDeviceInfo\n'),
        isEmpty,
      );
    });

    test('turns down a service that appears before any namespace', () {
      expect(
        () => parseHsl('service Router\n    actions\n        GetWANSettings\n'),
        throwsFormatException,
      );
    });
  });

  group('baselineMismatches', () {
    // The tests read a baseline service's actions from the pin, which holds
    // only while the two agree.
    test('finds none when every baseline service is the same at the pin', () {
      expect(
        baselineMismatches(
          baseline: {
            'r/Router': ['A']
          },
          pin: {
            'r/Router': ['A'],
            'r/Router2': ['A', 'B'],
          },
        ),
        isEmpty,
      );
    });

    test('names a baseline service the pin changed or dropped', () {
      expect(
        baselineMismatches(
          baseline: {
            'r/Router': ['A'],
            'r/Router2': ['A', 'B'],
          },
          pin: {
            'r/Router': ['A', 'C'],
          },
        ),
        [
          'r/Router: the pin adds C',
          'r/Router2: the pin drops it',
        ],
      );
    });
  });

  group('mergeServices', () {
    test('joins the actions of a service that two files define', () {
      // healthcheck.hsl and healthcheck_samknows.hsl both define
      // http://linksys.com/jnap/healthcheck/HealthCheckManager.
      final merged = mergeServices([
        {
          'http://linksys.com/jnap/healthcheck/HealthCheckManager': ['B', 'A'],
        },
        {
          'http://linksys.com/jnap/healthcheck/HealthCheckManager': ['C', 'A'],
          'http://linksys.com/jnap/core/Core': ['GetDeviceInfo'],
        },
      ]);
      expect(merged, {
        'http://linksys.com/jnap/core/Core': ['GetDeviceInfo'],
        'http://linksys.com/jnap/healthcheck/HealthCheckManager': [
          'A',
          'B',
          'C',
        ],
      });
      expect(merged.keys.toList(), [
        'http://linksys.com/jnap/core/Core',
        'http://linksys.com/jnap/healthcheck/HealthCheckManager',
      ]);
    });
  });
}
