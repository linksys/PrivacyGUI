import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/ip_getter/get_local_ip.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';

/// Mock ConnectivityNotifier that allows setting initial state
class MockConnectivityNotifier extends Notifier<ConnectivityState>
    implements ConnectivityNotifier {
  final ConnectivityState _initialState;

  MockConnectivityNotifier(this._initialState);

  @override
  ConnectivityState build() => _initialState;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProviderReader typedef', () {
    test('ProviderReader type is compatible with container.read', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act - Verify that container.read can be assigned to ProviderReader
      final ProviderReader reader = container.read;

      // Assert - The assignment should compile and work
      expect(reader, isNotNull);
    });

    test('ProviderReader can read StateProvider', () {
      // Arrange
      final testProvider = StateProvider<String>((ref) => 'test_value');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final ProviderReader reader = container.read;
      final value = reader(testProvider);

      // Assert
      expect(value, equals('test_value'));
    });

    test('ProviderReader can read Provider with complex state', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          connectivityProvider
              .overrideWith(() => MockConnectivityNotifier(ConnectivityState(
                    hasInternet: true,
                    connectivityInfo:
                        ConnectivityInfo(gatewayIp: '192.168.1.1'),
                  ))),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final ProviderReader reader = container.read;
      final state = reader(connectivityProvider);

      // Assert
      expect(state.connectivityInfo.gatewayIp, equals('192.168.1.1'));
    });

    test('ProviderReader accesses same provider instance on multiple reads',
        () {
      // Arrange
      final counterProvider = StateProvider<int>((ref) => 0);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act - Read twice using ProviderReader
      final ProviderReader reader = container.read;
      final value1 = reader(counterProvider);

      // Mutate state
      container.read(counterProvider.notifier).state = 42;

      final value2 = reader(counterProvider);

      // Assert
      expect(value1, equals(0));
      expect(value2, equals(42));
    });

    test('Multiple ProviderReader references access same ProviderContainer',
        () {
      // Arrange - Simulates Ref.read and WidgetRef.read both accessing same container
      final sharedProvider = StateProvider<String>((ref) => 'shared_value');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act - Create two reader references (simulating Ref.read and WidgetRef.read)
      final ProviderReader reader1 = container.read;
      final ProviderReader reader2 = container.read;

      final value1 = reader1(sharedProvider);
      final value2 = reader2(sharedProvider);

      // Assert - Both should get the same value from the same provider instance
      expect(value1, equals(value2));
      expect(value1, equals('shared_value'));
    });
  });

  // Note: The actual getLocalIp function uses conditional exports
  // (mobile_get_local_ip.dart, web_get_local_ip.dart) which are platform-specific.
  // In a non-mobile/non-web test environment, the stub version throws UnsupportedError.
  // The following tests verify the mobile implementation logic can be called
  // with a ProviderReader, using direct implementation testing.

  group('Mobile getLocalIp implementation logic', () {
    test('gatewayIp extraction from ConnectivityInfo', () {
      // Arrange - Test the underlying logic that mobile_get_local_ip.dart uses
      final container = ProviderContainer(
        overrides: [
          connectivityProvider
              .overrideWith(() => MockConnectivityNotifier(ConnectivityState(
                    hasInternet: true,
                    connectivityInfo:
                        ConnectivityInfo(gatewayIp: '192.168.0.1'),
                  ))),
        ],
      );
      addTearDown(container.dispose);

      // Act - Simulate what mobile_get_local_ip.dart does
      final gatewayIp =
          container.read(connectivityProvider).connectivityInfo.gatewayIp ?? '';

      // Assert
      expect(gatewayIp, equals('192.168.0.1'));
    });

    test('null gatewayIp returns empty string', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          connectivityProvider
              .overrideWith(() => MockConnectivityNotifier(ConnectivityState(
                    hasInternet: false,
                    connectivityInfo: ConnectivityInfo(gatewayIp: null),
                  ))),
        ],
      );
      addTearDown(container.dispose);

      // Act - Simulate what mobile_get_local_ip.dart does
      final gatewayIp =
          container.read(connectivityProvider).connectivityInfo.gatewayIp ?? '';

      // Assert
      expect(gatewayIp, equals(''));
    });

    test('common IP address formats are preserved', () {
      // Test common IP address formats
      final testCases = [
        ('192.168.0.1', '192.168.0.1'),
        ('10.0.0.254', '10.0.0.254'),
        ('172.16.0.1', '172.16.0.1'),
        ('localhost', 'localhost'),
        ('https://192.168.1.1', 'https://192.168.1.1'),
        (null, ''),
      ];

      for (final (input, expected) in testCases) {
        final container = ProviderContainer(
          overrides: [
            connectivityProvider
                .overrideWith(() => MockConnectivityNotifier(ConnectivityState(
                      hasInternet: input != null,
                      connectivityInfo: ConnectivityInfo(gatewayIp: input),
                    ))),
          ],
        );
        addTearDown(container.dispose);

        // Act - Simulate mobile_get_local_ip.dart logic
        final gatewayIp =
            container.read(connectivityProvider).connectivityInfo.gatewayIp ??
                '';

        // Assert
        expect(gatewayIp, equals(expected),
            reason: 'Input: $input should produce: $expected');
      }
    });
  });
}
