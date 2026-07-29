import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/cloud_host_resolver.dart';
import 'package:privacy_gui/core/utils/ip_getter/ip_getter.dart';

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

  group('getCloudOrigin (platform stub) → resolver integration', () {
    // Tests run on the Dart VM, which selects the non-web (stub/mobile)
    // implementation. It MUST return '' — never call Uri.base.origin, which
    // throws a StateError on a file: URI. This locks in the non-web crash fix.
    test('returns empty string on non-web', () {
      expect(getCloudOrigin(), isEmpty);
    });

    test('local build + non-web origin → falls back to cloud base (no throw)',
        () {
      // Emulates a mobile .local build: isLocal() true, but getCloudOrigin()
      // yields '' → resolver must fall back to the cloud base without throwing.
      final resolver = CloudHostResolver(
        isLocal: () => true,
        originGetter: getCloudOrigin,
      );

      expect(resolver.resolve(forCA: false), cloudBase);
    });
  });
}
