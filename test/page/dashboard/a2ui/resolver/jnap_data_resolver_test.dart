import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/a2ui/resolver/jnap_data_resolver.dart';

void main() {
  group('JnapDataResolver', () {
    late ProviderContainer container;
    late JnapDataResolver resolver;

    setUp(() {
      container = ProviderContainer();
      resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;
    });

    tearDown(() {
      container.dispose();
    });

    group('resolve', () {
      test('returns value for router.deviceCount', () {
        final result = resolver.resolve('router.deviceCount');
        // Currently returns placeholder value
        expect(result, isA<int>());
      });

      test('returns value for router.nodeCount', () {
        final result = resolver.resolve('router.nodeCount');
        expect(result, isA<int>());
      });

      test('returns value for router.wanStatus', () {
        final result = resolver.resolve('router.wanStatus');
        expect(result, isA<String>());
      });

      test('returns value for router.uptime', () {
        final result = resolver.resolve('router.uptime');
        expect(result, isA<String>());
      });

      test('returns value for wifi.ssid', () {
        final result = resolver.resolve('wifi.ssid');
        expect(result, isA<String>());
      });

      test('returns null for unknown path', () {
        final result = resolver.resolve('unknown.path');
        expect(result, isNull);
      });

      test('returns null for empty path', () {
        final result = resolver.resolve('');
        expect(result, isNull);
      });
    });

    group('watch', () {
      test('returns null for now (placeholder implementation)', () {
        // Current implementation returns null for all paths
        // This will be updated when real providers are connected
        final result = resolver.watch('router.deviceCount');
        expect(result, isNull);
      });
    });
  });

  group('jnapDataResolverProvider', () {
    test('provides DataPathResolver instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final resolver = container.read(jnapDataResolverProvider);

      expect(resolver, isA<JnapDataResolver>());
    });
  });
}
