import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/services/polling_service.dart';

import '../../../mocks/test_data/polling_test_data.dart';

class MockPollingService extends Mock implements PollingService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoreTransactionData', () {
    test('creates with required parameters', () {
      // Act
      const data = CoreTransactionData(
        lastUpdate: 123456,
        isReady: true,
        data: {},
      );

      // Assert
      expect(data.lastUpdate, equals(123456));
      expect(data.isReady, isTrue);
      expect(data.data, isEmpty);
    });

    test('copyWith updates lastUpdate', () {
      // Arrange
      const original = CoreTransactionData(
        lastUpdate: 100,
        isReady: false,
        data: {},
      );

      // Act
      final updated = original.copyWith(lastUpdate: 200);

      // Assert
      expect(updated.lastUpdate, equals(200));
      expect(updated.isReady, isFalse);
      expect(updated.data, isEmpty);
    });

    test('copyWith updates isReady', () {
      // Arrange
      const original = CoreTransactionData(
        lastUpdate: 100,
        isReady: false,
        data: {},
      );

      // Act
      final updated = original.copyWith(isReady: true);

      // Assert
      expect(updated.lastUpdate, equals(100));
      expect(updated.isReady, isTrue);
    });

    test('copyWith updates data', () {
      // Arrange
      const original = CoreTransactionData(
        lastUpdate: 100,
        isReady: false,
        data: {},
      );
      final newData = <JNAPAction, JNAPResult>{
        JNAPAction.getDeviceInfo: PollingTestData.createDeviceInfoSuccess(),
      };

      // Act
      final updated = original.copyWith(data: newData);

      // Assert
      expect(updated.data, isNotEmpty);
      expect(updated.data.containsKey(JNAPAction.getDeviceInfo), isTrue);
    });

    test('equality works correctly', () {
      // Arrange
      const data1 = CoreTransactionData(
        lastUpdate: 100,
        isReady: true,
        data: {},
      );
      const data2 = CoreTransactionData(
        lastUpdate: 100,
        isReady: true,
        data: {},
      );
      const data3 = CoreTransactionData(
        lastUpdate: 200,
        isReady: true,
        data: {},
      );

      // Assert
      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
    });

    test('props includes all fields', () {
      // Arrange
      const data = CoreTransactionData(
        lastUpdate: 100,
        isReady: true,
        data: {},
      );

      // Assert
      expect(data.props, hasLength(3));
      expect(data.props, contains(100));
      expect(data.props, contains(true));
    });
  });

  group('PollingNotifier - build', () {
    test('returns initial state with default values', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          pollingServiceProvider.overrideWithValue(MockPollingService()),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final state = container.read(pollingProvider);

      // Assert
      expect(state.value, isNotNull);
      expect(state.value?.lastUpdate, equals(0));
      expect(state.value?.isReady, isFalse);
      expect(state.value?.data, isEmpty);
    });
  });

  group('PollingNotifier - init', () {
    test('resets state to initial values', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          pollingServiceProvider.overrideWithValue(MockPollingService()),
        ],
      );
      addTearDown(container.dispose);

      // Act
      container.read(pollingProvider.notifier).init();
      final state = container.read(pollingProvider);

      // Assert
      expect(state.value?.lastUpdate, equals(0));
      expect(state.value?.isReady, isFalse);
      expect(state.value?.data, isEmpty);
    });
  });

  group('PollingNotifier - paused', () {
    test('getter returns initial paused state as false', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          pollingServiceProvider.overrideWithValue(MockPollingService()),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final paused = container.read(pollingProvider.notifier).paused;

      // Assert
      expect(paused, isFalse);
    });

    test('setter updates paused state', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          pollingServiceProvider.overrideWithValue(MockPollingService()),
        ],
      );
      addTearDown(container.dispose);

      // Act
      container.read(pollingProvider.notifier).paused = true;

      // Assert
      expect(container.read(pollingProvider.notifier).paused, isTrue);
    });
  });

  group('PollingNotifier - stopPolling', () {
    test('can be called without error', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          pollingServiceProvider.overrideWithValue(MockPollingService()),
        ],
      );
      addTearDown(container.dispose);

      // Act & Assert - should not throw
      expect(
        () => container.read(pollingProvider.notifier).stopPolling(),
        returnsNormally,
      );
    });
  });
}
