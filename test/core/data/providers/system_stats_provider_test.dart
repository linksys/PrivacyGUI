import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/system_stats_provider.dart';

void main() {
  group('systemStatsProvider', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    CoreTransactionData createPollingData({
      Map<String, dynamic>? systemStatsOutput,
    }) {
      final data = <JNAPAction, JNAPResult>{};
      if (systemStatsOutput != null) {
        data[JNAPAction.getSystemStats] =
            JNAPSuccess(result: 'OK', output: systemStatsOutput);
      }
      return CoreTransactionData(lastUpdate: 1, isReady: true, data: data);
    }

    Map<String, dynamic> createSystemStatsOutput({
      int uptimeSeconds = 86400,
      String cpuLoad = '15%',
      String memoryLoad = '45%',
    }) {
      return {
        'uptimeSeconds': uptimeSeconds,
        'CPULoad': cpuLoad,
        'MemoryLoad': memoryLoad,
      };
    }

    test('returns default SystemStatsState when polling data is null', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final state = container.read(systemStatsProvider);

      // Assert
      expect(state.uptimes, 0);
      expect(state.cpuLoad, isNull);
      expect(state.memoryLoad, isNull);
    });

    test('extracts uptimes from getSystemStats action', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  systemStatsOutput: createSystemStatsOutput(
                    uptimeSeconds: 172800,
                  ),
                ),
              )),
        ],
      );

      // Act
      final state = container.read(systemStatsProvider);

      // Assert
      expect(state.uptimes, 172800);
    });

    test('extracts cpuLoad from getSystemStats action', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  systemStatsOutput: createSystemStatsOutput(
                    cpuLoad: '25%',
                  ),
                ),
              )),
        ],
      );

      // Act
      final state = container.read(systemStatsProvider);

      // Assert
      expect(state.cpuLoad, '25%');
    });

    test('extracts memoryLoad from getSystemStats action', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  systemStatsOutput: createSystemStatsOutput(
                    memoryLoad: '60%',
                  ),
                ),
              )),
        ],
      );

      // Act
      final state = container.read(systemStatsProvider);

      // Assert
      expect(state.memoryLoad, '60%');
    });

    test('extracts all fields from getSystemStats action', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  systemStatsOutput: createSystemStatsOutput(
                    uptimeSeconds: 259200,
                    cpuLoad: '35%',
                    memoryLoad: '70%',
                  ),
                ),
              )),
        ],
      );

      // Act
      final state = container.read(systemStatsProvider);

      // Assert
      expect(state.uptimes, 259200);
      expect(state.cpuLoad, '35%');
      expect(state.memoryLoad, '70%');
    });

    test('returns default uptimes (0) when uptimeSeconds is null', () {
      // Arrange
      final pollingData = createPollingData(
        systemStatsOutput: {
          'CPULoad': '15%',
          'MemoryLoad': '45%',
          // uptimeSeconds is missing
        },
      );
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(pollingData)),
        ],
      );

      // Act
      final state = container.read(systemStatsProvider);

      // Assert
      expect(state.uptimes, 0);
      expect(state.cpuLoad, '15%');
      expect(state.memoryLoad, '45%');
    });

    test('returns default state when getSystemStats returns JNAPError', () {
      // Arrange
      final data = <JNAPAction, JNAPResult>{
        JNAPAction.getSystemStats: const JNAPError(
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
      final state = container.read(systemStatsProvider);

      // Assert
      expect(state.uptimes, 0);
      expect(state.cpuLoad, isNull);
      expect(state.memoryLoad, isNull);
    });

    test('handles partial data with only uptimeSeconds', () {
      // Arrange
      final pollingData = createPollingData(
        systemStatsOutput: {
          'uptimeSeconds': 43200,
          // CPULoad and MemoryLoad are missing
        },
      );
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(pollingData)),
        ],
      );

      // Act
      final state = container.read(systemStatsProvider);

      // Assert
      expect(state.uptimes, 43200);
      expect(state.cpuLoad, isNull);
      expect(state.memoryLoad, isNull);
    });

    group('SystemStatsState', () {
      test('props returns correct list for equality comparison', () {
        // Arrange & Act
        const state1 = SystemStatsState(
          uptimes: 86400,
          cpuLoad: '15%',
          memoryLoad: '45%',
        );
        const state2 = SystemStatsState(
          uptimes: 86400,
          cpuLoad: '15%',
          memoryLoad: '45%',
        );
        const state3 = SystemStatsState(
          uptimes: 172800,
          cpuLoad: '15%',
          memoryLoad: '45%',
        );

        // Assert
        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('default constructor creates state with default values', () {
        // Arrange & Act
        const state = SystemStatsState();

        // Assert
        expect(state.uptimes, 0);
        expect(state.cpuLoad, isNull);
        expect(state.memoryLoad, isNull);
      });

      test('states with different cpuLoad are not equal', () {
        // Arrange & Act
        const state1 = SystemStatsState(
          uptimes: 86400,
          cpuLoad: '15%',
        );
        const state2 = SystemStatsState(
          uptimes: 86400,
          cpuLoad: '25%',
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('states with different memoryLoad are not equal', () {
        // Arrange & Act
        const state1 = SystemStatsState(
          uptimes: 86400,
          memoryLoad: '45%',
        );
        const state2 = SystemStatsState(
          uptimes: 86400,
          memoryLoad: '60%',
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });
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
