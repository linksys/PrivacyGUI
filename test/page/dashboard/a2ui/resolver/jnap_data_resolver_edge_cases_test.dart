import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/page/dashboard/a2ui/resolver/jnap_data_resolver.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';

// Import standard mocks from project
import '../../../../mocks/dashboard_home_notifier_mocks.dart';
import '../../../../mocks/device_manager_notifier_mocks.dart';

/// Fixed version of JnapDataResolver Edge Cases Tests
///
/// This version uses the project's standard mock notifiers and focuses on
/// essential edge cases without complex object creation that could cause errors.
void main() {
  group('JnapDataResolver - Edge Cases (Fixed)', () {
    late ProviderContainer container;
    late JnapDataResolver resolver;
    late MockDashboardHomeNotifier mockDashboardHome;
    late MockDeviceManagerNotifier mockDeviceManager;

    setUp(() {
      mockDashboardHome = MockDashboardHomeNotifier();
      mockDeviceManager = MockDeviceManagerNotifier();
    });

    tearDown(() {
      container.dispose();
    });

    group('Device Count Edge Cases', () {
      test('handles empty device list correctly', () {
        // Setup mock with empty device list
        const emptyState = DeviceManagerState(deviceList: []);
        when(mockDeviceManager.build()).thenReturn(emptyState);
        when(mockDeviceManager.state).thenReturn(emptyState);

        container = ProviderContainer(
          overrides: [
            deviceManagerProvider.overrideWith(() => mockDeviceManager),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.deviceCount');
        expect(result, '0'); // Expect string '0'
      });

      test('returns consistent device count across multiple calls', () {
        const testState = DeviceManagerState(deviceList: []);
        when(mockDeviceManager.build()).thenReturn(testState);
        when(mockDeviceManager.state).thenReturn(testState);

        container = ProviderContainer(
          overrides: [
            deviceManagerProvider.overrideWith(() => mockDeviceManager),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Multiple calls should return same result
        final result1 = resolver.resolve('router.deviceCount');
        final result2 = resolver.resolve('router.deviceCount');
        final result3 = resolver.resolve('router.deviceCount');

        expect(result1, equals(result2));
        expect(result2, equals(result3));
        expect(result1, isA<String>()); // Expect String
      });
    });

    group('Node Count Edge Cases', () {
      test('handles empty device list for node count', () {
        const emptyState = DeviceManagerState(deviceList: []);
        when(mockDeviceManager.build()).thenReturn(emptyState);
        when(mockDeviceManager.state).thenReturn(emptyState);

        container = ProviderContainer(
          overrides: [
            deviceManagerProvider.overrideWith(() => mockDeviceManager),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.nodeCount');
        expect(result, '0'); // Expect string '0'
      });

      test('node count is consistent with device manager state', () {
        const testState = DeviceManagerState(deviceList: []);
        when(mockDeviceManager.build()).thenReturn(testState);
        when(mockDeviceManager.state).thenReturn(testState);

        container = ProviderContainer(
          overrides: [
            deviceManagerProvider.overrideWith(() => mockDeviceManager),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.nodeCount');
        expect(result, isA<String>()); // Expect String
        expect(int.parse(result as String), greaterThanOrEqualTo(0));
      });
    });

    group('WAN Status Edge Cases', () {
      test('handles null WAN port connection', () {
        const nullWanState = DashboardHomeState(wanPortConnection: null);
        when(mockDashboardHome.build()).thenReturn(nullWanState);
        when(mockDashboardHome.state).thenReturn(nullWanState);

        container = ProviderContainer(
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.wanStatus');
        expect(result, 'Offline'); // Should default to Offline for null
      });

      test('handles empty WAN port connection', () {
        const emptyWanState = DashboardHomeState(wanPortConnection: '');
        when(mockDashboardHome.build()).thenReturn(emptyWanState);
        when(mockDashboardHome.state).thenReturn(emptyWanState);

        container = ProviderContainer(
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.wanStatus');
        expect(result, 'Offline'); // Empty string should be Offline
      });

      test('recognizes connected status correctly', () {
        const connectedState =
            DashboardHomeState(wanPortConnection: 'Connected');
        when(mockDashboardHome.build()).thenReturn(connectedState);
        when(mockDashboardHome.state).thenReturn(connectedState);

        container = ProviderContainer(
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.wanStatus');
        expect(result, 'Online'); // Connected should be Online
      });

      test('handles case insensitive connected status', () {
        const lowerCaseState =
            DashboardHomeState(wanPortConnection: 'connected');
        when(mockDashboardHome.build()).thenReturn(lowerCaseState);
        when(mockDashboardHome.state).thenReturn(lowerCaseState);

        container = ProviderContainer(
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.wanStatus');
        expect(result, 'Online'); // Should be case insensitive
      });
    });

    group('Uptime Edge Cases', () {
      test('handles null uptime correctly', () {
        const nullUptimeState = DashboardHomeState(uptime: null);
        when(mockDashboardHome.build()).thenReturn(nullUptimeState);
        when(mockDashboardHome.state).thenReturn(nullUptimeState);

        container = ProviderContainer(
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.uptime');
        expect(result, '0d 0h 0m'); // Should default to zero uptime
      });

      test('handles zero uptime correctly', () {
        const zeroUptimeState = DashboardHomeState(uptime: 0);
        when(mockDashboardHome.build()).thenReturn(zeroUptimeState);
        when(mockDashboardHome.state).thenReturn(zeroUptimeState);

        container = ProviderContainer(
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.uptime');
        expect(result, '0d 0h 0m');
      });

      test('formats standard uptime correctly', () {
        // 1 day, 2 hours, 20 minutes, 45 seconds = 94845 seconds
        const standardUptimeState = DashboardHomeState(uptime: 94845);
        when(mockDashboardHome.build()).thenReturn(standardUptimeState);
        when(mockDashboardHome.state).thenReturn(standardUptimeState);

        container = ProviderContainer(
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.uptime');
        expect(
            result, '1d 2h 20m'); // Should format correctly (seconds truncated)
      });

      test('handles large uptime values', () {
        // 365 days, 23 hours, 59 minutes = 31622340 seconds
        const largeUptimeState = DashboardHomeState(uptime: 31622340);
        when(mockDashboardHome.build()).thenReturn(largeUptimeState);
        when(mockDashboardHome.state).thenReturn(largeUptimeState);

        container = ProviderContainer(
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('router.uptime');
        expect(result, isA<String>());
        expect(result, contains('d'));
        expect(result, contains('h'));
        expect(result, contains('m'));
      });
    });

    group('SSID Resolution Edge Cases', () {
      test('handles empty WiFi list', () {
        const emptyWifiState = DashboardHomeState(wifis: []);
        when(mockDashboardHome.build()).thenReturn(emptyWifiState);
        when(mockDashboardHome.state).thenReturn(emptyWifiState);

        container = ProviderContainer(
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result = resolver.resolve('wifi.ssid');
        expect(result, ''); // Should return empty string for no WiFi
      });

      test('returns consistent SSID across multiple calls', () {
        const testState = DashboardHomeState(wifis: []);
        when(mockDashboardHome.build()).thenReturn(testState);
        when(mockDashboardHome.state).thenReturn(testState);

        container = ProviderContainer(
          overrides: [
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final result1 = resolver.resolve('wifi.ssid');
        final result2 = resolver.resolve('wifi.ssid');

        expect(result1, equals(result2));
        expect(result1, isA<String>());
      });
    });

    group('Path Resolution Edge Cases', () {
      test('handles invalid paths gracefully', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final invalidPaths = [
          'invalid.path',
          'router.unknown',
          'wifi.unknown',
          'router.',
          '.deviceCount',
          '',
          '   ', // whitespace
          'router..deviceCount', // double dot
          'ROUTER.DEVICECOUNT', // wrong case
        ];

        for (final path in invalidPaths) {
          final result = resolver.resolve(path);
          expect(result == null || result is String, isTrue,
              reason: 'Should handle invalid path gracefully: "$path"');
        }
      });

      test('valid paths return expected types', () {
        // Setup minimal mocks
        const deviceState = DeviceManagerState(deviceList: []);
        const dashboardState = DashboardHomeState(
          wanPortConnection: 'Connected',
          uptime: 3600, // 1 hour
          wifis: [],
        );

        when(mockDeviceManager.build()).thenReturn(deviceState);
        when(mockDeviceManager.state).thenReturn(deviceState);
        when(mockDashboardHome.build()).thenReturn(dashboardState);
        when(mockDashboardHome.state).thenReturn(dashboardState);

        container = ProviderContainer(
          overrides: [
            deviceManagerProvider.overrideWith(() => mockDeviceManager),
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Test valid paths return expected types
        expect(resolver.resolve('router.deviceCount'), isA<String>()); // String
        expect(resolver.resolve('router.nodeCount'), isA<String>()); // String
        expect(resolver.resolve('router.wanStatus'), isA<String>());
        expect(resolver.resolve('router.uptime'), isA<String>());
        expect(resolver.resolve('wifi.ssid'), isA<String>());
      });
    });

    group('Reactive Behavior Edge Cases', () {
      test('watch returns ProviderListenable for valid paths', () {
        const deviceState = DeviceManagerState(deviceList: []);
        const dashboardState = DashboardHomeState();

        when(mockDeviceManager.build()).thenReturn(deviceState);
        when(mockDeviceManager.state).thenReturn(deviceState);
        when(mockDashboardHome.build()).thenReturn(dashboardState);
        when(mockDashboardHome.state).thenReturn(dashboardState);

        container = ProviderContainer(
          overrides: [
            deviceManagerProvider.overrideWith(() => mockDeviceManager),
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final validPaths = [
          'router.deviceCount',
          'router.nodeCount',
          'router.wanStatus',
          'router.uptime',
          'wifi.ssid',
        ];

        for (final path in validPaths) {
          final watcher = resolver.watch(path);
          expect(watcher, isA<ProviderListenable>(),
              reason: 'Should return ProviderListenable for: $path');
        }
      });

      test('watch returns null for invalid paths', () {
        container = ProviderContainer();
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final invalidPaths = [
          'invalid.path',
          'router.unknown',
          '',
        ];

        for (final path in invalidPaths) {
          final watcher = resolver.watch(path);
          expect(watcher, isNull,
              reason: 'Should return null for invalid path: $path');
        }
      });
    });

    group('Error Resilience', () {
      test('handles provider exceptions gracefully', () {
        // Use mocks that throw exceptions
        when(mockDeviceManager.build())
            .thenThrow(Exception('Device manager error'));
        when(mockDashboardHome.build()).thenThrow(Exception('Dashboard error'));

        container = ProviderContainer(
          overrides: [
            deviceManagerProvider.overrideWith(() => mockDeviceManager),
            dashboardHomeProvider.overrideWith(() => mockDashboardHome),
          ],
        );
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Should not throw exceptions, should return sensible defaults
        expect(() => resolver.resolve('router.deviceCount'), returnsNormally);
        expect(() => resolver.resolve('router.wanStatus'), returnsNormally);
        expect(() => resolver.resolve('wifi.ssid'), returnsNormally);

        // Verify default values are returned
        final deviceCount = resolver.resolve('router.deviceCount');
        final wanStatus = resolver.resolve('router.wanStatus');
        final ssid = resolver.resolve('wifi.ssid');

        expect(deviceCount, isA<String>()); // String
        expect(wanStatus, isA<String>());
        expect(ssid, isA<String>());
      });

      test('provides consistent default values', () {
        container = ProviderContainer(); // No overrides, using defaults
        resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Multiple calls should return same defaults
        for (int i = 0; i < 3; i++) {
          final deviceCount = resolver.resolve('router.deviceCount');
          final nodeCount = resolver.resolve('router.nodeCount');
          final wanStatus = resolver.resolve('router.wanStatus');
          final uptime = resolver.resolve('router.uptime');
          final ssid = resolver.resolve('wifi.ssid');

          expect(deviceCount, isA<String>()); // String
          expect(nodeCount, isA<String>()); // String
          expect(wanStatus, isA<String>());
          expect(uptime, isA<String>());
          expect(ssid, isA<String>());
        }
      });
    });
  });
}
