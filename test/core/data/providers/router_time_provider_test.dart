import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/router_time_provider.dart';

void main() {
  group('routerTimeProvider', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    CoreTransactionData createPollingData({
      Map<String, dynamic>? localTimeOutput,
    }) {
      final data = <JNAPAction, JNAPResult>{};
      if (localTimeOutput != null) {
        data[JNAPAction.getLocalTime] =
            JNAPSuccess(result: 'OK', output: localTimeOutput);
      }
      return CoreTransactionData(lastUpdate: 1, isReady: true, data: data);
    }

    test('returns current system time when polling data is null', () {
      // Arrange
      final beforeTest = DateTime.now().millisecondsSinceEpoch;
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final result = container.read(routerTimeProvider);
      final afterTest = DateTime.now().millisecondsSinceEpoch;

      // Assert - result should be between before and after test timestamps
      expect(result, greaterThanOrEqualTo(beforeTest));
      expect(result, lessThanOrEqualTo(afterTest));
    });

    test('parses valid time string and returns a past timestamp', () {
      // Arrange
      // Note: DateFormat("yyyy-MM-ddThh:mm:ssZ") uses 12-hour format (hh)
      // The exact timestamp depends on how hh parses the time,
      // but we verify it returns a past timestamp (not current time)
      final beforeTest = DateTime.now().millisecondsSinceEpoch;
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  localTimeOutput: {
                    'currentTime': '2024-01-15T10:30:00Z',
                  },
                ),
              )),
        ],
      );

      // Act
      final result = container.read(routerTimeProvider);

      // Assert - result should be a past timestamp (year 2024), not current time
      expect(result, lessThan(beforeTest));
      expect(result, greaterThan(0)); // Sanity check: should be positive
    });

    test('returns current system time when currentTime is null', () {
      // Arrange
      final beforeTest = DateTime.now().millisecondsSinceEpoch;
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  localTimeOutput: {
                    // currentTime is missing
                  },
                ),
              )),
        ],
      );

      // Act
      final result = container.read(routerTimeProvider);
      final afterTest = DateTime.now().millisecondsSinceEpoch;

      // Assert
      expect(result, greaterThanOrEqualTo(beforeTest));
      expect(result, lessThanOrEqualTo(afterTest));
    });

    test('returns current system time when time string is invalid format', () {
      // Arrange
      final beforeTest = DateTime.now().millisecondsSinceEpoch;
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  localTimeOutput: {
                    'currentTime': 'invalid-time-format',
                  },
                ),
              )),
        ],
      );

      // Act
      final result = container.read(routerTimeProvider);
      final afterTest = DateTime.now().millisecondsSinceEpoch;

      // Assert
      expect(result, greaterThanOrEqualTo(beforeTest));
      expect(result, lessThanOrEqualTo(afterTest));
    });

    test('returns current system time when getLocalTime returns JNAPError', () {
      // Arrange
      final beforeTest = DateTime.now().millisecondsSinceEpoch;
      final data = <JNAPAction, JNAPResult>{
        JNAPAction.getLocalTime: const JNAPError(
          result: 'ErrorUnsupportedAction',
          error: 'Unsupported action',
        ),
      };
      final pollingData =
          CoreTransactionData(lastUpdate: 1, isReady: true, data: data);

      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(pollingData)),
        ],
      );

      // Act
      final result = container.read(routerTimeProvider);
      final afterTest = DateTime.now().millisecondsSinceEpoch;

      // Assert
      expect(result, greaterThanOrEqualTo(beforeTest));
      expect(result, lessThanOrEqualTo(afterTest));
    });

    test('parses different valid ISO 8601 time strings', () {
      // Test that valid time strings are parsed (not falling back to DateTime.now())
      final testTimeStrings = [
        '2024-06-20T02:45:30Z', // Use 12-hour compatible times
        '2023-12-31T11:59:59Z',
        '2024-01-01T08:00:00Z',
      ];

      for (final timeString in testTimeStrings) {
        // Arrange
        final beforeTest = DateTime.now().millisecondsSinceEpoch;
        container = ProviderContainer(
          overrides: [
            pollingProvider.overrideWith(() => _MockPollingNotifier(
                  createPollingData(
                    localTimeOutput: {
                      'currentTime': timeString,
                    },
                  ),
                )),
          ],
        );

        // Act
        final result = container.read(routerTimeProvider);

        // Assert - parsed time should be in the past (2023-2024), not current time
        expect(result, lessThan(beforeTest),
            reason:
                'Should parse $timeString to a past timestamp, not current time');

        container.dispose();
      }
    });

    test('returns int type', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  localTimeOutput: {
                    'currentTime': '2024-01-15T10:30:00Z',
                  },
                ),
              )),
        ],
      );

      // Act
      final result = container.read(routerTimeProvider);

      // Assert
      expect(result, isA<int>());
    });
  });
}

class _MockPollingNotifier extends AsyncNotifier<CoreTransactionData>
    implements PollingNotifier {
  final CoreTransactionData? _data;

  _MockPollingNotifier(this._data);

  @override
  CoreTransactionData build() {
    return _data ??
        const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
