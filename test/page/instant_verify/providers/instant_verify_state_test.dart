// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';

void main() {
  group('InstantVerifyState', () {
    test('initial() creates correct default state', () {
      final state = InstantVerifyState.initial();

      expect(state.wanConnection, isNull);
      expect(state.radioInfo, RadioInfoUIModel.initial());
      expect(state.guestRadioSettings, GuestRadioSettingsUIModel.initial());
      expect(state.wanExternal, isNull);
      expect(state.isRunning, isFalse);
    });

    test('copyWith preserves values when not specified', () {
      final state = InstantVerifyState(
        wanConnection: WANConnectionUIModel(
          wanType: 'DHCP',
          ipAddress: '192.168.1.100',
          networkPrefixLength: 24,
          gateway: '192.168.1.1',
          mtu: 1500,
          dnsServer1: '8.8.8.8',
        ),
        radioInfo: RadioInfoUIModel.initial(),
        guestRadioSettings: GuestRadioSettingsUIModel.initial(),
        isRunning: true,
      );

      final newState = state.copyWith();

      expect(newState.wanConnection, state.wanConnection);
      expect(newState.isRunning, isTrue);
    });

    test('copyWith updates specified values', () {
      final state = InstantVerifyState.initial();

      final newState = state.copyWith(isRunning: true);

      expect(newState.isRunning, isTrue);
      expect(newState.wanConnection, isNull);
    });

    test('toMap and fromMap are symmetric', () {
      final state = InstantVerifyState(
        wanConnection: WANConnectionUIModel(
          wanType: 'DHCP',
          ipAddress: '192.168.1.100',
          networkPrefixLength: 24,
          gateway: '192.168.1.1',
          mtu: 1500,
          dnsServer1: '8.8.8.8',
        ),
        radioInfo: RadioInfoUIModel(
          isBandSteeringSupported: true,
          radios: [
            RouterRadioUIModel(
              radioID: 'RADIO_2.4GHz',
              band: '2.4GHz',
              isEnabled: true,
              ssid: 'TestNetwork',
              channel: 6,
              channelWidth: 'Auto',
              security: 'WPA2-Personal',
            ),
          ],
        ),
        guestRadioSettings: GuestRadioSettingsUIModel(
          isGuestNetworkACaptivePortal: false,
          isGuestNetworkEnabled: true,
          radios: [
            GuestRadioUIModel(
              radioID: 'RADIO_2.4GHz',
              isEnabled: true,
              broadcastGuestSSID: true,
              guestSSID: 'GuestNetwork',
            ),
          ],
        ),
        wanExternal: WanExternalUIModel(
          publicWanIPv4: '203.0.113.1',
          privateWanIPv4: '192.168.1.100',
        ),
        isRunning: false,
      );

      final map = state.toMap();
      final restored = InstantVerifyState.fromMap(map);

      expect(restored, state);
    });

    test('props returns correct list for equality', () {
      final state1 = InstantVerifyState.initial();
      final state2 = InstantVerifyState.initial();

      expect(state1, state2);
      expect(state1.hashCode, state2.hashCode);
    });
  });
}
