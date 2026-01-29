import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/models/jnap_device_info_raw.dart';
import 'package:privacy_gui/core/data/providers/session_provider.dart';
import 'package:privacy_gui/core/data/providers/device_info_provider.dart';
import 'package:privacy_gui/core/data/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/test_data/dashboard_manager_test_data.dart';

class MockSessionService extends Mock implements SessionService {}

void main() {
  // Initialize Flutter binding for SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockSessionService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockSessionService();
  });

  tearDown(() {
    container.dispose();
  });

  group('SessionNotifier - build', () {
    test('build returns void (no state management)', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act & Assert - Just verify it doesn't throw
      expect(() => container.read(sessionProvider), returnsNormally);
    });
  });

  group('SessionNotifier - saveSelectedNetwork', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves serialNumber and networkId to SharedPreferences', () async {
      // Arrange
      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act
      await container
          .read(sessionProvider.notifier)
          .saveSelectedNetwork('TEST_SN', 'TEST_NETWORK_ID');

      // Assert
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pCurrentSN), equals('TEST_SN'));
      expect(prefs.getString(pSelectedNetworkId), equals('TEST_NETWORK_ID'));
      expect(
          container.read(selectedNetworkIdProvider), equals('TEST_NETWORK_ID'));
    });

    test('saves empty networkId for local sessions', () async {
      // Arrange
      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act
      await container
          .read(sessionProvider.notifier)
          .saveSelectedNetwork('LOCAL_SN', '');

      // Assert
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pCurrentSN), equals('LOCAL_SN'));
      expect(prefs.getString(pSelectedNetworkId), equals(''));
      expect(container.read(selectedNetworkIdProvider), equals(''));
    });
  });

  group('SessionNotifier - checkRouterIsBack', () {
    setUp(() {
      // Mock SharedPreferences for checkRouterIsBack tests
      SharedPreferences.setMockInitialValues({
        pCurrentSN: 'MOCK_SN',
      });
    });

    test('delegates to service.checkRouterIsBack with currentSN', () async {
      // Arrange
      final expectedDeviceInfo = JnapDeviceInfoRaw.fromJson(
        SessionTestData.createDeviceInfoSuccess(serialNumber: 'MOCK_SN').output,
      ).toUIModel();

      when(() => mockService.checkRouterIsBack('MOCK_SN'))
          .thenAnswer((_) async => expectedDeviceInfo);

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act
      final result =
          await container.read(sessionProvider.notifier).checkRouterIsBack();

      // Assert
      verify(() => mockService.checkRouterIsBack('MOCK_SN')).called(1);
      expect(result.serialNumber, equals('MOCK_SN'));
    });

    test('falls back to pnpConfiguredSN if currentSN is null', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        pPnpConfiguredSN: 'PNP_SN',
      });

      final expectedDeviceInfo = JnapDeviceInfoRaw.fromJson(
        SessionTestData.createDeviceInfoSuccess(serialNumber: 'PNP_SN').output,
      ).toUIModel();

      when(() => mockService.checkRouterIsBack('PNP_SN'))
          .thenAnswer((_) async => expectedDeviceInfo);

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act
      final result =
          await container.read(sessionProvider.notifier).checkRouterIsBack();

      // Assert
      verify(() => mockService.checkRouterIsBack('PNP_SN')).called(1);
      expect(result.serialNumber, equals('PNP_SN'));
    });

    test('propagates SerialNumberMismatchError from service', () async {
      // Arrange
      when(() => mockService.checkRouterIsBack(any())).thenThrow(
        const SerialNumberMismatchError(expected: 'EXPECTED', actual: 'ACTUAL'),
      );

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act & Assert
      await expectLater(
        () => container.read(sessionProvider.notifier).checkRouterIsBack(),
        throwsA(isA<SerialNumberMismatchError>()),
      );
    });

    test('propagates ConnectivityError from service', () async {
      // Arrange
      when(() => mockService.checkRouterIsBack(any())).thenThrow(
        const ConnectivityError(message: 'Router unreachable'),
      );

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act & Assert
      await expectLater(
        () => container.read(sessionProvider.notifier).checkRouterIsBack(),
        throwsA(isA<ConnectivityError>()),
      );
    });
  });

  group('SessionNotifier - checkDeviceInfo', () {
    test('delegates to service.checkDeviceInfo with cached state', () async {
      // Arrange
      final cachedDeviceInfo = JnapDeviceInfoRaw.fromJson(
        SessionTestData.createDeviceInfoSuccess(serialNumber: 'CACHED_SN')
            .output,
      ).toUIModel();
      final deviceInfoState = DeviceInfoState(deviceInfo: cachedDeviceInfo);

      when(() => mockService.checkDeviceInfo(cachedDeviceInfo))
          .thenAnswer((_) async => cachedDeviceInfo);

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(deviceInfoState),
        ],
      );

      // Act
      final result =
          await container.read(sessionProvider.notifier).checkDeviceInfo(null);

      // Assert
      verify(() => mockService.checkDeviceInfo(cachedDeviceInfo)).called(1);
      expect(result.serialNumber, equals('CACHED_SN'));
    });

    test('delegates to service.checkDeviceInfo with null when no cache',
        () async {
      // Arrange
      final freshDeviceInfo = JnapDeviceInfoRaw.fromJson(
        SessionTestData.createDeviceInfoSuccess(serialNumber: 'FRESH_SN')
            .output,
      ).toUIModel();

      when(() => mockService.checkDeviceInfo(null))
          .thenAnswer((_) async => freshDeviceInfo);

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act
      final result =
          await container.read(sessionProvider.notifier).checkDeviceInfo(null);

      // Assert
      verify(() => mockService.checkDeviceInfo(null)).called(1);
      expect(result.serialNumber, equals('FRESH_SN'));
    });

    test('propagates ServiceError from service', () async {
      // Arrange
      when(() => mockService.checkDeviceInfo(any())).thenThrow(
        const ResourceNotFoundError(),
      );

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act & Assert
      expect(
        () => container.read(sessionProvider.notifier).checkDeviceInfo(null),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });
  });

  group('SessionNotifier - forceFetchDeviceInfo', () {
    test('delegates to service.forceFetchDeviceInfo', () async {
      // Arrange
      final freshDeviceInfo = JnapDeviceInfoRaw.fromJson(
        SessionTestData.createDeviceInfoSuccess(serialNumber: 'FRESH_SN')
            .output,
      ).toUIModel();

      when(() => mockService.forceFetchDeviceInfo())
          .thenAnswer((_) async => freshDeviceInfo);

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act
      final result =
          await container.read(sessionProvider.notifier).forceFetchDeviceInfo();

      // Assert
      verify(() => mockService.forceFetchDeviceInfo()).called(1);
      expect(result.serialNumber, equals('FRESH_SN'));
    });

    test('always fetches fresh data, ignoring cache', () async {
      // Arrange - Cached device info exists but should be ignored
      final cachedDeviceInfo = JnapDeviceInfoRaw.fromJson(
        SessionTestData.createDeviceInfoSuccess(serialNumber: 'CACHED_SN')
            .output,
      ).toUIModel();
      final freshDeviceInfo = JnapDeviceInfoRaw.fromJson(
        SessionTestData.createDeviceInfoSuccess(serialNumber: 'FRESH_SN')
            .output,
      ).toUIModel();

      when(() => mockService.forceFetchDeviceInfo())
          .thenAnswer((_) async => freshDeviceInfo);

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider
              .overrideWithValue(DeviceInfoState(deviceInfo: cachedDeviceInfo)),
        ],
      );

      // Act
      final result =
          await container.read(sessionProvider.notifier).forceFetchDeviceInfo();

      // Assert - Should return fresh data, not cached
      expect(result.serialNumber, equals('FRESH_SN'));
      verify(() => mockService.forceFetchDeviceInfo()).called(1);
    });

    test('propagates UnauthorizedError from service', () async {
      // Arrange
      when(() => mockService.forceFetchDeviceInfo()).thenThrow(
        const UnauthorizedError(),
      );

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act & Assert
      await expectLater(
        () => container.read(sessionProvider.notifier).forceFetchDeviceInfo(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('propagates ResourceNotFoundError from service', () async {
      // Arrange
      when(() => mockService.forceFetchDeviceInfo()).thenThrow(
        const ResourceNotFoundError(),
      );

      container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(mockService),
          deviceInfoProvider.overrideWithValue(const DeviceInfoState()),
        ],
      );

      // Act & Assert
      await expectLater(
        () => container.read(sessionProvider.notifier).forceFetchDeviceInfo(),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });
  });
}
