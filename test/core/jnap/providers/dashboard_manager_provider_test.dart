import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/services/dashboard_manager_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/test_data/dashboard_manager_test_data.dart';

class MockDashboardManagerService extends Mock
    implements DashboardManagerService {}

void main() {
  // Initialize Flutter binding for SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockDashboardManagerService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockDashboardManagerService();
  });

  tearDown(() {
    container.dispose();
  });

  group('DashboardManagerNotifier - build', () {
    test('delegates to service.transformPollingData with polling data', () {
      // Arrange
      final pollingData =
          DashboardManagerTestData.createSuccessfulPollingData();
      final expectedState = DashboardManagerState(
        deviceInfo: NodeDeviceInfo.fromJson(
          DashboardManagerTestData.createDeviceInfoSuccess().output,
        ),
        uptimes: 86400,
        wanConnection: 'Linked-1000Mbps',
      );

      when(() => mockService.transformPollingData(pollingData))
          .thenReturn(expectedState);

      container = ProviderContainer(
        overrides: [
          dashboardManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(pollingData)),
        ],
      );

      // Act
      final state = container.read(dashboardManagerProvider);

      // Assert
      verify(() => mockService.transformPollingData(pollingData)).called(1);
      expect(state, equals(expectedState));
    });

    test('handles null polling data by returning default state', () {
      // Arrange
      const expectedState = DashboardManagerState();

      when(() => mockService.transformPollingData(any()))
          .thenReturn(expectedState);

      container = ProviderContainer(
        overrides: [
          dashboardManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final state = container.read(dashboardManagerProvider);

      // Assert
      verify(() => mockService.transformPollingData(any())).called(1);
      expect(state.deviceInfo, isNull);
      expect(state.mainRadios, isEmpty);
      expect(state.uptimes, equals(0));
    });

    test('rebuilds when polling data changes', () async {
      // Arrange
      final pollingData1 = DashboardManagerTestData.createSuccessfulPollingData(
        systemStats: DashboardManagerTestData.createSystemStatsSuccess(
          uptimeSeconds: 1000,
        ),
      );
      final pollingData2 = DashboardManagerTestData.createSuccessfulPollingData(
        systemStats: DashboardManagerTestData.createSystemStatsSuccess(
          uptimeSeconds: 2000,
        ),
      );

      const state1 = DashboardManagerState(uptimes: 1000);
      const state2 = DashboardManagerState(uptimes: 2000);

      when(() => mockService.transformPollingData(pollingData1))
          .thenReturn(state1);
      when(() => mockService.transformPollingData(pollingData2))
          .thenReturn(state2);

      // First container with pollingData1
      container = ProviderContainer(
        overrides: [
          dashboardManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider
              .overrideWith(() => _MockPollingNotifier(pollingData1)),
        ],
      );

      // Act - First read
      final firstState = container.read(dashboardManagerProvider);
      expect(firstState.uptimes, equals(1000));

      // Dispose and create new container with pollingData2
      container.dispose();
      container = ProviderContainer(
        overrides: [
          dashboardManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider
              .overrideWith(() => _MockPollingNotifier(pollingData2)),
        ],
      );

      final secondState = container.read(dashboardManagerProvider);

      // Assert
      expect(secondState.uptimes, equals(2000));
    });
  });

  group('DashboardManagerNotifier - checkRouterIsBack', () {
    setUp(() {
      // Mock SharedPreferences for checkRouterIsBack tests
      SharedPreferences.setMockInitialValues({
        'currentSN': 'MOCK_SN',
      });
    });

    test('delegates to service.checkRouterIsBack', () async {
      // Arrange
      final expectedDeviceInfo = NodeDeviceInfo.fromJson(
        DashboardManagerTestData.createDeviceInfoSuccess(
                serialNumber: 'TEST_SN')
            .output,
      );

      when(() => mockService.transformPollingData(any()))
          .thenReturn(const DashboardManagerState());
      when(() => mockService.checkRouterIsBack(any()))
          .thenAnswer((_) async => expectedDeviceInfo);

      container = ProviderContainer(
        overrides: [
          dashboardManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final result = await container
          .read(dashboardManagerProvider.notifier)
          .checkRouterIsBack();

      // Assert
      verify(() => mockService.checkRouterIsBack(any())).called(1);
      expect(result.serialNumber, equals('TEST_SN'));
    });

    test('propagates SerialNumberMismatchError from service', () async {
      // Arrange
      when(() => mockService.transformPollingData(any()))
          .thenReturn(const DashboardManagerState());
      when(() => mockService.checkRouterIsBack(any())).thenThrow(
        const SerialNumberMismatchError(expected: 'EXPECTED', actual: 'ACTUAL'),
      );

      container = ProviderContainer(
        overrides: [
          dashboardManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act & Assert
      await expectLater(
        () => container
            .read(dashboardManagerProvider.notifier)
            .checkRouterIsBack(),
        throwsA(isA<SerialNumberMismatchError>()),
      );
    });

    test('propagates ConnectivityError from service', () async {
      // Arrange
      when(() => mockService.transformPollingData(any()))
          .thenReturn(const DashboardManagerState());
      when(() => mockService.checkRouterIsBack(any())).thenThrow(
        const ConnectivityError(message: 'Router unreachable'),
      );

      container = ProviderContainer(
        overrides: [
          dashboardManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act & Assert
      await expectLater(
        () => container
            .read(dashboardManagerProvider.notifier)
            .checkRouterIsBack(),
        throwsA(isA<ConnectivityError>()),
      );
    });
  });

  group('DashboardManagerNotifier - checkDeviceInfo', () {
    test('delegates to service.checkDeviceInfo with cached state', () async {
      // Arrange
      final cachedDeviceInfo = NodeDeviceInfo.fromJson(
        DashboardManagerTestData.createDeviceInfoSuccess(
                serialNumber: 'CACHED_SN')
            .output,
      );
      final initialState = DashboardManagerState(deviceInfo: cachedDeviceInfo);

      when(() => mockService.transformPollingData(any()))
          .thenReturn(initialState);
      when(() => mockService.checkDeviceInfo(cachedDeviceInfo))
          .thenAnswer((_) async => cachedDeviceInfo);

      container = ProviderContainer(
        overrides: [
          dashboardManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final result = await container
          .read(dashboardManagerProvider.notifier)
          .checkDeviceInfo(null);

      // Assert
      verify(() => mockService.checkDeviceInfo(cachedDeviceInfo)).called(1);
      expect(result.serialNumber, equals('CACHED_SN'));
    });

    test('delegates to service.checkDeviceInfo with null when no cache',
        () async {
      // Arrange
      final freshDeviceInfo = NodeDeviceInfo.fromJson(
        DashboardManagerTestData.createDeviceInfoSuccess(
                serialNumber: 'FRESH_SN')
            .output,
      );

      when(() => mockService.transformPollingData(any()))
          .thenReturn(const DashboardManagerState());
      when(() => mockService.checkDeviceInfo(null))
          .thenAnswer((_) async => freshDeviceInfo);

      container = ProviderContainer(
        overrides: [
          dashboardManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final result = await container
          .read(dashboardManagerProvider.notifier)
          .checkDeviceInfo(null);

      // Assert
      verify(() => mockService.checkDeviceInfo(null)).called(1);
      expect(result.serialNumber, equals('FRESH_SN'));
    });

    test('propagates ServiceError from service', () async {
      // Arrange
      when(() => mockService.transformPollingData(any()))
          .thenReturn(const DashboardManagerState());
      when(() => mockService.checkDeviceInfo(any())).thenThrow(
        const ResourceNotFoundError(),
      );

      container = ProviderContainer(
        overrides: [
          dashboardManagerServiceProvider.overrideWithValue(mockService),
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act & Assert
      expect(
        () => container
            .read(dashboardManagerProvider.notifier)
            .checkDeviceInfo(null),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });
  });
}

/// Mock polling notifier that returns the given data
class _MockPollingNotifier extends PollingNotifier {
  final CoreTransactionData? _data;

  _MockPollingNotifier(this._data);

  @override
  CoreTransactionData build() =>
      _data ??
      const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});
}
