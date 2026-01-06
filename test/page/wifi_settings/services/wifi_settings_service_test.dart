import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_service.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';

// Mocks
class MockRouterRepository extends Mock implements RouterRepository {}

class MockJNAPTransactionBuilder extends Mock
    implements JNAPTransactionBuilder {}

class MockServiceHelper extends Mock implements ServiceHelper {}

class MockLinksysDevice extends Mock implements LinksysDevice {}

// Fake Objects
class FakeJNAPTransactionBuilder extends Fake
    implements JNAPTransactionBuilder {
  @override
  final List<MapEntry<JNAPAction, Map<String, dynamic>>> commands;
  FakeJNAPTransactionBuilder({required this.commands});
}

class FakeLinksysDevice extends Fake implements LinksysDevice {
  @override
  String get deviceID => 'dev-1';
}

void main() {
  late WifiSettingsService service;
  late MockRouterRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(JNAPTransactionBuilder(commands: []));
    registerFallbackValue(JNAPAction.getRadioInfo);
    registerFallbackValue(FakeLinksysDevice());
    registerFallbackValue(CacheLevel.noCache);
  });

  setUp(() {
    mockRepo = MockRouterRepository();
    service = WifiSettingsService(mockRepo);

    // Default transaction stub
    when(() =>
        mockRepo.transaction(any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'))).thenAnswer(
        (_) async => JNAPTransactionSuccessWrap(result: 'OK', data: const []));
  });

  group('WifiSettingsService', () {
    // --- Validation Tests ---
    group('Validation', () {
      test('validateWifiListSettings - returns true when valid (Simple)', () {
        final settings = WiFiListSettings(
            mainWiFi: const [],
            guestWiFi: const GuestWiFiItem(
                isEnabled: false,
                ssid: 'guest',
                password: 'password',
                numOfDevices: 0),
            isSimpleMode: true,
            simpleModeWifi: WiFiItem.fromMap(const {
              'ssid': 'test',
              'password': 'password',
              'securityType': 'WPA2-Personal',
              'channel': 0,
              'isBroadcast': true,
              'isEnabled': true,
              'numOfDevices': 0
            }));
        expect(service.validateWifiListSettings(settings), true);
      });

      test('validateWifiListSettings - returns false when pwd empty (Simple)',
          () {
        final settings = WiFiListSettings(
            mainWiFi: const [],
            guestWiFi: const GuestWiFiItem(
                isEnabled: false,
                ssid: 'guest',
                password: 'password',
                numOfDevices: 0),
            isSimpleMode: true,
            simpleModeWifi: WiFiItem.fromMap(const {
              'ssid': 'test',
              'password': '',
              'securityType': 'WPA2-Personal',
              'channel': 0,
              'isBroadcast': true,
              'isEnabled': true,
              'numOfDevices': 0
            }));
        expect(service.validateWifiListSettings(settings), false);
      });

      test('validateWifiListSettings - returns true when valid (Advanced)', () {
        final settings = WiFiListSettings(
            mainWiFi: [
              WiFiItem.fromMap(const {
                'ssid': 'test',
                'password': 'password',
                'securityType': 'WPA2-Personal',
                'channel': 0,
                'isBroadcast': true,
                'isEnabled': true,
                'numOfDevices': 0
              })
            ],
            guestWiFi: const GuestWiFiItem(
                isEnabled: false,
                ssid: 'guest',
                password: 'password',
                numOfDevices: 0),
            isSimpleMode: false,
            simpleModeWifi: WiFiItem.fromMap(const {
              'channel': 0,
              'isBroadcast': true,
              'isEnabled': true,
              'numOfDevices': 0
            }));
        expect(service.validateWifiListSettings(settings), true);
      });

      test('validateWifiListSettings - returns false when pwd empty (Advanced)',
          () {
        final settings = WiFiListSettings(
            mainWiFi: [
              WiFiItem.fromMap(const {
                'ssid': 'test',
                'password': '',
                'securityType': 'WPA2-Personal',
                'channel': 0,
                'isBroadcast': true,
                'isEnabled': true,
                'numOfDevices': 0
              })
            ],
            guestWiFi: const GuestWiFiItem(
                isEnabled: false,
                ssid: 'guest',
                password: 'password',
                numOfDevices: 0),
            isSimpleMode: false,
            simpleModeWifi: WiFiItem.fromMap(const {
              'channel': 0,
              'isBroadcast': true,
              'isEnabled': true,
              'numOfDevices': 0
            }));
        expect(service.validateWifiListSettings(settings), false);
      });
    });

    group('MLO Conflicts', () {
      test('checkingMLOSettingsConflicts returns false if radios empty', () {
        expect(service.checkingMLOSettingsConflicts({}), false);
      });

      test('checkingMLOSettingsConflicts returns false if MLO is disabled', () {
        expect(
            service.checkingMLOSettingsConflicts(<WifiRadioBand, WiFiItem>{},
                isMloEnabled: false),
            false);
      });

      test('checkingMLOSettingsConflicts returns true if SSIDs differ', () {
        final items = {
          WifiRadioBand.radio_24: WiFiItem.fromMap(const {
            'radioID': 'RADIO_2.4GHz',
            'ssid': 'A',
            'password': 'pass',
            'channel': 0,
            'isBroadcast': true,
            'isEnabled': true,
            'numOfDevices': 0
          }),
          WifiRadioBand.radio_5_1: WiFiItem.fromMap(const {
            'radioID': 'RADIO_5GHz',
            'ssid': 'B',
            'password': 'pass',
            'channel': 0,
            'isBroadcast': true,
            'isEnabled': true,
            'numOfDevices': 0
          })
        };
        expect(service.checkingMLOSettingsConflicts(items, isMloEnabled: true),
            true);
      });

      test('checkingMLOSettingsConflicts returns true if passwords differ', () {
        final items = {
          WifiRadioBand.radio_24: WiFiItem.fromMap(const {
            'radioID': 'RADIO_2.4GHz',
            'ssid': 'A',
            'password': 'pass1',
            'channel': 0,
            'isBroadcast': true,
            'isEnabled': true,
            'numOfDevices': 0
          }),
          WifiRadioBand.radio_5_1: WiFiItem.fromMap(const {
            'radioID': 'RADIO_5GHz',
            'ssid': 'A',
            'password': 'pass2',
            'channel': 0,
            'isBroadcast': true,
            'isEnabled': true,
            'numOfDevices': 0
          })
        };
        expect(service.checkingMLOSettingsConflicts(items, isMloEnabled: true),
            true);
      });

      test('checkingMLOSettingsConflicts returns false if inclusive match', () {
        // To be inclusive match (no conflict), needs:
        // - Same SSID/Pass
        // - WPA3 Variant Security
        // - Mode includes BE (Mixed)
        // - All enabled
        final items = {
          WifiRadioBand.radio_24: WiFiItem.fromMap(const {
            'radioID': 'RADIO_2.4GHz', 'ssid': 'A', 'password': 'pass',
            'channel': 0, 'isBroadcast': true, 'isEnabled': true,
            'numOfDevices': 0,
            'securityType': 'WPA3-Personal', // Correct security
            'wirelessMode': '802.11mixed' // Includes BE
          }),
          WifiRadioBand.radio_5_1: WiFiItem.fromMap(const {
            'radioID': 'RADIO_5GHz',
            'ssid': 'A',
            'password': 'pass',
            'channel': 0,
            'isBroadcast': true,
            'isEnabled': true,
            'numOfDevices': 0,
            'securityType': 'WPA3-Personal',
            'wirelessMode': '802.11mixed'
          })
        };
        expect(service.checkingMLOSettingsConflicts(items, isMloEnabled: true),
            false);
      });

      test('checkingMLOSettingsConflicts returns true if non-WPA3', () {
        final items = {
          WifiRadioBand.radio_24: WiFiItem.fromMap(const {
            'radioID': 'RADIO_2.4GHz', 'ssid': 'A', 'password': 'pass',
            'channel': 0, 'isBroadcast': true, 'isEnabled': true,
            'numOfDevices': 0,
            'securityType': 'WPA2-Personal', // NOT WPA3
            'wirelessMode': '802.11mixed'
          }),
        };
        expect(service.checkingMLOSettingsConflicts(items, isMloEnabled: true),
            true);
      });

      test('checkingMLOSettingsConflicts returns true if band disabled', () {
        final items = {
          WifiRadioBand.radio_24: WiFiItem.fromMap(const {
            'radioID': 'RADIO_2.4GHz',
            'ssid': 'A',
            'password': 'pass',
            'channel': 0,
            'isBroadcast': true,
            'isEnabled': true,
            'numOfDevices': 0,
            'securityType': 'WPA3-Personal',
            'wirelessMode': '802.11mixed'
          }),
          WifiRadioBand.radio_5_1: WiFiItem.fromMap(const {
            'radioID': 'RADIO_5GHz', 'ssid': 'A', 'password': 'pass',
            'channel': 0, 'isBroadcast': true,
            'isEnabled': false, // Disabled
            'numOfDevices': 0,
            'securityType': 'WPA3-Personal', 'wirelessMode': '802.11mixed'
          }),
        };
        expect(service.checkingMLOSettingsConflicts(items, isMloEnabled: true),
            true);
      });

      test('checkingMLOSettingsConflicts returns true if non-Mixed mode', () {
        final items = {
          WifiRadioBand.radio_24: WiFiItem.fromMap(const {
            'radioID': 'RADIO_2.4GHz',
            'ssid': 'A',
            'password': 'pass',
            'channel': 0,
            'isBroadcast': true,
            'isEnabled': true,
            'numOfDevices': 0,
            'securityType': 'WPA3-Personal',
            'wirelessMode': '802.11mixed'
          }),
          WifiRadioBand.radio_5_1: WiFiItem.fromMap(const {
            'radioID': 'RADIO_5GHz', 'ssid': 'A', 'password': 'pass',
            'channel': 0, 'isBroadcast': true, 'isEnabled': true,
            'numOfDevices': 0,
            'securityType': 'WPA3-Personal',
            'wirelessMode': '802.11ac' // Not Mixed
          }),
        };
        expect(service.checkingMLOSettingsConflicts(items, isMloEnabled: true),
            true);
      });
    });

    // --- Fetch Tests ---
    group('fetchBundleSettings', () {
      test('fetchBundleSettings parses response and returns correct settings',
          () async {
        final mockHelper = MockServiceHelper();
        when(() => mockHelper.isSupportGuestNetwork()).thenReturn(true);
        when(() => mockHelper.isSupportTopologyOptimization()).thenReturn(true);
        when(() => mockHelper.isSupportIPTv()).thenReturn(true);
        when(() => mockHelper.isSupportMLO()).thenReturn(true);
        when(() => mockHelper.isSupportDFS()).thenReturn(true);
        when(() => mockHelper.isSupportAirtimeFairness()).thenReturn(true);
        when(() => mockHelper.isSupportGetSTABSSID()).thenReturn(true);

        when(() => mockRepo.send(JNAPAction.getLocalDevice,
                auth: true,
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel')))
            .thenAnswer((_) async =>
                JNAPSuccess(result: 'OK', output: const {'deviceID': 'dev-1'}));

        // Corrected Transaction Result Data
        final responses = <MapEntry<JNAPAction, JNAPResult>>[
          MapEntry(
              JNAPAction.getRadioInfo,
              const JNAPSuccess(result: 'OK', output: {
                'isBandSteeringSupported': false,
                'radios': [
                  {
                    'radioID': 'RADIO_2.4GHz',
                    'physicalRadioID': '1',
                    'band': '2.4GHz',
                    'bssid': '00:01:02:03:04:05',
                    'supportedModes': ['802.11n'],
                    'supportedChannelsForChannelWidths': [
                      {
                        'channelWidth': 'Standard',
                        'channels': [6]
                      }
                    ],
                    'supportedSecurityTypes': ['WPA2-Personal'],
                    'maxRADIUSSharedKeyLength': 64,
                    'settings': {
                      'isEnabled': true,
                      'ssid': 'MainSSID',
                      'password': 'pass',
                      'broadcastSSID': true,
                      'channel': 6,
                      'mode': '802.11n',
                      'channelWidth': 'Standard',
                      'security': 'WPA2-Personal'
                    }
                  },
                  {
                    'radioID': 'RADIO_5GHz',
                    'physicalRadioID': '2',
                    'band': '5GHz',
                    'bssid': '00:01:02:03:04:06',
                    'supportedModes': ['802.11ac'],
                    'supportedChannelsForChannelWidths': [
                      {
                        'channelWidth': 'Wide',
                        'channels': [36]
                      }
                    ],
                    'supportedSecurityTypes': ['WPA2-Personal'],
                    'maxRADIUSSharedKeyLength': 64,
                    'settings': {
                      'isEnabled': true,
                      'ssid': 'MainSSID',
                      'password': 'pass',
                      'broadcastSSID': true,
                      'channel': 36,
                      'mode': '802.11ac',
                      'channelWidth': 'Wide',
                      'security': 'WPA2-Personal'
                    }
                  }
                ]
              })),
          MapEntry(
              JNAPAction.getGuestRadioSettings,
              JNAPSuccess(result: 'OK', output: const {
                'isGuestNetworkEnabled': true,
                'isGuestNetworkACaptivePortal': false,
                'radios': [
                  {
                    'radioID': 'RADIO_2.4GHz',
                    'guestSSID': 'Guest',
                    'guestWPAPassphrase': 'pass',
                    'isEnabled': true,
                    'broadcastGuestSSID': true,
                    'canEnableRadio': true
                  },
                  {
                    'radioID': 'RADIO_5GHz',
                    'guestSSID': 'Guest',
                    'guestWPAPassphrase': 'pass',
                    'isEnabled': true,
                    'broadcastGuestSSID': true,
                    'canEnableRadio': true
                  }
                ]
              })),
          MapEntry(
              JNAPAction.getTopologyOptimizationSettings,
              JNAPSuccess(
                  result: 'OK',
                  output: const {'isTopologyOptimizationEnabled': false})),
          MapEntry(JNAPAction.getIptvSettings,
              JNAPSuccess(result: 'OK', output: const {'isEnabled': true})),
          MapEntry(
              JNAPAction.getMLOSettings,
              JNAPSuccess(result: 'OK', output: const {
                'isMLOSupported': true,
                'isMLOEnabled': true
              })),
          MapEntry(
              JNAPAction.getDFSSettings,
              JNAPSuccess(result: 'OK', output: const {
                'isDFSSupported': true,
                'isDFSEnabled': false
              })),
          MapEntry(
              JNAPAction.getAirtimeFairnessSettings,
              JNAPSuccess(result: 'OK', output: const {
                'isAirtimeFairnessSupported': true,
                'isAirtimeFairnessEnabled': true
              })),
          MapEntry(
              JNAPAction.getMACFilterSettings,
              JNAPSuccess(result: 'OK', output: const {
                'macFilterMode': 'Allow',
                'maxMACAddresses': 32,
                'macAddresses': ['11:11:11:11:11:11']
              })),
          MapEntry(
              JNAPAction.getSTABSSIDs,
              JNAPSuccess(
                  result: 'OK', output: const {'staBSSIDs': <String>[]}))
        ];

        when(() => mockRepo.transaction(any(),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel')))
            .thenAnswer((_) async =>
                JNAPTransactionSuccessWrap(result: 'OK', data: responses));

        final (settings, status) = await service.fetchBundleSettings(
          serviceHelper: mockHelper,
          mainWifiDevices: [],
          guestWifiDevices: [],
          allDevices: [],
          isLanConnected: true,
          getBandConnectedBy: (b) => '2.4GHz', // Mock callback
        );

        // Assertions
        expect(settings.advanced.isIptvEnabled, true);
        expect(settings.advanced.isMLOEnabled, true);
        expect(settings.privacy.mode, MacFilterMode.allow);
        expect(settings.wifiList.mainWiFi.length, 2);
        expect(settings.wifiList.mainWiFi.first.ssid, 'MainSSID');
        expect(settings.wifiList.guestWiFi.isEnabled, true);
        expect(settings.wifiList.guestWiFi.ssid, 'Guest');
      });

      test('fetchBundleSettings handles missing/disabled features gracefully',
          () async {
        final mockHelper = MockServiceHelper();
        when(() => mockHelper.isSupportGuestNetwork()).thenReturn(false);
        // ... set others false ...
        when(() => mockHelper.isSupportTopologyOptimization())
            .thenReturn(false);
        when(() => mockHelper.isSupportIPTv()).thenReturn(false);
        when(() => mockHelper.isSupportMLO()).thenReturn(false);
        when(() => mockHelper.isSupportDFS()).thenReturn(false);
        when(() => mockHelper.isSupportAirtimeFairness()).thenReturn(false);
        when(() => mockHelper.isSupportGetSTABSSID()).thenReturn(false);

        when(() => mockRepo.send(JNAPAction.getLocalDevice,
                auth: true,
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel')))
            .thenAnswer((_) async =>
                JNAPSuccess(result: 'OK', output: const {'deviceID': 'dev-1'}));

        final responses = <MapEntry<JNAPAction, JNAPResult>>[
          MapEntry(
              JNAPAction.getRadioInfo,
              JNAPSuccess(result: 'OK', output: const {
                'isBandSteeringSupported': false,
                'radios': []
              })),
          MapEntry(
              JNAPAction.getMACFilterSettings,
              JNAPSuccess(result: 'OK', output: const {
                'macFilterMode': 'Deny',
                'maxMACAddresses': 32,
                'macAddresses': []
              })),
        ];

        when(() => mockRepo.transaction(any(),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel')))
            .thenAnswer((_) async =>
                JNAPTransactionSuccessWrap(result: 'OK', data: responses));

        final (settings, status) = await service.fetchBundleSettings(
          serviceHelper: mockHelper,
          mainWifiDevices: [],
          guestWifiDevices: [],
          allDevices: [],
          isLanConnected: false,
          getBandConnectedBy: (_) => null,
        );

        expect(settings.wifiList.mainWiFi, isEmpty);
        expect(settings.privacy.mode, MacFilterMode.deny);
      });

      test('Builds transaction with minimal features checks keys only',
          () async {
        final mockHelper = MockServiceHelper();
        when(() => mockHelper.isSupportGuestNetwork()).thenReturn(false);
        when(() => mockHelper.isSupportTopologyOptimization())
            .thenReturn(false);
        when(() => mockHelper.isSupportIPTv()).thenReturn(false);
        when(() => mockHelper.isSupportMLO()).thenReturn(false);
        when(() => mockHelper.isSupportDFS()).thenReturn(false);
        when(() => mockHelper.isSupportAirtimeFairness()).thenReturn(false);
        when(() => mockHelper.isSupportGetSTABSSID()).thenReturn(false);

        // Mock getLocalDevice
        when(() => mockRepo.send(JNAPAction.getLocalDevice,
                auth: true,
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel')))
            .thenAnswer((_) async =>
                JNAPSuccess(result: 'OK', output: const {'deviceID': 'dev-1'}));

        when(() => mockRepo.transaction(any(),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(
                    named: 'cacheLevel'))) // Stub specifically to catch call
            .thenAnswer((_) async =>
                JNAPTransactionSuccessWrap(result: 'OK', data: const [
                  MapEntry(
                      JNAPAction.getRadioInfo,
                      JNAPSuccess(result: 'OK', output: {
                        'isBandSteeringSupported': false,
                        'radios': []
                      })),
                  MapEntry(
                      JNAPAction.getMACFilterSettings,
                      JNAPSuccess(result: 'OK', output: {
                        'macFilterMode': 'Deny',
                        'macAddresses': [],
                        'maxMACAddresses': 32
                      })),
                ]));

        await service.fetchBundleSettings(
          serviceHelper: mockHelper,
          mainWifiDevices: [],
          guestWifiDevices: [],
          allDevices: [],
          isLanConnected: false,
          getBandConnectedBy: (_) => null,
        );

        final captured = verify(() => mockRepo.transaction(captureAny(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'))).captured;
        final builder = captured.first as JNAPTransactionBuilder;
        final keys = builder.commands.map((e) => e.key).toSet();

        expect(keys.contains(JNAPAction.getRadioInfo), true);
        expect(keys.contains(JNAPAction.getMACFilterSettings), true);

        // Assert absence
        expect(keys.contains(JNAPAction.getGuestRadioSettings), false);
        expect(keys.contains(JNAPAction.getMLOSettings), false);
      });

      test('fetchBundleSettings calculates numOfDevices correctly', () async {
        final mockHelper = MockServiceHelper();
        when(() => mockHelper.isSupportGuestNetwork()).thenReturn(false);
        when(() => mockHelper.isSupportTopologyOptimization())
            .thenReturn(false);
        when(() => mockHelper.isSupportIPTv()).thenReturn(false);
        when(() => mockHelper.isSupportMLO()).thenReturn(false);
        when(() => mockHelper.isSupportDFS()).thenReturn(false);
        when(() => mockHelper.isSupportAirtimeFairness()).thenReturn(false);
        when(() => mockHelper.isSupportGetSTABSSID()).thenReturn(false);

        // Mock getLocalDevice handles error
        // Mock getLocalDevice handles error
        when(() => mockRepo.send(JNAPAction.getLocalDevice,
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'))).thenAnswer(
          (_) async => throw Exception('Fail'),
        );

        when(() =>
            mockRepo.transaction(any(),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'))).thenAnswer(
            (_) async => JNAPTransactionSuccessWrap(result: 'OK', data: const [
                  MapEntry(
                      JNAPAction.getRadioInfo,
                      JNAPSuccess(result: 'OK', output: {
                        'isBandSteeringSupported': false,
                        'radios': [
                          {
                            'radioID': 'RADIO_2.4GHz',
                            'physicalRadioID': '1',
                            'band': '2.4GHz',
                            'bssid': '00:00:00:00:00:00',
                            'supportedModes': ['802.11mixed'],
                            'supportedChannelsForChannelWidths': [],
                            'supportedSecurityTypes': ['None'],
                            'maxRADIUSSharedKeyLength': 64,
                            'settings': {
                              'ssid': 'Main',
                              'password': 'p',
                              'security': 'None',
                              'mode': '802.11mixed',
                              'channelWidth': 'Auto',
                              'channel': 1,
                              'broadcastSSID': true,
                              'isEnabled': true
                            }
                          }
                        ]
                      })),
                  MapEntry(
                      JNAPAction.getMACFilterSettings,
                      JNAPSuccess(result: 'OK', output: {
                        'macFilterMode': 'Deny',
                        'macAddresses': [],
                        'maxMACAddresses': 32
                      })),
                ]));

        final dev1 = MockLinksysDevice();
        // Mock connection to make isOnline() true
        when(() => dev1.connections).thenReturn([
          const RawDeviceConnection(
              macAddress: '11:11:11:11:11:11', isGuest: false)
        ]);
        // Mock knownInterfaces for band? No, getBandConnectedBy callback is employed in test.

        final dev2 = MockLinksysDevice(); // Offline
        when(() => dev2.connections).thenReturn([]);

        final (settings, _) = await service.fetchBundleSettings(
          serviceHelper: mockHelper,
          mainWifiDevices: [dev1, dev2],
          guestWifiDevices: [],
          allDevices: [dev1, dev2],
          isLanConnected: false,
          getBandConnectedBy: (d) => d == dev1 ? '2.4GHz' : '5GHz',
        );

        // Expect 1 device on 2.4GHz (dev1)
        expect(settings.wifiList.mainWiFi.first.numOfDevices, 1);
        expect(settings.privacy.myMac, null); // Error handled
      });
    });

    // --- Save Tests ---

    test('saveAdvancedSettings sends correct commands based on capabilities',
        () async {
      // Arrange
      const settings = WifiAdvancedSettingsState(
        isClientSteeringEnabled: true,
        isNodesSteeringEnabled: false,
        isIptvEnabled: true,
        isMLOEnabled: true,
        isDFSEnabled: false,
        isAirtimeFairnessEnabled: true,
      );

      final mockHelper = MockServiceHelper();
      when(() => mockHelper.isSupportTopologyOptimization()).thenReturn(true);
      when(() => mockHelper.isSupportIPTv()).thenReturn(true);
      when(() => mockHelper.isSupportMLO()).thenReturn(true);
      when(() => mockHelper.isSupportDFS()).thenReturn(true);
      when(() => mockHelper.isSupportAirtimeFairness()).thenReturn(true);

      // Act
      await service.saveAdvancedSettings(
          settings: settings, serviceHelper: mockHelper);

      // Assert
      final captured =
          verify(() => mockRepo.transaction(captureAny())).captured;
      final builder = captured.first as JNAPTransactionBuilder;
      final commands = builder.commands;

      expect(
          commands
              .any((e) => e.key == JNAPAction.setTopologyOptimizationSettings),
          isTrue);
      expect(commands.any((e) => e.key == JNAPAction.setIptvSettings), isTrue);
      expect(commands.any((e) => e.key == JNAPAction.setMLOSettings), isTrue);
      expect(commands.any((e) => e.key == JNAPAction.setDFSSettings), isTrue);
      expect(
          commands.any((e) => e.key == JNAPAction.setAirtimeFairnessSettings),
          isTrue);
    });

    test('saveAdvancedSettings skips null fields even if supported', () async {
      // Arrange: Settings with nulls
      const settings = WifiAdvancedSettingsState(
        isClientSteeringEnabled: true,
        isNodesSteeringEnabled: true,
        isIptvEnabled: true,
        isMLOEnabled: null, // Null
        isDFSEnabled: null, // Null
        isAirtimeFairnessEnabled: null, // Null
      );

      final mockHelper = MockServiceHelper();
      when(() => mockHelper.isSupportTopologyOptimization()).thenReturn(true);
      when(() => mockHelper.isSupportIPTv()).thenReturn(true);
      when(() => mockHelper.isSupportMLO()).thenReturn(true);
      when(() => mockHelper.isSupportDFS()).thenReturn(true);
      when(() => mockHelper.isSupportAirtimeFairness()).thenReturn(true);

      // Act
      await service.saveAdvancedSettings(
          settings: settings, serviceHelper: mockHelper);

      // Assert
      final captured =
          verify(() => mockRepo.transaction(captureAny())).captured;
      final builder = captured.first as JNAPTransactionBuilder;
      final commands = builder.commands;

      expect(commands.any((e) => e.key == JNAPAction.setMLOSettings), isFalse);
      expect(commands.any((e) => e.key == JNAPAction.setDFSSettings), isFalse);
      expect(
          commands.any((e) => e.key == JNAPAction.setAirtimeFairnessSettings),
          isFalse);
    });

    test('saveWifiListSettings sends setRadioSettings', () async {
      // Arrange
      final mainWifi = [
        WiFiItem.fromMap(const {
          'band': '2.4GHz',
          'ssid': 'test2.4',
          'isEnabled': true,
          'isBroadcast': true,
          'channel': 0,
          'numOfDevices': 0
        })
      ];
      final settings = WiFiListSettings(
          mainWiFi: mainWifi,
          guestWiFi: const GuestWiFiItem(
              isEnabled: false,
              ssid: 'guest',
              password: 'pass',
              numOfDevices: 0),
          isSimpleMode: false,
          simpleModeWifi: WiFiItem.fromMap(const {
            'channel': 0,
            'isBroadcast': true,
            'isEnabled': true,
            'numOfDevices': 0
          }));

      // Act
      await service.saveWifiListSettings(settings, false);

      // Assert
      final captured = verify(() => mockRepo.transaction(captureAny(),
          fetchRemote: any(named: 'fetchRemote'),
          cacheLevel: any(named: 'cacheLevel'))).captured;
      final builder = captured.first as JNAPTransactionBuilder;

      expect(builder.commands.any((e) => e.key == JNAPAction.setRadioSettings),
          isTrue);
      expect(
          builder.commands
              .any((e) => e.key == JNAPAction.setGuestRadioSettings),
          isFalse);
    });

    test('saveWifiListSettings merges guest settings when supported', () async {
      final settings = WiFiListSettings(
          mainWiFi: const [],
          guestWiFi: const GuestWiFiItem(
            isEnabled: true,
            ssid: 'guest',
            password: 'pass',
            numOfDevices: 0,
          ),
          isSimpleMode: false,
          simpleModeWifi: WiFiItem.fromMap(const {
            'channel': 0,
            'isBroadcast': true,
            'isEnabled': true,
            'numOfDevices': 0
          }));

      // Mock getGuestRadioSettings response
      when(() => mockRepo.send(JNAPAction.getGuestRadioSettings,
              fetchRemote: true, auth: true))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {
                'isGuestNetworkEnabled': false,
                'isGuestNetworkACaptivePortal': false,
                'radios': [
                  {
                    'radioID': 'RADIO_2.4GHz',
                    'guestSSID': 'Old',
                    'guestWPAPassphrase': 'old',
                    'isEnabled': false,
                    'broadcastGuestSSID': true,
                    'canEnableRadio': true
                  }
                ]
              }));

      when(() => mockRepo.transaction(any(),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel')))
          .thenAnswer((_) async =>
              JNAPTransactionSuccessWrap(result: 'OK', data: const []));

      await service.saveWifiListSettings(settings, true);

      final captured = verify(() => mockRepo.transaction(captureAny(),
          fetchRemote: any(named: 'fetchRemote'),
          cacheLevel: any(named: 'cacheLevel'))).captured;
      final builder = captured.first as JNAPTransactionBuilder;

      expect(builder.commands.any((e) => e.key == JNAPAction.setRadioSettings),
          isTrue);
      expect(
          builder.commands
              .any((e) => e.key == JNAPAction.setGuestRadioSettings),
          isTrue);
    });

    test('savePrivacySettings sends correct MAC filter settings', () async {
      final settings = InstantPrivacySettings.init().copyWith(
          mode: MacFilterMode.deny, denyMacAddresses: ['AA:BB:CC:DD:EE:FF']);

      // Mock response for setMACFilterSettings (single command, not transaction)
      when(() => mockRepo.send(JNAPAction.setMACFilterSettings,
              data: any(named: 'data'),
              auth: true,
              fetchRemote: true,
              cacheLevel: any(named: 'cacheLevel')))
          .thenAnswer((_) async =>
              JNAPSuccess(result: 'OK', output: const {'deviceID': 'dev-1'}));

      await service.savePrivacySettings(settings: settings, nodeDevices: []);

      final captured = verify(() => mockRepo.send(
          JNAPAction.setMACFilterSettings,
          data: captureAny(named: 'data'),
          auth: true,
          fetchRemote: true,
          cacheLevel: any(named: 'cacheLevel'))).captured;
      final data = captured.first as Map<String, dynamic>;

      expect(data['macFilterMode'], 'Deny');
      expect(
          (data['macAddresses'] as List).contains('AA:BB:CC:DD:EE:FF'), true);
    });

    test('savePrivacySettings merges lists in Allow mode', () async {
      final settings = InstantPrivacySettings.init().copyWith(
          mode: MacFilterMode.allow,
          macAddresses: ['11:11:11:11:11:11'],
          bssids: ['33:33:33:33:33:33']);
      final nodeDevice = MockLinksysDevice();
      // Configure knownInterfaces so getMacAddress() extension works
      when(() => nodeDevice.knownInterfaces).thenReturn([
        const RawDeviceKnownInterface(
            macAddress: '22:22:22:22:22:22', interfaceType: 'Wired')
      ]);
      // Also mock knownMACAddresses to be safe if implementation falls back
      when(() => nodeDevice.knownMACAddresses).thenReturn(null);

      when(() => mockRepo.send(JNAPAction.setMACFilterSettings,
              data: any(named: 'data'),
              auth: true,
              fetchRemote: true,
              cacheLevel: any(named: 'cacheLevel')))
          .thenAnswer((_) async =>
              JNAPSuccess(result: 'OK', output: const {'deviceID': 'dev-1'}));

      await service
          .savePrivacySettings(settings: settings, nodeDevices: [nodeDevice]);

      final captured = verify(() => mockRepo.send(
          JNAPAction.setMACFilterSettings,
          data: captureAny(named: 'data'),
          auth: true,
          fetchRemote: true,
          cacheLevel: any(named: 'cacheLevel'))).captured;
      final data = captured.first as Map<String, dynamic>;
      final sentMacs = List<String>.from(data['macAddresses']);

      expect(data['macFilterMode'], 'Allow');
      expect(sentMacs.contains('11:11:11:11:11:11'), true);
      expect(sentMacs.contains('22:22:22:22:22:22'), true); // Node
      expect(sentMacs.contains('33:33:33:33:33:33'), true); // BSSID
    });

    // --- Device List Filter Tests ---
    group('getFilteredDeviceList', () {
      test('filters out devices in bssid list', () {
        final devices = [
          const DeviceListItem(macAddress: 'AA:AA:AA:AA:AA:AA', name: 'Dev1'),
          const DeviceListItem(macAddress: 'BB:BB:BB:BB:BB:BB', name: 'Dev2'),
        ];
        final macAddresses = ['AA:AA:AA:AA:AA:AA', 'BB:BB:BB:BB:BB:BB'];
        final bssidList = ['BB:BB:BB:BB:BB:BB']; // exclude this one

        final result = service.getFilteredDeviceList(
            allDevices: devices,
            macAddresses: macAddresses,
            bssidList: bssidList);

        expect(result.length, 1);
        expect(result.first.macAddress, 'AA:AA:AA:AA:AA:AA');
      });

      test('creates default items for unknown macs', () {
        final devices = <DeviceListItem>[];
        final macAddresses = ['AA:AA:AA:AA:AA:AA'];
        final bssidList = <String>[];

        final result = service.getFilteredDeviceList(
            allDevices: devices,
            macAddresses: macAddresses,
            bssidList: bssidList);

        expect(result.length, 1);
        expect(result.first.name, '--');
      });
    });
  });
}
