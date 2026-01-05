// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_external.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';

void main() {
  group('PingStatusUIModel', () {
    test('initial() creates correct default state', () {
      const model = PingStatusUIModel.initial();

      expect(model.isRunning, isFalse);
      expect(model.pingLog, isEmpty);
    });

    test('copyWith preserves values when not specified', () {
      const model = PingStatusUIModel(
        isRunning: true,
        pingLog: 'ping test log',
      );

      final newModel = model.copyWith();

      expect(newModel.isRunning, isTrue);
      expect(newModel.pingLog, 'ping test log');
    });

    test('copyWith updates specified values', () {
      const model = PingStatusUIModel.initial();

      final newModel = model.copyWith(isRunning: true, pingLog: 'new log');

      expect(newModel.isRunning, isTrue);
      expect(newModel.pingLog, 'new log');
    });

    test('toMap and fromMap are symmetric', () {
      const model = PingStatusUIModel(
        isRunning: true,
        pingLog: 'test ping log content',
      );

      final map = model.toMap();
      final restored = PingStatusUIModel.fromMap(map);

      expect(restored, model);
    });

    test('toJson and fromJson are symmetric', () {
      const model = PingStatusUIModel(
        isRunning: false,
        pingLog: 'json test log',
      );

      final json = model.toJson();
      final restored = PingStatusUIModel.fromJson(json);

      expect(restored, model);
    });

    test('props returns correct list for equality', () {
      const model1 = PingStatusUIModel(isRunning: true, pingLog: 'log');
      const model2 = PingStatusUIModel(isRunning: true, pingLog: 'log');

      expect(model1, model2);
      expect(model1.hashCode, model2.hashCode);
    });
  });

  group('TracerouteStatusUIModel', () {
    test('initial() creates correct default state', () {
      const model = TracerouteStatusUIModel.initial();

      expect(model.isRunning, isFalse);
      expect(model.tracerouteLog, isEmpty);
    });

    test('copyWith preserves values when not specified', () {
      const model = TracerouteStatusUIModel(
        isRunning: true,
        tracerouteLog: 'traceroute log',
      );

      final newModel = model.copyWith();

      expect(newModel.isRunning, isTrue);
      expect(newModel.tracerouteLog, 'traceroute log');
    });

    test('toMap and fromMap are symmetric', () {
      const model = TracerouteStatusUIModel(
        isRunning: false,
        tracerouteLog: 'hop 1: 192.168.1.1',
      );

      final map = model.toMap();
      final restored = TracerouteStatusUIModel.fromMap(map);

      expect(restored, model);
    });

    test('props returns correct list for equality', () {
      const model1 =
          TracerouteStatusUIModel(isRunning: false, tracerouteLog: 'log');
      const model2 =
          TracerouteStatusUIModel(isRunning: false, tracerouteLog: 'log');

      expect(model1, model2);
    });
  });

  group('WANConnectionUIModel', () {
    test('fromJnap creates correct model from JNAP WANConnectionInfo', () {
      final jnapModel = WANConnectionInfo(
        wanType: 'DHCP',
        ipAddress: '192.168.1.100',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        mtu: 1500,
        dhcpLeaseMinutes: 1440,
        dnsServer1: '8.8.8.8',
        dnsServer2: '8.8.4.4',
        dnsServer3: '1.1.1.1',
      );

      final uiModel = WANConnectionUIModel.fromJnap(jnapModel);

      expect(uiModel.wanType, 'DHCP');
      expect(uiModel.ipAddress, '192.168.1.100');
      expect(uiModel.networkPrefixLength, 24);
      expect(uiModel.gateway, '192.168.1.1');
      expect(uiModel.mtu, 1500);
      expect(uiModel.dhcpLeaseMinutes, 1440);
      expect(uiModel.dnsServer1, '8.8.8.8');
      expect(uiModel.dnsServer2, '8.8.4.4');
      expect(uiModel.dnsServer3, '1.1.1.1');
    });

    test('copyWith updates specified values', () {
      const model = WANConnectionUIModel(
        wanType: 'DHCP',
        ipAddress: '192.168.1.100',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        mtu: 1500,
        dnsServer1: '8.8.8.8',
      );

      final newModel = model.copyWith(ipAddress: '10.0.0.1');

      expect(newModel.ipAddress, '10.0.0.1');
      expect(newModel.wanType, 'DHCP');
    });

    test('toMap and fromMap are symmetric', () {
      const model = WANConnectionUIModel(
        wanType: 'Static',
        ipAddress: '10.0.0.100',
        networkPrefixLength: 16,
        gateway: '10.0.0.1',
        mtu: 1400,
        dnsServer1: '8.8.8.8',
      );

      final map = model.toMap();
      final restored = WANConnectionUIModel.fromMap(map);

      expect(restored, model);
    });

    test('props returns correct list for equality', () {
      const model1 = WANConnectionUIModel(
        wanType: 'DHCP',
        ipAddress: '192.168.1.1',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        mtu: 1500,
        dnsServer1: '8.8.8.8',
      );
      const model2 = WANConnectionUIModel(
        wanType: 'DHCP',
        ipAddress: '192.168.1.1',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        mtu: 1500,
        dnsServer1: '8.8.8.8',
      );

      expect(model1, model2);
    });
  });

  group('RadioInfoUIModel', () {
    test('initial() creates correct default state', () {
      const model = RadioInfoUIModel.initial();

      expect(model.isBandSteeringSupported, isFalse);
      expect(model.radios, isEmpty);
    });

    test('fromJnap creates correct model from JNAP GetRadioInfo', () {
      final jnapModel = GetRadioInfo(
        isBandSteeringSupported: true,
        radios: const [
          RouterRadio(
            radioID: 'RADIO_2.4GHz',
            physicalRadioID: 'phy0',
            bssid: '00:11:22:33:44:55',
            band: '2.4GHz',
            supportedModes: ['802.11bgn'],
            supportedChannelsForChannelWidths: [],
            supportedSecurityTypes: ['WPA2-Personal'],
            maxRadiusSharedKeyLength: 64,
            settings: RouterRadioSettings(
              isEnabled: true,
              mode: '802.11bgn',
              ssid: 'TestNetwork',
              broadcastSSID: true,
              channelWidth: 'Auto',
              channel: 6,
              security: 'WPA2-Personal',
            ),
          ),
        ],
      );

      final uiModel = RadioInfoUIModel.fromJnap(jnapModel);

      expect(uiModel.isBandSteeringSupported, isTrue);
      expect(uiModel.radios.length, 1);
      expect(uiModel.radios.first.band, '2.4GHz');
      expect(uiModel.radios.first.ssid, 'TestNetwork');
      expect(uiModel.radios.first.isEnabled, isTrue);
    });

    test('toMap and fromMap are symmetric', () {
      const model = RadioInfoUIModel(
        isBandSteeringSupported: true,
        radios: [
          RouterRadioUIModel(
            radioID: 'RADIO_5GHz',
            band: '5GHz',
            isEnabled: true,
            ssid: 'MyNetwork_5G',
            channel: 36,
            channelWidth: '80MHz',
            security: 'WPA3-Personal',
          ),
        ],
      );

      final map = model.toMap();
      final restored = RadioInfoUIModel.fromMap(map);

      expect(restored, model);
    });
  });

  group('RouterRadioUIModel', () {
    test('fromJnap creates flattened model from nested JNAP RouterRadio', () {
      final jnapModel = RouterRadio(
        radioID: 'RADIO_2.4GHz',
        physicalRadioID: 'phy0',
        bssid: '00:11:22:33:44:55',
        band: '2.4GHz',
        supportedModes: const ['802.11bgn'],
        supportedChannelsForChannelWidths: const [],
        supportedSecurityTypes: const ['WPA2-Personal'],
        maxRadiusSharedKeyLength: 64,
        settings: RouterRadioSettings(
          isEnabled: false,
          mode: '802.11bgn',
          ssid: 'DisabledNetwork',
          broadcastSSID: false,
          channelWidth: '20MHz',
          channel: 11,
          security: 'WPA-Personal',
        ),
      );

      final uiModel = RouterRadioUIModel.fromJnap(jnapModel);

      expect(uiModel.radioID, 'RADIO_2.4GHz');
      expect(uiModel.band, '2.4GHz');
      expect(uiModel.isEnabled, isFalse);
      expect(uiModel.ssid, 'DisabledNetwork');
      expect(uiModel.channel, 11);
      expect(uiModel.channelWidth, '20MHz');
      expect(uiModel.security, 'WPA-Personal');
    });

    test('copyWith updates specified values', () {
      const model = RouterRadioUIModel(
        radioID: 'RADIO_2.4GHz',
        band: '2.4GHz',
        isEnabled: true,
        ssid: 'OriginalSSID',
        channel: 6,
        channelWidth: 'Auto',
        security: 'WPA2-Personal',
      );

      final newModel = model.copyWith(ssid: 'NewSSID', channel: 11);

      expect(newModel.ssid, 'NewSSID');
      expect(newModel.channel, 11);
      expect(newModel.band, '2.4GHz');
    });

    test('toMap and fromMap are symmetric', () {
      const model = RouterRadioUIModel(
        radioID: 'RADIO_5GHz',
        band: '5GHz',
        isEnabled: true,
        ssid: 'HighSpeed5G',
        channel: 149,
        channelWidth: '160MHz',
        security: 'WPA3-Personal',
      );

      final map = model.toMap();
      final restored = RouterRadioUIModel.fromMap(map);

      expect(restored, model);
    });
  });

  group('GuestRadioSettingsUIModel', () {
    test('initial() creates correct default state', () {
      const model = GuestRadioSettingsUIModel.initial();

      expect(model.isGuestNetworkACaptivePortal, isFalse);
      expect(model.isGuestNetworkEnabled, isFalse);
      expect(model.radios, isEmpty);
    });

    test('fromJnap creates correct model from JNAP GuestRadioSettings', () {
      const jnapModel = GuestRadioSettings(
        isGuestNetworkACaptivePortal: false,
        isGuestNetworkEnabled: true,
        radios: [
          GuestRadioInfo(
            radioID: 'RADIO_2.4GHz',
            isEnabled: true,
            broadcastGuestSSID: true,
            guestSSID: 'Guest_Network',
            canEnableRadio: true,
          ),
        ],
      );

      final uiModel = GuestRadioSettingsUIModel.fromJnap(jnapModel);

      expect(uiModel.isGuestNetworkACaptivePortal, isFalse);
      expect(uiModel.isGuestNetworkEnabled, isTrue);
      expect(uiModel.radios.length, 1);
      expect(uiModel.radios.first.guestSSID, 'Guest_Network');
    });

    test('toMap and fromMap are symmetric', () {
      const model = GuestRadioSettingsUIModel(
        isGuestNetworkACaptivePortal: true,
        isGuestNetworkEnabled: true,
        radios: [
          GuestRadioUIModel(
            radioID: 'RADIO_5GHz',
            isEnabled: true,
            broadcastGuestSSID: false,
            guestSSID: 'Hidden_Guest',
          ),
        ],
      );

      final map = model.toMap();
      final restored = GuestRadioSettingsUIModel.fromMap(map);

      expect(restored, model);
    });
  });

  group('GuestRadioUIModel', () {
    test('fromJnap creates correct model from JNAP GuestRadioInfo', () {
      const jnapModel = GuestRadioInfo(
        radioID: 'RADIO_2.4GHz',
        isEnabled: true,
        broadcastGuestSSID: true,
        guestSSID: 'GuestWiFi',
        canEnableRadio: true,
      );

      final uiModel = GuestRadioUIModel.fromJnap(jnapModel);

      expect(uiModel.radioID, 'RADIO_2.4GHz');
      expect(uiModel.isEnabled, isTrue);
      expect(uiModel.broadcastGuestSSID, isTrue);
      expect(uiModel.guestSSID, 'GuestWiFi');
    });

    test('copyWith updates specified values', () {
      const model = GuestRadioUIModel(
        radioID: 'RADIO_2.4GHz',
        isEnabled: true,
        broadcastGuestSSID: true,
        guestSSID: 'OriginalGuest',
      );

      final newModel = model.copyWith(guestSSID: 'NewGuest', isEnabled: false);

      expect(newModel.guestSSID, 'NewGuest');
      expect(newModel.isEnabled, isFalse);
      expect(newModel.broadcastGuestSSID, isTrue);
    });

    test('toMap and fromMap are symmetric', () {
      const model = GuestRadioUIModel(
        radioID: 'RADIO_5GHz',
        isEnabled: false,
        broadcastGuestSSID: false,
        guestSSID: 'VIP_Guest',
      );

      final map = model.toMap();
      final restored = GuestRadioUIModel.fromMap(map);

      expect(restored, model);
    });
  });

  group('WanExternalUIModel', () {
    test('initial() creates correct default state', () {
      const model = WanExternalUIModel.initial();

      expect(model.publicWanIPv4, isNull);
      expect(model.publicWanIPv6, isNull);
      expect(model.privateWanIPv4, isNull);
      expect(model.privateWanIPv6, isNull);
    });

    test('fromJnap creates correct model from JNAP WanExternal', () {
      const jnapModel = WanExternal(
        publicWanIPv4: '203.0.113.1',
        publicWanIPv6: '2001:db8::1',
        privateWanIPv4: '192.168.1.100',
        privateWanIPv6: 'fd00::100',
      );

      final uiModel = WanExternalUIModel.fromJnap(jnapModel);

      expect(uiModel.publicWanIPv4, '203.0.113.1');
      expect(uiModel.publicWanIPv6, '2001:db8::1');
      expect(uiModel.privateWanIPv4, '192.168.1.100');
      expect(uiModel.privateWanIPv6, 'fd00::100');
    });

    test('copyWith updates specified values', () {
      const model = WanExternalUIModel(
        publicWanIPv4: '203.0.113.1',
        privateWanIPv4: '192.168.1.100',
      );

      final newModel = model.copyWith(publicWanIPv4: '198.51.100.1');

      expect(newModel.publicWanIPv4, '198.51.100.1');
      expect(newModel.privateWanIPv4, '192.168.1.100');
    });

    test('toMap and fromMap are symmetric', () {
      const model = WanExternalUIModel(
        publicWanIPv4: '203.0.113.50',
        publicWanIPv6: '2001:db8::50',
        privateWanIPv4: '10.0.0.50',
        privateWanIPv6: 'fd00::50',
      );

      final map = model.toMap();
      final restored = WanExternalUIModel.fromMap(map);

      expect(restored, model);
    });

    test('toMap removes null values', () {
      const model = WanExternalUIModel(
        publicWanIPv4: '203.0.113.1',
      );

      final map = model.toMap();

      expect(map.containsKey('publicWanIPv4'), isTrue);
      expect(map.containsKey('publicWanIPv6'), isFalse);
      expect(map.containsKey('privateWanIPv4'), isFalse);
    });

    test('props returns correct list for equality', () {
      const model1 = WanExternalUIModel(publicWanIPv4: '1.2.3.4');
      const model2 = WanExternalUIModel(publicWanIPv4: '1.2.3.4');

      expect(model1, model2);
    });
  });
}
