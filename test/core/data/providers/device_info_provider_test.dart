import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/device_info_provider.dart';

void main() {
  group('deviceInfoProvider', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    CoreTransactionData createPollingData({
      Map<String, dynamic>? deviceInfoOutput,
      Map<String, dynamic>? softSkuOutput,
    }) {
      final data = <JNAPAction, JNAPResult>{};
      if (deviceInfoOutput != null) {
        data[JNAPAction.getDeviceInfo] =
            JNAPSuccess(result: 'OK', output: deviceInfoOutput);
      }
      if (softSkuOutput != null) {
        data[JNAPAction.getSoftSKUSettings] =
            JNAPSuccess(result: 'OK', output: softSkuOutput);
      }
      return CoreTransactionData(lastUpdate: 1, isReady: true, data: data);
    }

    test('returns empty DeviceInfoState when polling data is null', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final state = container.read(deviceInfoProvider);

      // Assert
      expect(state.deviceInfo, isNull);
      expect(state.skuModelNumber, isNull);
    });

    test('extracts deviceInfo from getDeviceInfo action', () {
      // Arrange
      final deviceInfoOutput = {
        'serialNumber': 'TEST123456',
        'modelNumber': 'MX5300',
        'hardwareVersion': '1',
        'manufacturer': 'Linksys',
        'description': 'Test Router',
        'firmwareVersion': '1.0.0',
        'firmwareDate': '2024-01-01T00:00:00Z',
        'services': const ['http://linksys.com/jnap/core/Core'],
      };

      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(deviceInfoOutput: deviceInfoOutput),
              )),
        ],
      );

      // Act
      final state = container.read(deviceInfoProvider);

      // Assert
      expect(state.deviceInfo, isNotNull);
      expect(state.deviceInfo!.serialNumber, 'TEST123456');
      expect(state.deviceInfo!.modelNumber, 'MX5300');
      expect(state.deviceInfo!.hardwareVersion, '1');
    });

    test('extracts skuModelNumber from getSoftSKUSettings action', () {
      // Arrange
      final deviceInfoOutput = {
        'serialNumber': 'TEST123456',
        'modelNumber': 'MX5300',
        'hardwareVersion': '1',
        'manufacturer': 'Linksys',
        'description': 'Test Router',
        'firmwareVersion': '1.0.0',
        'firmwareDate': '2024-01-01T00:00:00Z',
        'services': const <String>[],
      };

      final softSkuOutput = {
        'modelNumber': 'MX5300-SKU',
        'isChangeable': false,
      };

      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  deviceInfoOutput: deviceInfoOutput,
                  softSkuOutput: softSkuOutput,
                ),
              )),
        ],
      );

      // Act
      final state = container.read(deviceInfoProvider);

      // Assert
      expect(state.skuModelNumber, 'MX5300-SKU');
    });

    test('returns null skuModelNumber when getSoftSKUSettings is missing', () {
      // Arrange
      final deviceInfoOutput = {
        'serialNumber': 'TEST123456',
        'modelNumber': 'MX5300',
        'hardwareVersion': '1',
        'manufacturer': 'Linksys',
        'description': 'Test Router',
        'firmwareVersion': '1.0.0',
        'firmwareDate': '2024-01-01T00:00:00Z',
        'services': const <String>[],
      };

      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(deviceInfoOutput: deviceInfoOutput),
              )),
        ],
      );

      // Act
      final state = container.read(deviceInfoProvider);

      // Assert
      expect(state.deviceInfo, isNotNull);
      expect(state.skuModelNumber, isNull);
    });

    test('returns null deviceInfo when getDeviceInfo returns JNAPError', () {
      // Arrange
      final data = <JNAPAction, JNAPResult>{
        JNAPAction.getDeviceInfo: const JNAPError(
          result: 'ErrorDeviceNotFound',
          error: 'Device not found',
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
      final state = container.read(deviceInfoProvider);

      // Assert
      expect(state.deviceInfo, isNull);
    });

    group('DeviceInfoState', () {
      test('props returns correct list for equality comparison', () {
        // Arrange & Act
        const state1 = DeviceInfoState(skuModelNumber: 'SKU1');
        const state2 = DeviceInfoState(skuModelNumber: 'SKU1');
        const state3 = DeviceInfoState(skuModelNumber: 'SKU2');

        // Assert
        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('default constructor creates empty state', () {
        // Arrange & Act
        const state = DeviceInfoState();

        // Assert
        expect(state.deviceInfo, isNull);
        expect(state.skuModelNumber, isNull);
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
