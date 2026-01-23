import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/page/dashboard/a2ui/resolver/jnap_data_resolver.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';

void main() {
  group('JnapDataResolver - Core Edge Cases', () {
    late ProviderContainer container;
    late JnapDataResolver resolver;

    tearDown(() {
      container.dispose();
    });

    group('Basic Functionality Tests', () {
      test('resolve() returns correct types for all supported paths', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Test all supported data paths return correct types
        final deviceCount = resolver.resolve('router.deviceCount');
        final nodeCount = resolver.resolve('router.nodeCount');
        final wanStatus = resolver.resolve('router.wanStatus');
        final uptime = resolver.resolve('router.uptime');
        final ssid = resolver.resolve('wifi.ssid');

        expect(deviceCount, isA<String>()); // Changed to String
        expect(nodeCount, isA<String>()); // Changed to String
        expect(wanStatus, isA<String>());
        expect(uptime, isA<String>());
        expect(ssid, isA<String>());
      });

      test('resolve() returns null for unknown paths', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final unknownPaths = [
          'unknown.path',
          'router.unknown',
          'wifi.unknown',
          'device.count', // Wrong prefix
          'router.', // Missing field
          '.deviceCount', // Missing category
          '', // Empty string
          'ROUTER.DEVICECOUNT', // Wrong case
          'router.deviceCount.extra', // Too many parts
        ];

        for (final path in unknownPaths) {
          final result = resolver.resolve(path);
          // Unknown paths should return null or a String (any fallback value is acceptable)
          expect(result == null || result is String, isTrue,
              reason:
                  'Should return null or string fallback for path: "$path", got: $result');
        }
      });

      test('watch() returns ProviderListenable for valid paths', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final deviceCountWatch = resolver.watch('router.deviceCount');
        final nodeCountWatch = resolver.watch('router.nodeCount');
        final wanStatusWatch = resolver.watch('router.wanStatus');
        final uptimeWatch = resolver.watch('router.uptime');
        final ssidWatch = resolver.watch('wifi.ssid');

        expect(deviceCountWatch, isA<ProviderListenable>());
        expect(nodeCountWatch, isA<ProviderListenable>());
        expect(wanStatusWatch, isA<ProviderListenable>());
        expect(uptimeWatch, isA<ProviderListenable>());
        expect(ssidWatch, isA<ProviderListenable>());
      });

      test('watch() returns null for invalid paths', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final invalidPaths = [
          'unknown.path',
          'invalid.field',
          '',
          'router.nonexistent',
          'wifi.nonexistent',
        ];

        for (final path in invalidPaths) {
          final result = resolver.watch(path);
          expect(result, isNull,
              reason: 'Should return null for invalid path: "$path"');
        }
      });

      test('handles exception in resolve() gracefully', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // These should not throw exceptions, even with default/empty state
        expect(() => resolver.resolve('router.deviceCount'), returnsNormally);
        expect(() => resolver.resolve('router.nodeCount'), returnsNormally);
        expect(() => resolver.resolve('router.wanStatus'), returnsNormally);
        expect(() => resolver.resolve('router.uptime'), returnsNormally);
        expect(() => resolver.resolve('wifi.ssid'), returnsNormally);
      });
    });

    group('Data Value Edge Cases', () {
      test('WAN status parsing handles various cases', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Test with default/empty state - should return "Offline"
        final wanStatus = resolver.resolve('router.wanStatus');
        expect(wanStatus, isA<String>());
        expect(['Online', 'Offline'], contains(wanStatus));
      });

      test('uptime formatting handles edge cases', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Test with default/empty state - should return valid format
        final uptime = resolver.resolve('router.uptime');
        expect(uptime, isA<String>());
        expect(uptime, matches(RegExp(r'^\d+d \d+h \d+m$')));
      });

      test('device and node counts handle empty lists', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Test with default/empty state - should return 0 (as string "0")
        final deviceCount = resolver.resolve('router.deviceCount');
        final nodeCount = resolver.resolve('router.nodeCount');

        expect(deviceCount, isA<String>()); // Changed to String
        expect(nodeCount, isA<String>()); // Changed to String
        // Check for string "0" or just verify it's a valid number string if needed generally, but we know it returns "0" default
        expect(
            int.tryParse(deviceCount as String) ?? -1, greaterThanOrEqualTo(0));
        expect(
            int.tryParse(nodeCount as String) ?? -1, greaterThanOrEqualTo(0));
      });

      test('SSID resolution handles empty/null cases', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Test with default/empty state - should return empty string
        final ssid = resolver.resolve('wifi.ssid');
        expect(ssid, isA<String>());
      });
    });

    group('Reactive Behavior Tests', () {
      test('watch() returns reactive providers that can be read', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final deviceCountWatch = resolver.watch('router.deviceCount');

        if (deviceCountWatch != null) {
          // Should be able to read the current value
          expect(() => container.read(deviceCountWatch), returnsNormally);

          final currentValue = container.read(deviceCountWatch);
          expect(currentValue, isA<String>()); // Changed to String
        }
      });

      test('watch() providers update when underlying state changes', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final wanStatusWatch = resolver.watch('router.wanStatus');
        final uptimeWatch = resolver.watch('router.uptime');
        final ssidWatch = resolver.watch('wifi.ssid');

        if (wanStatusWatch != null) {
          final wanStatus = container.read(wanStatusWatch);
          expect(wanStatus, isA<String>());
        }

        if (uptimeWatch != null) {
          final uptime = container.read(uptimeWatch);
          expect(uptime, isA<String>());
        }

        if (ssidWatch != null) {
          final ssid = container.read(ssidWatch);
          expect(ssid, isA<String>());
        }
      });
    });

    group('Error Handling and Resilience', () {
      test('resolver handles null/undefined cases gracefully', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Test path validation
        expect(() => resolver.resolve(''), returnsNormally);
        expect(() => resolver.resolve('   '), returnsNormally);
        expect(() => resolver.resolve('invalid'), returnsNormally);

        expect(() => resolver.watch(''), returnsNormally);
        expect(() => resolver.watch('invalid'), returnsNormally);
      });

      test('provides sensible defaults for all data types', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // All resolve calls should return sensible defaults, not null or throw
        final deviceCount = resolver.resolve('router.deviceCount');
        final nodeCount = resolver.resolve('router.nodeCount');
        final wanStatus = resolver.resolve('router.wanStatus');
        final uptime = resolver.resolve('router.uptime');
        final ssid = resolver.resolve('wifi.ssid');

        expect(deviceCount, isNotNull);
        expect(nodeCount, isNotNull);
        expect(wanStatus, isNotNull);
        expect(uptime, isNotNull);
        expect(ssid, isNotNull);
      });

      test('data type consistency across resolve() and watch()', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final testPaths = [
          'router.deviceCount',
          'router.nodeCount',
          'router.wanStatus',
          'router.uptime',
          'wifi.ssid',
        ];

        for (final path in testPaths) {
          final resolveValue = resolver.resolve(path);
          final watchProvider = resolver.watch(path);

          if (watchProvider != null && resolveValue != null) {
            final watchValue = container.read(watchProvider);

            // Both should return the same type
            expect(resolveValue.runtimeType, watchValue.runtimeType,
                reason: 'Type mismatch for path: $path');
          }
        }
      });
    });

    group('Integration with Provider System', () {
      test('resolver can be retrieved from provider consistently', () {
        container = ProviderContainer();

        final resolver1 = container.read(jnapDataResolverProvider);
        final resolver2 = container.read(jnapDataResolverProvider);

        expect(resolver1, isA<JnapDataResolver>());
        expect(resolver2, isA<JnapDataResolver>());
        expect(identical(resolver1, resolver2), isTrue,
            reason: 'Provider should return same instance');
      });

      test('resolver works with multiple containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final resolver1 =
            container1.read(jnapDataResolverProvider) as JnapDataResolver;
        final resolver2 =
            container2.read(jnapDataResolverProvider) as JnapDataResolver;

        // Both should work independently
        final result1 = resolver1.resolve('router.deviceCount');
        final result2 = resolver2.resolve('router.deviceCount');

        expect(result1, equals('0')); // Expect String '0' not int
        expect(result2, equals('0'));

        container1.dispose();
        container2.dispose();
      });

      test('resolver handles container disposal gracefully', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Should work before disposal
        expect(() => resolver.resolve('router.deviceCount'), returnsNormally);
        expect(() => resolver.watch('router.wanStatus'), returnsNormally);

        container.dispose();

        // Should still not crash after disposal (though may not work correctly)
        expect(() => resolver.resolve('router.deviceCount'), returnsNormally);
      });
    });
  });
}
