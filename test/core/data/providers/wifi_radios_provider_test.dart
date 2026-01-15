import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/wifi_radios_provider.dart';

void main() {
  group('wifiRadiosProvider', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    CoreTransactionData createPollingData({
      Map<String, dynamic>? radioInfoOutput,
      Map<String, dynamic>? guestRadioOutput,
    }) {
      final data = <JNAPAction, JNAPResult>{};
      if (radioInfoOutput != null) {
        data[JNAPAction.getRadioInfo] =
            JNAPSuccess(result: 'OK', output: radioInfoOutput);
      }
      if (guestRadioOutput != null) {
        data[JNAPAction.getGuestRadioSettings] =
            JNAPSuccess(result: 'OK', output: guestRadioOutput);
      }
      return CoreTransactionData(lastUpdate: 1, isReady: true, data: data);
    }

    Map<String, dynamic> createRadioInfoOutput({
      int radioCount = 2,
    }) {
      final radios = <Map<String, dynamic>>[];
      if (radioCount >= 1) {
        radios.add({
          'radioID': 'RADIO_2.4GHz',
          'physicalRadioID': 'wl0',
          'bssid': 'AA:BB:CC:DD:EE:01',
          'band': '2.4GHz',
          'supportedModes': const ['802.11b/g/n'],
          'supportedChannelsForChannelWidths': const [
            {
              'channelWidth': 'Auto',
              'channels': [1, 6, 11],
            }
          ],
          'supportedSecurityTypes': const ['None', 'WPA2-Personal'],
          'maxRADIUSSharedKeyLength': 64,
          'settings': {
            'isEnabled': true,
            'mode': '802.11b/g/n',
            'ssid': 'TestNetwork-2.4',
            'broadcastSSID': true,
            'channelWidth': 'Auto',
            'channel': 6,
            'security': 'WPA2-Personal',
            'wpaPersonalSettings': {
              'passphrase': 'password123',
            },
          },
        });
      }
      if (radioCount >= 2) {
        radios.add({
          'radioID': 'RADIO_5GHz',
          'physicalRadioID': 'wl1',
          'bssid': 'AA:BB:CC:DD:EE:02',
          'band': '5GHz',
          'supportedModes': const ['802.11a/n/ac'],
          'supportedChannelsForChannelWidths': const [
            {
              'channelWidth': 'Auto',
              'channels': [36, 40, 44, 48],
            }
          ],
          'supportedSecurityTypes': const ['None', 'WPA2-Personal'],
          'maxRADIUSSharedKeyLength': 64,
          'settings': {
            'isEnabled': true,
            'mode': '802.11a/n/ac',
            'ssid': 'TestNetwork-5',
            'broadcastSSID': true,
            'channelWidth': 'Auto',
            'channel': 36,
            'security': 'WPA2-Personal',
            'wpaPersonalSettings': {
              'passphrase': 'password123',
            },
          },
        });
      }
      return {
        'isBandSteeringSupported': true,
        'radios': radios,
      };
    }

    Map<String, dynamic> createGuestRadioOutput({
      bool isGuestNetworkEnabled = true,
    }) {
      return {
        'isGuestNetworkACaptivePortal': false,
        'isGuestNetworkEnabled': isGuestNetworkEnabled,
        'radios': [
          {
            'radioID': 'RADIO_2.4GHz',
            'isEnabled': true,
            'broadcastGuestSSID': true,
            'guestSSID': 'Guest-Network',
            'guestWPAPassphrase': 'guestpass123',
            'canEnableRadio': true,
          },
          {
            'radioID': 'RADIO_5GHz',
            'isEnabled': true,
            'broadcastGuestSSID': true,
            'guestSSID': 'Guest-Network',
            'guestWPAPassphrase': 'guestpass123',
            'canEnableRadio': true,
          },
        ],
      };
    }

    test('returns empty WifiRadiosState when polling data is null', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(null)),
        ],
      );

      // Act
      final state = container.read(wifiRadiosProvider);

      // Assert
      expect(state.mainRadios, isEmpty);
      expect(state.guestRadios, isEmpty);
      expect(state.isGuestNetworkEnabled, isFalse);
    });

    test('extracts mainRadios from getRadioInfo action', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(radioInfoOutput: createRadioInfoOutput()),
              )),
        ],
      );

      // Act
      final state = container.read(wifiRadiosProvider);

      // Assert
      expect(state.mainRadios.length, 2);
      expect(state.mainRadios[0].radioID, 'RADIO_2.4GHz');
      expect(state.mainRadios[0].band, '2.4GHz');
      expect(state.mainRadios[1].radioID, 'RADIO_5GHz');
      expect(state.mainRadios[1].band, '5GHz');
    });

    test(
        'extracts guestRadios and isGuestNetworkEnabled from getGuestRadioSettings',
        () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  radioInfoOutput: createRadioInfoOutput(),
                  guestRadioOutput: createGuestRadioOutput(
                    isGuestNetworkEnabled: true,
                  ),
                ),
              )),
        ],
      );

      // Act
      final state = container.read(wifiRadiosProvider);

      // Assert
      expect(state.guestRadios.length, 2);
      expect(state.guestRadios[0].radioID, 'RADIO_2.4GHz');
      expect(state.guestRadios[0].guestSSID, 'Guest-Network');
      expect(state.isGuestNetworkEnabled, isTrue);
    });

    test('returns isGuestNetworkEnabled false when guest network is disabled',
        () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(
                  radioInfoOutput: createRadioInfoOutput(),
                  guestRadioOutput: createGuestRadioOutput(
                    isGuestNetworkEnabled: false,
                  ),
                ),
              )),
        ],
      );

      // Act
      final state = container.read(wifiRadiosProvider);

      // Assert
      expect(state.isGuestNetworkEnabled, isFalse);
    });

    test('returns empty guestRadios when getGuestRadioSettings is missing', () {
      // Arrange
      container = ProviderContainer(
        overrides: [
          pollingProvider.overrideWith(() => _MockPollingNotifier(
                createPollingData(radioInfoOutput: createRadioInfoOutput()),
              )),
        ],
      );

      // Act
      final state = container.read(wifiRadiosProvider);

      // Assert
      expect(state.mainRadios.length, 2);
      expect(state.guestRadios, isEmpty);
      expect(state.isGuestNetworkEnabled, isFalse);
    });

    test('returns empty mainRadios when getRadioInfo returns JNAPError', () {
      // Arrange
      final data = <JNAPAction, JNAPResult>{
        JNAPAction.getRadioInfo: const JNAPError(
          result: 'ErrorRadioNotFound',
          error: 'Radio not found',
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
      final state = container.read(wifiRadiosProvider);

      // Assert
      expect(state.mainRadios, isEmpty);
    });

    group('WifiRadiosState', () {
      test('props returns correct list for equality comparison', () {
        // Arrange & Act
        const state1 = WifiRadiosState(isGuestNetworkEnabled: true);
        const state2 = WifiRadiosState(isGuestNetworkEnabled: true);
        const state3 = WifiRadiosState(isGuestNetworkEnabled: false);

        // Assert
        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('default constructor creates empty state', () {
        // Arrange & Act
        const state = WifiRadiosState();

        // Assert
        expect(state.mainRadios, isEmpty);
        expect(state.guestRadios, isEmpty);
        expect(state.isGuestNetworkEnabled, isFalse);
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
