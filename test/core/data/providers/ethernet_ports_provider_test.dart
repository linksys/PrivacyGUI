import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/ethernet_ports_provider.dart';

void main() {
  group('ethernetPortsProvider', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    CoreTransactionData createPollingData({
      Map<String, dynamic>? ethernetPortsOutput,
    }) {
      final data = <JNAPAction, JNAPResult>{};
      if (ethernetPortsOutput != null) {
        data[JNAPAction.getEthernetPortConnections] =
            JNAPSuccess(result: 'OK', output: ethernetPortsOutput);
      }
      return CoreTransactionData(lastUpdate: 1, isReady: true, data: data);
    }

    Map<String, dynamic> createEthernetPortsOutput({
      String wanPortConnection = 'Linked-1000Mbps',
      List<String> lanPortConnections = const [
        'Linked-100Mbps',
        'None',
        'None',
        'None'
      ],
    }) {
      return {
        'wanPortConnection': wanPortConnection,
        'lanPortConnections': lanPortConnections,
      };
    }

    test('returns empty EthernetPortsState when polling data is null', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final state = container.read(ethernetPortsProvider);

      // Assert
      expect(state.wanConnection, isNull);
      expect(state.lanConnections, isEmpty);
    });

    test('extracts wanConnection from getEthernetPortConnections action', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  ethernetPortsOutput: createEthernetPortsOutput(
                    wanPortConnection: 'Linked-1000Mbps',
                  ),
                ),
              )),
        ],
      );

      // Act
      final state = container.read(ethernetPortsProvider);

      // Assert
      expect(state.wanConnection, 'Linked-1000Mbps');
    });

    test('extracts lanConnections from getEthernetPortConnections action', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  ethernetPortsOutput: createEthernetPortsOutput(
                    lanPortConnections: [
                      'Linked-100Mbps',
                      'Linked-1000Mbps',
                      'None',
                      'None'
                    ],
                  ),
                ),
              )),
        ],
      );

      // Act
      final state = container.read(ethernetPortsProvider);

      // Assert
      expect(state.lanConnections.length, 4);
      expect(state.lanConnections[0], 'Linked-100Mbps');
      expect(state.lanConnections[1], 'Linked-1000Mbps');
      expect(state.lanConnections[2], 'None');
      expect(state.lanConnections[3], 'None');
    });

    test('returns empty lanConnections when lanPortConnections is null', () {
      // Arrange
      final pollingData = createPollingData(
        ethernetPortsOutput: {
          'wanPortConnection': 'Linked-1000Mbps',
          // lanPortConnections is missing
        },
      );
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(pollingData)),
        ],
      );

      // Act
      final state = container.read(ethernetPortsProvider);

      // Assert
      expect(state.wanConnection, 'Linked-1000Mbps');
      expect(state.lanConnections, isEmpty);
    });

    test(
        'returns empty state when getEthernetPortConnections returns JNAPError',
        () {
      // Arrange
      final data = <JNAPAction, JNAPResult>{
        JNAPAction.getEthernetPortConnections: const JNAPError(
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
      final state = container.read(ethernetPortsProvider);

      // Assert
      expect(state.wanConnection, isNull);
      expect(state.lanConnections, isEmpty);
    });

    test('handles different WAN connection states', () {
      // Test various connection states: None, Linked-100Mbps, Linked-1000Mbps
      final connectionStates = [
        'None',
        'Linked-100Mbps',
        'Linked-1000Mbps',
        'Linked-2500Mbps'
      ];

      for (final connectionState in connectionStates) {
        // Arrange
        container = ProviderContainer(
          overrides: [
            pollingProvider.overrideWith(() => _MockPollingNotifier(
                  createPollingData(
                    ethernetPortsOutput: createEthernetPortsOutput(
                      wanPortConnection: connectionState,
                    ),
                  ),
                )),
          ],
        );

        // Act
        final state = container.read(ethernetPortsProvider);

        // Assert
        expect(state.wanConnection, connectionState);

        container.dispose();
      }
    });

    group('EthernetPortsState', () {
      test('props returns correct list for equality comparison', () {
        // Arrange & Act
        const state1 = EthernetPortsState(
          wanConnection: 'Linked-1000Mbps',
          lanConnections: ['Linked-100Mbps', 'None'],
        );
        const state2 = EthernetPortsState(
          wanConnection: 'Linked-1000Mbps',
          lanConnections: ['Linked-100Mbps', 'None'],
        );
        const state3 = EthernetPortsState(
          wanConnection: 'None',
          lanConnections: ['Linked-100Mbps', 'None'],
        );

        // Assert
        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('default constructor creates empty state', () {
        // Arrange & Act
        const state = EthernetPortsState();

        // Assert
        expect(state.wanConnection, isNull);
        expect(state.lanConnections, isEmpty);
      });

      test('lanConnections with different content are not equal', () {
        // Arrange & Act
        const state1 = EthernetPortsState(
          lanConnections: ['Linked-100Mbps', 'None'],
        );
        const state2 = EthernetPortsState(
          lanConnections: ['Linked-1000Mbps', 'None'],
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
