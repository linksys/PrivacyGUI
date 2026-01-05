// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/wan_external.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';
import 'package:privacy_gui/page/instant_verify/services/instant_verify_service.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late InstantVerifyService service;
  late MockRouterRepository mockRouterRepository;

  setUp(() {
    mockRouterRepository = MockRouterRepository();
    service = InstantVerifyService(mockRouterRepository);
  });

  group('InstantVerifyService', () {
    group('parseWanConnection', () {
      test('returns null when getWANStatus is not in polling data', () {
        final pollingData = <JNAPAction, JNAPResult>{};

        final result = service.parseWanConnection(pollingData);

        expect(result, isNull);
      });

      test('returns null when wanConnection is null in WAN status', () {
        final wanStatusOutput = {
          'macAddress': '00:11:22:33:44:55',
          'detectedWANType': 'DHCP',
          'wanStatus': 'Connected',
          'wanIPv6Status': 'Disconnected',
          'wanConnection': null,
          'supportedWANTypes': ['DHCP', 'Static'],
          'supportedIPv6WANTypes': [],
        };
        final pollingData = <JNAPAction, JNAPResult>{
          JNAPAction.getWANStatus:
              JNAPSuccess(result: 'OK', output: wanStatusOutput),
        };

        final result = service.parseWanConnection(pollingData);

        expect(result, isNull);
      });

      test('returns WANConnectionUIModel when valid WAN connection exists', () {
        final wanStatusOutput = {
          'macAddress': '00:11:22:33:44:55',
          'detectedWANType': 'DHCP',
          'wanStatus': 'Connected',
          'wanIPv6Status': 'Disconnected',
          'wanConnection': {
            'wanType': 'DHCP',
            'ipAddress': '192.168.1.100',
            'networkPrefixLength': 24,
            'gateway': '192.168.1.1',
            'mtu': 1500,
            'dnsServer1': '8.8.8.8',
            'dnsServer2': '8.8.4.4',
          },
          'supportedWANTypes': ['DHCP', 'Static'],
          'supportedIPv6WANTypes': [],
        };
        final pollingData = <JNAPAction, JNAPResult>{
          JNAPAction.getWANStatus:
              JNAPSuccess(result: 'OK', output: wanStatusOutput),
        };

        final result = service.parseWanConnection(pollingData);

        expect(result, isNotNull);
        expect(result!.wanType, 'DHCP');
        expect(result.ipAddress, '192.168.1.100');
        expect(result.gateway, '192.168.1.1');
        expect(result.dnsServer1, '8.8.8.8');
      });
    });

    group('parseRadioInfo', () {
      test('returns initial model when getRadioInfo is not in polling data',
          () {
        final pollingData = <JNAPAction, JNAPResult>{};

        final result = service.parseRadioInfo(pollingData);

        expect(result, RadioInfoUIModel.initial());
      });

      test('returns RadioInfoUIModel when valid radio info exists', () {
        final radioInfoOutput = {
          'isBandSteeringSupported': true,
          'radios': [
            {
              'radioID': 'RADIO_2.4GHz',
              'physicalRadioID': 'phy0',
              'bssid': '00:11:22:33:44:55',
              'band': '2.4GHz',
              'supportedModes': ['802.11bgn'],
              'supportedChannelsForChannelWidths': [],
              'supportedSecurityTypes': ['WPA2-Personal'],
              'maxRADIUSSharedKeyLength': 64,
              'settings': {
                'isEnabled': true,
                'mode': '802.11bgn',
                'ssid': 'MyNetwork_2.4G',
                'broadcastSSID': true,
                'channelWidth': 'Auto',
                'channel': 6,
                'security': 'WPA2-Personal',
                'wpaPersonalSettings': {
                  'passphrase': 'password123',
                },
              }
            }
          ],
        };
        final pollingData = <JNAPAction, JNAPResult>{
          JNAPAction.getRadioInfo:
              JNAPSuccess(result: 'OK', output: radioInfoOutput),
        };

        final result = service.parseRadioInfo(pollingData);

        expect(result.isBandSteeringSupported, isTrue);
        expect(result.radios.length, 1);
        expect(result.radios.first.band, '2.4GHz');
        expect(result.radios.first.ssid, 'MyNetwork_2.4G');
        expect(result.radios.first.isEnabled, isTrue);
      });
    });

    group('parseGuestRadioSettings', () {
      test(
          'returns initial model when getGuestRadioSettings is not in polling data',
          () {
        final pollingData = <JNAPAction, JNAPResult>{};

        final result = service.parseGuestRadioSettings(pollingData);

        expect(result, GuestRadioSettingsUIModel.initial());
      });

      test('returns GuestRadioSettingsUIModel when valid settings exist', () {
        final guestRadioOutput = {
          'isGuestNetworkACaptivePortal': false,
          'isGuestNetworkEnabled': true,
          'maxSimultaneousGuests': 50,
          'radios': [
            {
              'radioID': 'RADIO_2.4GHz',
              'isEnabled': true,
              'broadcastGuestSSID': true,
              'guestSSID': 'Guest_Network',
              'guestWPAPassphrase': 'password123',
              'canEnableRadio': true,
            }
          ],
        };
        final pollingData = <JNAPAction, JNAPResult>{
          JNAPAction.getGuestRadioSettings:
              JNAPSuccess(result: 'OK', output: guestRadioOutput),
        };

        final result = service.parseGuestRadioSettings(pollingData);

        expect(result.isGuestNetworkEnabled, isTrue);
        expect(result.radios.length, 1);
        expect(result.radios.first.guestSSID, 'Guest_Network');
      });
    });

    group('transformWanExternal', () {
      test('returns null when input is null', () {
        final result = service.transformWanExternal(null);

        expect(result, isNull);
      });

      test('returns WanExternalUIModel when valid WanExternal provided', () {
        final wanExternal = WanExternal(
          publicWanIPv4: '203.0.113.1',
          privateWanIPv4: '192.168.1.100',
        );

        final result = service.transformWanExternal(wanExternal);

        expect(result, isNotNull);
        expect(result!.publicWanIPv4, '203.0.113.1');
        expect(result.privateWanIPv4, '192.168.1.100');
      });
    });
  });
}
