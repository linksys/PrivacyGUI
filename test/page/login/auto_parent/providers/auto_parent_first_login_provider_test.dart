import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/data/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/page/login/auto_parent/providers/auto_parent_first_login_provider.dart';
import 'package:privacy_gui/page/login/auto_parent/services/auto_parent_first_login_service.dart';

import '../../../../mocks/firmware_update_notifier_mocks.dart';

// Mocks (Mocktail)
class MockAutoParentFirstLoginService extends Mock
    implements AutoParentFirstLoginService {}

/// Mock polling notifier that tracks paused state
class _MockPollingNotifier extends PollingNotifier {
  bool _pausedValue = false;

  @override
  set paused(bool value) => _pausedValue = value;

  @override
  bool get paused => _pausedValue;

  @override
  CoreTransactionData build() =>
      const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});
}

void main() {
  late MockAutoParentFirstLoginService mockService;
  late MockFirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late _MockPollingNotifier mockPollingNotifier;
  late ProviderContainer container;

  setUp(() {
    mockService = MockAutoParentFirstLoginService();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockPollingNotifier = _MockPollingNotifier();
    container = ProviderContainer(overrides: [
      autoParentFirstLoginServiceProvider.overrideWithValue(mockService),
      firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      pollingProvider.overrideWith(() => mockPollingNotifier),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  // ===========================================================================
  // User Story 3 - finishFirstTimeLogin Tests (T025-T028)
  // ===========================================================================

  group('AutoParentFirstLoginNotifier - finishFirstTimeLogin', () {
    test('delegates to Service methods', () async {
      // Arrange
      when(() => mockService.checkInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockService.setUserAcknowledgedAutoConfiguration())
          .thenAnswer((_) async {});
      when(() => mockService.setFirmwareUpdatePolicy())
          .thenAnswer((_) async {});

      // Act
      await container
          .read(autoParentFirstLoginProvider.notifier)
          .finishFirstTimeLogin();

      // Assert
      verify(() => mockService.checkInternetConnection()).called(1);
      verify(() => mockService.setUserAcknowledgedAutoConfiguration())
          .called(1);
      verify(() => mockService.setFirmwareUpdatePolicy()).called(1);
    });

    test('awaits setUserAcknowledgedAutoConfiguration', () async {
      // Arrange
      var acknowledgeCompleted = false;
      when(() => mockService.checkInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockService.setUserAcknowledgedAutoConfiguration())
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        acknowledgeCompleted = true;
      });
      when(() => mockService.setFirmwareUpdatePolicy()).thenAnswer((_) async {
        // This should run AFTER setUserAcknowledgedAutoConfiguration completes
        expect(acknowledgeCompleted, isTrue,
            reason:
                'setFirmwareUpdatePolicy should run after setUserAcknowledgedAutoConfiguration');
      });

      // Act
      await container
          .read(autoParentFirstLoginProvider.notifier)
          .finishFirstTimeLogin();

      // Assert
      expect(acknowledgeCompleted, isTrue);
    });

    test('awaits setFirmwareUpdatePolicy', () async {
      // Arrange
      var policyCompleted = false;
      when(() => mockService.checkInternetConnection())
          .thenAnswer((_) async => true);
      when(() => mockService.setUserAcknowledgedAutoConfiguration())
          .thenAnswer((_) async {});
      when(() => mockService.setFirmwareUpdatePolicy()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        policyCompleted = true;
      });

      // Act
      await container
          .read(autoParentFirstLoginProvider.notifier)
          .finishFirstTimeLogin();

      // Assert - finishFirstTimeLogin should wait for setFirmwareUpdatePolicy
      expect(policyCompleted, isTrue);
    });

    test('skips acknowledgment when failCheck is true', () async {
      // Arrange
      when(() => mockService.setFirmwareUpdatePolicy())
          .thenAnswer((_) async {});

      // Act
      await container
          .read(autoParentFirstLoginProvider.notifier)
          .finishFirstTimeLogin(true);

      // Assert
      verifyNever(() => mockService.checkInternetConnection());
      verifyNever(() => mockService.setUserAcknowledgedAutoConfiguration());
      verify(() => mockService.setFirmwareUpdatePolicy()).called(1);
    });
  });

  // ===========================================================================
  // checkAndAutoInstallFirmware Tests (for coverage)
  // ===========================================================================

  group('AutoParentFirstLoginNotifier - checkAndAutoInstallFirmware', () {
    test('pauses polling and checks for firmware updates', () async {
      // Arrange - Mockito syntax for MockFirmwareUpdateNotifier
      mockito
          .when(mockFirmwareUpdateNotifier.fetchAvailableFirmwareUpdates())
          .thenAnswer((_) async {});
      mockito
          .when(mockFirmwareUpdateNotifier.isFailedCheckFirmwareUpdate())
          .thenReturn(false);
      mockito
          .when(mockFirmwareUpdateNotifier.getAvailableUpdateNumber())
          .thenReturn(0);

      // Act
      final result = await container
          .read(autoParentFirstLoginProvider.notifier)
          .checkAndAutoInstallFirmware();

      // Assert
      expect(result, isFalse);
      expect(mockPollingNotifier.paused, isTrue);
      mockito
          .verify(mockFirmwareUpdateNotifier.fetchAvailableFirmwareUpdates())
          .called(1);
    });

    test('throws exception when firmware check fails', () async {
      // Arrange - Mockito syntax
      mockito
          .when(mockFirmwareUpdateNotifier.fetchAvailableFirmwareUpdates())
          .thenAnswer((_) async {});
      mockito
          .when(mockFirmwareUpdateNotifier.isFailedCheckFirmwareUpdate())
          .thenReturn(true);

      // Act & Assert
      expect(
        () => container
            .read(autoParentFirstLoginProvider.notifier)
            .checkAndAutoInstallFirmware(),
        throwsA(isA<Exception>()),
      );
    });

    test('returns true and updates firmware when new firmware available',
        () async {
      // Arrange - Mockito syntax
      mockito
          .when(mockFirmwareUpdateNotifier.fetchAvailableFirmwareUpdates())
          .thenAnswer((_) async {});
      mockito
          .when(mockFirmwareUpdateNotifier.isFailedCheckFirmwareUpdate())
          .thenReturn(false);
      mockito
          .when(mockFirmwareUpdateNotifier.getAvailableUpdateNumber())
          .thenReturn(1);
      mockito
          .when(mockFirmwareUpdateNotifier.updateFirmware())
          .thenAnswer((_) async {});

      // Act
      final result = await container
          .read(autoParentFirstLoginProvider.notifier)
          .checkAndAutoInstallFirmware();

      // Assert
      expect(result, isTrue);
      mockito.verify(mockFirmwareUpdateNotifier.updateFirmware()).called(1);
    });

    test('returns false when no firmware updates available', () async {
      // Arrange - Mockito syntax
      mockito
          .when(mockFirmwareUpdateNotifier.fetchAvailableFirmwareUpdates())
          .thenAnswer((_) async {});
      mockito
          .when(mockFirmwareUpdateNotifier.isFailedCheckFirmwareUpdate())
          .thenReturn(false);
      mockito
          .when(mockFirmwareUpdateNotifier.getAvailableUpdateNumber())
          .thenReturn(0);

      // Act
      final result = await container
          .read(autoParentFirstLoginProvider.notifier)
          .checkAndAutoInstallFirmware();

      // Assert
      expect(result, isFalse);
      mockito.verifyNever(mockFirmwareUpdateNotifier.updateFirmware());
    });
  });
}
