import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';

import '../../../common/di.dart';
import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../test_data/wifi_list_test_state.dart';

/// One radio as `GetRadioInfo` reports it.
Map<String, dynamic> _routerRadio(
  String radioID, {
  required String ssid,
  required String passphrase,
  String mode = '802.11mixed',
  String security = 'WPA2/WPA3-Mixed-Personal',
}) =>
    {
      'radioID': radioID,
      'physicalRadioID': 'ath${radioID.length}',
      'bssid': '00:11:22:33:44:55',
      'band': radioID == 'RADIO_2.4GHz' ? '2.4GHz' : '5GHz',
      'supportedModes': ['802.11bgn', '802.11mixed'],
      'defaultMixedMode': '802.11mixed',
      'supportedChannelsForChannelWidths': [
        {
          'channelWidth': 'Auto',
          'channels': [0, 1, 6, 11]
        },
        {
          'channelWidth': 'Standard',
          'channels': [0, 1, 6, 11]
        },
      ],
      'supportedSecurityTypes': [
        'None',
        'WEP',
        'WPA2-Personal',
        'WPA2-Enterprise',
        'WPA2/WPA3-Mixed-Personal',
        'WPA3-Personal',
      ],
      'maxRADIUSSharedKeyLength': 64,
      'settings': {
        'isEnabled': true,
        'mode': mode,
        'ssid': ssid,
        'broadcastSSID': true,
        'channelWidth': 'Auto',
        'channel': 0,
        'security': security,
        'wpaPersonalSettings': {'passphrase': passphrase},
      },
    };

/// `GetGuestRadioSettings` output: guest Wi-Fi on, under an older name.
const _routerGuest = <String, dynamic>{
  'isGuestNetworkACaptivePortal': false,
  'isGuestNetworkEnabled': true,
  'maxSimultaneousGuests': 50,
  'maxSimultaneousGuestsLimit': 128,
  'radios': [
    {
      'radioID': 'RADIO_2.4GHz',
      'isEnabled': true,
      'broadcastGuestSSID': true,
      'guestSSID': 'OldGuest',
      'guestWPAPassphrase': 'oldpass1',
      'canEnableRadio': true,
    },
    {
      'radioID': 'RADIO_5GHz',
      'isEnabled': true,
      'broadcastGuestSSID': true,
      'guestSSID': 'OldGuest',
      'guestWPAPassphrase': 'oldpass1',
      'canEnableRadio': true,
    },
  ],
};

// A testable version of WifiListNotifier that allows setting state.
class TestableWifiListNotifier extends WifiListNotifier {
  @override
  WiFiState build() {
    // Do nothing, state will be set manually.
    return WiFiState.fromMap(wifiListTestState);
  }

  void setState(WiFiState newState) {
    state = newState;
  }
}

void main() {
  final defaultWifiItem = WiFiItem(
    radioID: WifiRadioBand.radio_24,
    ssid: 'test',
    password: 'test',
    securityType: WifiSecurityType.wpa2Personal,
    wirelessMode: WifiWirelessMode.bgn,
    channelWidth: WifiChannelWidth.auto,
    channel: 1,
    isBroadcast: false,
    isEnabled: true,
    availableSecurityTypes: const [
      WifiSecurityType.wpa2Personal,
      WifiSecurityType.wpa3Personal,
      WifiSecurityType.wpa2Or3MixedPersonal,
    ],
    availableWirelessModes: const [WifiWirelessMode.bgn],
    availableChannels: const {
      WifiChannelWidth.auto: [1, 2, 3]
    },
    numOfDevices: 0,
  );
  group('WifiListNotifier - Testable Methods', () {
    group('getSimpleModeAvailableSecurityTypeList', () {
      final notifier = TestableWifiListNotifier();

      test('should return intersection of security types', () {
        final wifiItem1 = defaultWifiItem.copyWith(
          radioID: WifiRadioBand.radio_24,
          availableSecurityTypes: const [
            WifiSecurityType.wpa2Personal,
            WifiSecurityType.wpa3Personal,
            WifiSecurityType.wpa2Or3MixedPersonal,
          ],
        );
        final wifiItem2 = defaultWifiItem.copyWith(
          radioID: WifiRadioBand.radio_5_1,
          availableSecurityTypes: const [
            WifiSecurityType.wpa2Personal,
            WifiSecurityType.wpa3Personal,
          ],
        );

        final result = notifier
            .getSimpleModeAvailableSecurityTypeList([wifiItem1, wifiItem2]);

        expect(
            result,
            containsAll([
              WifiSecurityType.wpa2Personal,
              WifiSecurityType.wpa3Personal
            ]));
        expect(result.length, 2);
      });

      test('should return empty list for no common types', () {
        final wifiItem1 = defaultWifiItem.copyWith(
          radioID: WifiRadioBand.radio_24,
          availableSecurityTypes: const [WifiSecurityType.wpa2Personal],
        );
        final wifiItem2 = defaultWifiItem.copyWith(
          radioID: WifiRadioBand.radio_5_1,
          availableSecurityTypes: const [WifiSecurityType.wpa3Personal],
        );

        final result = notifier
            .getSimpleModeAvailableSecurityTypeList([wifiItem1, wifiItem2]);

        expect(result, isEmpty);
      });

      test('should return full list for a single wifi item', () {
        final wifiItem1 = defaultWifiItem.copyWith(
          radioID: WifiRadioBand.radio_24,
          availableSecurityTypes: const [
            WifiSecurityType.wpa2Personal,
            WifiSecurityType.wpa3Personal,
          ],
        );

        final result =
            notifier.getSimpleModeAvailableSecurityTypeList([wifiItem1]);

        expect(result,
            [WifiSecurityType.wpa2Personal, WifiSecurityType.wpa3Personal]);
      });

      test('should return empty list when mainWiFi is empty', () {
        final result = notifier.getSimpleModeAvailableSecurityTypeList([]);
        expect(result, isEmpty);
      });
    });

    group('getSimpleModeAvailableSecurityType', () {
      final notifier = TestableWifiListNotifier();
      final availableList = [
        WifiSecurityType.wpa2Personal,
        WifiSecurityType.wpa3Personal,
        WifiSecurityType.wpa2Or3MixedPersonal,
        WifiSecurityType.wep,
      ];

      test('should return current type if it is in the available list', () {
        const current = WifiSecurityType.wpa2Personal;
        final result =
            notifier.getSimpleModeAvailableSecurityType(current, availableList);
        expect(result, current);
      });

      test(
          'should return wpa3Personal if current is not available but wpa3Personal is',
          () {
        const current = WifiSecurityType.wpaPersonal;
        final result =
            notifier.getSimpleModeAvailableSecurityType(current, availableList);
        expect(result, WifiSecurityType.wpa3Personal);
      });

      test(
          'should return wpa2Or3MixedPersonal if wpa3Personal is not available',
          () {
        const current = WifiSecurityType.wpaPersonal;
        final listWithoutWpa3 = [
          WifiSecurityType.wpa2Personal,
          WifiSecurityType.wpa2Or3MixedPersonal,
          WifiSecurityType.wep,
        ];
        final result = notifier.getSimpleModeAvailableSecurityType(
            current, listWithoutWpa3);
        expect(result, WifiSecurityType.wpa2Or3MixedPersonal);
      });

      test('should return wpa2Personal if wpa3 and mixed are not available',
          () {
        const current = WifiSecurityType.wpaPersonal;
        final listWithoutWpa3AndMixed = [
          WifiSecurityType.wpa2Personal,
          WifiSecurityType.wep,
        ];
        final result = notifier.getSimpleModeAvailableSecurityType(
            current, listWithoutWpa3AndMixed);
        expect(result, WifiSecurityType.wpa2Personal);
      });

      test('should return the first item if no preferred types are available',
          () {
        const current = WifiSecurityType.wpaPersonal;
        final listWithoutPreferred = [
          WifiSecurityType.wep,
          WifiSecurityType.open,
        ];
        final result = notifier.getSimpleModeAvailableSecurityType(
            current, listWithoutPreferred);
        expect(result, WifiSecurityType.wep);
      });

      test('should return current type if available list is empty', () {
        const current = WifiSecurityType.wpaPersonal;
        final emptyList = <WifiSecurityType>[];
        final result =
            notifier.getSimpleModeAvailableSecurityType(current, emptyList);
        expect(result, current);
      });
    });
  });

  group('with a router', () {
    mockDependencyRegister();
    final services = serviceHelper as MockServiceHelper;

    late RouterBoundary router;
    late ProviderContainer container;
    late TestableWifiListNotifier notifier;

    WiFiState page() => container.read(wifiListProvider);

    /// The setRadioSettings entry the page writes for [radioID].
    Map<String, dynamic> writtenRadio(String radioID) =>
        (router.payloadsOf(JNAPAction.setRadioSettings).single['radios']
                as List)
            .cast<Map<String, dynamic>>()
            .singleWhere((radio) => radio['radioID'] == radioID);

    setUp(() {
      router = RouterBoundary()
        ..holds(JNAPAction.getRadioInfo, {
          'isBandSteeringSupported': false,
          'radios': [
            _routerRadio('RADIO_2.4GHz',
                ssid: 'Linksys03041', passphrase: 'p1'),
            _routerRadio('RADIO_5GHz', ssid: 'Linksys03041', passphrase: 'p1'),
          ],
        })
        ..holds(JNAPAction.getGuestRadioSettings, _routerGuest);
      for (final action in [
        JNAPAction.getTopologyOptimizationSettings,
        JNAPAction.getIptvSettings,
        JNAPAction.getMLOSettings,
        JNAPAction.getDFSSettings,
        JNAPAction.getAirtimeFairnessSettings,
      ]) {
        router.holds(action, const {});
      }
      when(services.isSupportGuestNetwork()).thenReturn(true);
      container = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router.repo),
        pollingProvider.overrideWith(() => RecordingPolling()),
        wifiListProvider.overrideWith(() => TestableWifiListNotifier()),
      ]);
      notifier =
          container.read(wifiListProvider.notifier) as TestableWifiListNotifier;
    });

    tearDown(() {
      container.dispose();
      reset(services);
    });

    group('save', () {
      test('writes each band as the page shows it', () async {
        await notifier.save();

        expect(writtenRadio('RADIO_2.4GHz'), {
          'radioID': 'RADIO_2.4GHz',
          'settings': {
            'isEnabled': true,
            'mode': '802.11mixed',
            'ssid': 'Linksys03041',
            'broadcastSSID': true,
            'channelWidth': 'Auto',
            'channel': 0,
            'security': 'WPA2/WPA3-Mixed-Personal',
            'wpaPersonalSettings': {'passphrase': 'FakeWiFi1@'},
          },
        });
        expect((writtenRadio('RADIO_5GHz')['settings'] as Map)['mode'],
            '802.11anacaxbe');
      });

      test('writes the guest network over what the router holds', () async {
        await notifier.save();

        expect(router.payloadsOf(JNAPAction.setGuestRadioSettings).single, {
          'isGuestNetworkEnabled': false,
          'maxSimultaneousGuests': 50,
          'radios': [
            for (final radioID in ['RADIO_2.4GHz', 'RADIO_5GHz'])
              {
                'radioID': radioID,
                // Each guest radio follows its main radio.
                'isEnabled': true,
                'broadcastGuestSSID': true,
                'guestSSID': 'Linksys03041-guest',
                'guestWPAPassphrase': 'BeMyGuest',
                'canEnableRadio': false,
              },
          ],
        });
      });

      test('reads the guest network fresh before writing it', () async {
        await notifier.save();

        final actions = router.actions;
        expect(actions.indexOf(JNAPAction.getGuestRadioSettings),
            lessThan(actions.indexOf(JNAPAction.setGuestRadioSettings)));
      });

      test('writes the main bands and the guest network in one transaction',
          () async {
        await notifier.save();

        expect(router.transactions.first.map((command) => command.key), [
          JNAPAction.setRadioSettings,
          JNAPAction.setGuestRadioSettings,
        ]);
      });

      test('writes no guest network on a router without one', () async {
        when(services.isSupportGuestNetwork()).thenReturn(false);

        await notifier.save();

        expect(
            router.actions, isNot(contains(JNAPAction.getGuestRadioSettings)));
        expect(router.transactions.first.map((command) => command.key),
            [JNAPAction.setRadioSettings]);
      });

      test('sends the blank WEP settings a WEP band needs', () async {
        notifier.setWiFiSecurityType(
            WifiSecurityType.wep, WifiRadioBand.radio_24);

        await notifier.save();

        final settings =
            writtenRadio('RADIO_2.4GHz')['settings'] as Map<String, dynamic>;
        expect(settings['security'], 'WEP');
        expect(settings['wepSettings'], {
          'encryption': '',
          'key1': '',
          'key2': '',
          'key3': '',
          'key4': '',
          'txKey': 0,
        });
        expect(settings.keys, isNot(contains('wpaPersonalSettings')));
      });

      test('sends the blank RADIUS settings an Enterprise band needs',
          () async {
        notifier.setWiFiSecurityType(
            WifiSecurityType.wpa2Enterprise, WifiRadioBand.radio_24);

        await notifier.save();

        final settings =
            writtenRadio('RADIO_2.4GHz')['settings'] as Map<String, dynamic>;
        expect(settings['wpaEnterpriseSettings'],
            {'radiusServer': '', 'radiusPort': 0, 'sharedKey': ''});
      });

      test('sends no key for an open band', () async {
        notifier.setWiFiSecurityType(
            WifiSecurityType.open, WifiRadioBand.radio_24);

        await notifier.save();

        final settings =
            writtenRadio('RADIO_2.4GHz')['settings'] as Map<String, dynamic>;
        expect(settings['security'], 'None');
        expect(settings.keys, isNot(contains('wpaPersonalSettings')));
        expect(settings.keys, isNot(contains('wepSettings')));
        expect(settings.keys, isNot(contains('wpaEnterpriseSettings')));
      });

      test('shows the bands the router holds after the write', () async {
        router.holds(JNAPAction.getRadioInfo, {
          'isBandSteeringSupported': false,
          'radios': [
            _routerRadio('RADIO_2.4GHz', ssid: 'Renamed', passphrase: 'p2'),
          ],
        });

        final saved = await notifier.save();

        expect(saved.mainWiFi.single.ssid, 'Renamed');
        expect(page().mainWiFi.single.password, 'p2');
        expect(page().guestWiFi.ssid, 'OldGuest');
      });

      test('reports a write the router refuses, and reads nothing back',
          () async {
        router.failsTransactions(
            const JNAPError(result: 'ErrorUnknown', error: 'ErrorUnknown'));
        final before = page();

        await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

        expect(router.actions, isNot(contains(JNAPAction.getRadioInfo)));
        expect(page(), before);
      });
    });

    group('saveToggleEnabled', () {
      test('switches the named bands and writes them', () async {
        await notifier
            .saveToggleEnabled(radios: ['RADIO_5GHz'], enabled: false);

        expect((writtenRadio('RADIO_5GHz')['settings'] as Map)['isEnabled'],
            false);
        expect((writtenRadio('RADIO_2.4GHz')['settings'] as Map)['isEnabled'],
            true);
      });

      test('switches the guest network when it names no band', () async {
        await notifier.saveToggleEnabled(radios: null, enabled: true);

        expect(
            router
                .payloadsOf(JNAPAction.setGuestRadioSettings)
                .single['isGuestNetworkEnabled'],
            true);
      });

      test('reports a write the router refuses, and reads nothing back',
          () async {
        router.failsTransactions(
            const JNAPError(result: 'ErrorUnknown', error: 'ErrorUnknown'));

        await expectLater(
            notifier.saveToggleEnabled(radios: ['RADIO_5GHz'], enabled: false),
            throwsA(isA<JNAPError>()));

        expect(router.actions, isNot(contains(JNAPAction.getRadioInfo)));
      });
    });

    group('fetch', () {
      test('reads each band and the guest network', () async {
        await notifier.fetch();

        final band = page().mainWiFi.first;
        expect(band.radioID, WifiRadioBand.radio_24);
        expect(band.ssid, 'Linksys03041');
        expect(band.password, 'p1');
        expect(page().guestWiFi.isEnabled, isTrue);
        expect(page().guestWiFi.password, 'oldpass1');
      });

      test('offers neither WEP nor Enterprise security on the page', () async {
        await notifier.fetch();

        expect(page().mainWiFi.first.availableSecurityTypes, [
          WifiSecurityType.open,
          WifiSecurityType.wpa2Personal,
          WifiSecurityType.wpa2Or3MixedPersonal,
          WifiSecurityType.wpa3Personal,
        ]);
      });

      test('turns on simple mode when every band matches', () async {
        await notifier.fetch();

        expect(page().isSimpleMode, isTrue);
        expect(page().simpleModeWifi.ssid, 'Linksys03041');
      });

      test('turns off simple mode when the bands differ', () async {
        router.holds(JNAPAction.getRadioInfo, {
          'isBandSteeringSupported': false,
          'radios': [
            _routerRadio('RADIO_2.4GHz', ssid: 'Home', passphrase: 'p1'),
            _routerRadio('RADIO_5GHz', ssid: 'Home-5G', passphrase: 'p1'),
          ],
        });

        await notifier.fetch();

        expect(page().isSimpleMode, isFalse);
      });

      test('leaves the guest network empty on a router without one', () async {
        when(services.isSupportGuestNetwork()).thenReturn(false);

        await notifier.fetch();

        expect(
            router.actions, isNot(contains(JNAPAction.getGuestRadioSettings)));
        expect(page().guestWiFi.isEnabled, isFalse);
        expect(page().guestWiFi.ssid, '');
      });
    });

    group('setters', () {
      WiFiItem band(WifiRadioBand id) =>
          page().mainWiFi.firstWhere((wifi) => wifi.radioID == id);

      test('change only the band they name', () {
        notifier
          ..setWiFiSSID('Den', WifiRadioBand.radio_5_1)
          ..setWiFiPassword('newpass1', WifiRadioBand.radio_5_1)
          ..setWiFiEnabled(false, WifiRadioBand.radio_5_1)
          ..setWiFiMode(WifiWirelessMode.ax, WifiRadioBand.radio_5_1)
          ..setEnableBoardcast(false, WifiRadioBand.radio_5_1)
          ..setChannel(36, WifiRadioBand.radio_5_1);

        final fiveG = band(WifiRadioBand.radio_5_1);
        expect(fiveG.ssid, 'Den');
        expect(fiveG.password, 'newpass1');
        expect(fiveG.isEnabled, isFalse);
        expect(fiveG.wirelessMode, WifiWirelessMode.ax);
        expect(fiveG.isBroadcast, isFalse);
        expect(fiveG.channel, 36);
        expect(band(WifiRadioBand.radio_24).ssid, 'Linksys03041');
      });

      test('change the guest network when they name no band', () {
        notifier
          ..setWiFiSSID('Visitors')
          ..setWiFiPassword('visit123')
          ..setWiFiEnabled(true);

        expect(page().guestWiFi.ssid, 'Visitors');
        expect(page().guestWiFi.password, 'visit123');
        expect(page().guestWiFi.isEnabled, isTrue);
      });

      test('ignore a band the router does not have', () {
        final before = page();

        notifier
          ..setWiFiSSID('Nope', WifiRadioBand.radio_6)
          ..setWiFiPassword('Nope', WifiRadioBand.radio_6)
          ..setWiFiEnabled(false, WifiRadioBand.radio_6)
          ..setWiFiSecurityType(WifiSecurityType.open, WifiRadioBand.radio_6)
          ..setWiFiMode(WifiWirelessMode.ax, WifiRadioBand.radio_6)
          ..setEnableBoardcast(false, WifiRadioBand.radio_6)
          ..setChannelWidth(WifiChannelWidth.wide80, WifiRadioBand.radio_6)
          ..setChannel(5, WifiRadioBand.radio_6);

        expect(page(), before);
      });

      test('a channel width moves a channel the width does not offer', () {
        // The 5 GHz band offers channel 140 at 20 MHz but not at 80 MHz,
        // where its first channel is 0 (auto).
        notifier
          ..setChannel(140, WifiRadioBand.radio_5_1)
          ..setChannelWidth(WifiChannelWidth.wide80, WifiRadioBand.radio_5_1);

        expect(band(WifiRadioBand.radio_5_1).channelWidth,
            WifiChannelWidth.wide80);
        expect(band(WifiRadioBand.radio_5_1).channel, 0);
      });

      test('a channel width keeps a channel the width offers', () {
        notifier
          ..setChannel(36, WifiRadioBand.radio_5_1)
          ..setChannelWidth(WifiChannelWidth.wide80, WifiRadioBand.radio_5_1);

        expect(band(WifiRadioBand.radio_5_1).channel, 36);
      });

      test('simple mode and its Wi-Fi are set as given', () {
        final wifi = band(WifiRadioBand.radio_5_1);

        notifier
          ..setSimpleMode(true)
          ..setSimpleModeWifi(wifi);

        expect(page().isSimpleMode, isTrue);
        expect(page().simpleModeWifi, wifi);
      });
    });

    group('checkingMLOSettingsConflicts', () {
      Map<WifiRadioBand, WiFiItem> bands() =>
          {for (final wifi in page().mainWiFi) wifi.radioID: wifi};

      test('finds none when every band suits MLO', () {
        expect(notifier.checkingMLOSettingsConflicts(bands()), isFalse);
      });

      test('finds none with no bands, or with MLO off', () {
        expect(notifier.checkingMLOSettingsConflicts({}), isFalse);
        notifier.setWiFiSSID('Other', WifiRadioBand.radio_5_1);
        expect(
            notifier.checkingMLOSettingsConflicts(bands(), isMloEnabled: false),
            isFalse);
      });

      test('finds one in each setting MLO needs to match', () {
        final changes = <String, void Function()>{
          'different SSIDs': () =>
              notifier.setWiFiSSID('Other', WifiRadioBand.radio_5_1),
          'security without WPA3': () => notifier.setWiFiSecurityType(
              WifiSecurityType.wpa2Personal, WifiRadioBand.radio_24),
          'a 5 GHz band off': () =>
              notifier.setWiFiEnabled(false, WifiRadioBand.radio_5_1),
          'a 5 GHz mode without 802.11be': () => notifier.setWiFiMode(
              WifiWirelessMode.anacax, WifiRadioBand.radio_5_1),
        };
        for (final MapEntry(key: reason, value: change) in changes.entries) {
          notifier.setState(WiFiState.fromMap(wifiListTestState));
          change();
          expect(notifier.checkingMLOSettingsConflicts(bands()), isTrue,
              reason: reason);
        }
      });
    });
  });
}
