import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/cloud_host_resolver.dart';

void main() {
  // Assert against the configured cloud base (not a hardcoded domain) so the
  // test is independent of the active CloudEnvironment.
  final cloudBase = 'https://${cloudEnvironmentConfig[kCloudBase]}';

  group('CloudHostResolver', () {
    test('local build + client → router proxy base', () {
      final resolver = CloudHostResolver(
        isLocal: () => true,
        originGetter: () => 'https://192.168.1.1',
      );

      expect(
          resolver.resolve(forCA: false), 'https://192.168.1.1$kProxyPrefix');
    });

    test('local build + CA → cloud base (origin ignored)', () {
      final resolver = CloudHostResolver(
        isLocal: () => true,
        originGetter: () => 'https://192.168.1.1',
      );

      expect(resolver.resolve(forCA: true), cloudBase);
    });

    test('local build + empty origin → cloud base (fallback)', () {
      final resolver = CloudHostResolver(
        isLocal: () => true,
        originGetter: () => '',
      );

      expect(resolver.resolve(forCA: false), cloudBase);
    });

    test('non-local build + client → cloud base', () {
      final resolver = CloudHostResolver(
        isLocal: () => false,
        originGetter: () => 'https://192.168.1.1',
      );

      expect(resolver.resolve(forCA: false), cloudBase);
    });

    test('origin with port is preserved', () {
      final resolver = CloudHostResolver(
        isLocal: () => true,
        originGetter: () => 'https://192.168.1.1:8443',
      );

      expect(
        resolver.resolve(forCA: false),
        'https://192.168.1.1:8443$kProxyPrefix',
      );
    });

    test('http origin scheme is preserved (not forced to https)', () {
      final resolver = CloudHostResolver(
        isLocal: () => true,
        originGetter: () => 'http://192.168.1.1',
      );

      expect(resolver.resolve(forCA: false), 'http://192.168.1.1$kProxyPrefix');
    });

    test('default constructor → cloud base (deterministic in test env)', () {
      // Defaults: origin empty + BuildConfig.isLocal (false under force=none).
      final resolver = CloudHostResolver();

      expect(resolver.resolve(forCA: false), cloudBase);
      expect(resolver.resolve(forCA: true), cloudBase);
    });
  });
}
