import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/providers/connectivity/services/connectivity_service.dart';

/// Mock for ConnectivityService
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockConnectivityService mockConnectivityService;

  setUp(() {
    mockConnectivityService = MockConnectivityService();
  });

  ProviderContainer makeProviderContainer() {
    return ProviderContainer(
      overrides: [
        connectivityServiceProvider
            .overrideWithValue(mockConnectivityService),
      ],
    );
  }

  // ============================================================================
  // isRouterConfigured() delegation tests
  // ============================================================================

  group('ConnectivityNotifier - isRouterConfigured delegation', () {
    test('delegates to ConnectivityService.fetchRouterConfiguredData on success',
        () async {
      // Arrange
      final container = makeProviderContainer();
      const expectedData = RouterConfiguredData(
        isDefaultPassword: false,
        isSetByUser: true,
      );

      when(() => mockConnectivityService.fetchRouterConfiguredData())
          .thenAnswer((_) async => expectedData);

      // Act
      final notifier = container.read(connectivityProvider.notifier);
      final result = await notifier.isRouterConfigured();

      // Assert
      expect(result.isDefaultPassword, false);
      expect(result.isSetByUser, true);
      verify(() => mockConnectivityService.fetchRouterConfiguredData())
          .called(1);
    });

    test('delegates to ConnectivityService and returns default password state',
        () async {
      // Arrange
      final container = makeProviderContainer();
      const expectedData = RouterConfiguredData(
        isDefaultPassword: true,
        isSetByUser: false,
      );

      when(() => mockConnectivityService.fetchRouterConfiguredData())
          .thenAnswer((_) async => expectedData);

      // Act
      final notifier = container.read(connectivityProvider.notifier);
      final result = await notifier.isRouterConfigured();

      // Assert
      expect(result.isDefaultPassword, true);
      expect(result.isSetByUser, false);
    });

    test('propagates ServiceError from ConnectivityService', () async {
      // Arrange
      final container = makeProviderContainer();

      when(() => mockConnectivityService.fetchRouterConfiguredData())
          .thenThrow(const UnexpectedError(message: 'JNAP error'));

      // Act & Assert
      final notifier = container.read(connectivityProvider.notifier);
      expect(
        () => notifier.isRouterConfigured(),
        throwsA(isA<ServiceError>()),
      );
      verify(() => mockConnectivityService.fetchRouterConfiguredData())
          .called(1);
    });

    test('propagates specific ServiceError types from ConnectivityService',
        () async {
      // Arrange
      final container = makeProviderContainer();

      when(() => mockConnectivityService.fetchRouterConfiguredData())
          .thenThrow(const NetworkError(message: 'Network timeout'));

      // Act & Assert
      final notifier = container.read(connectivityProvider.notifier);
      expect(
        () => notifier.isRouterConfigured(),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  // ============================================================================
  // Provider initial state tests
  // ============================================================================

  group('ConnectivityNotifier - initial state', () {
    test('has correct initial state', () {
      // Arrange
      final container = makeProviderContainer();

      // Act
      final state = container.read(connectivityProvider);

      // Assert
      expect(state.hasInternet, false);
      expect(state.connectivityInfo.routerType, RouterType.others);
    });
  });

  // ============================================================================
  // Service provider dependency tests
  // ============================================================================

  group('ConnectivityNotifier - service dependency', () {
    test('reads ConnectivityService from connectivityServiceProvider', () async {
      // Arrange
      final container = makeProviderContainer();
      const expectedData = RouterConfiguredData(
        isDefaultPassword: false,
        isSetByUser: true,
      );

      when(() => mockConnectivityService.fetchRouterConfiguredData())
          .thenAnswer((_) async => expectedData);

      // Act
      final notifier = container.read(connectivityProvider.notifier);
      await notifier.isRouterConfigured();

      // Assert - verify the mock was called, proving the provider override worked
      verify(() => mockConnectivityService.fetchRouterConfiguredData())
          .called(1);
    });

    test('multiple calls to isRouterConfigured delegate to service each time',
        () async {
      // Arrange
      final container = makeProviderContainer();
      const expectedData = RouterConfiguredData(
        isDefaultPassword: false,
        isSetByUser: true,
      );

      when(() => mockConnectivityService.fetchRouterConfiguredData())
          .thenAnswer((_) async => expectedData);

      // Act
      final notifier = container.read(connectivityProvider.notifier);
      await notifier.isRouterConfigured();
      await notifier.isRouterConfigured();
      await notifier.isRouterConfigured();

      // Assert - verify the service was called 3 times
      verify(() => mockConnectivityService.fetchRouterConfiguredData())
          .called(3);
    });
  });
}
