// What a router answers PnP, in the router's own JSON, for the PnP tests that
// run the real PnpNotifier over a RouterBoundary.

import 'dart:convert';

import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import '../../../common/router_boundary.dart';
import '../../../test_data/device_info_test_data.dart';

/// `GetDeviceInfo` output of the router PnP is setting up.
final Map<String, dynamic> pnpDeviceInfo =
    Map<String, dynamic>.from(jsonDecode(testDeviceInfo)['output']);

/// Its serial number.
final String pnpSerial = pnpDeviceInfo['serialNumber'] as String;

/// One radio of `GetRadioInfo` output, as the router shipped: every band on
/// the same name and WPA passphrase.
Map<String, dynamic> pnpRadio(
  String radioID,
  String band, {
  String ssid = 'Linksys00042',
  String? passphrase = 'RouterPass1',
  int channel = 0,
}) =>
    {
      'radioID': radioID,
      'physicalRadioID': 'ath${band == '2.4GHz' ? 0 : 1}',
      'bssid': '00:11:22:33:44:5${band == '2.4GHz' ? 0 : 1}',
      'band': band,
      'supportedModes': ['802.11mixed'],
      'defaultMixedMode': '802.11mixed',
      'supportedChannelsForChannelWidths': [
        {
          'channelWidth': 'Auto',
          'channels': [0, 1, 6, 11, 36, 149]
        },
      ],
      'supportedSecurityTypes': ['None', 'WPA2/WPA3-Mixed-Personal'],
      'maxRADIUSSharedKeyLength': 64,
      'settings': {
        'isEnabled': true,
        'mode': '802.11mixed',
        'ssid': ssid,
        'broadcastSSID': true,
        'channelWidth': 'Auto',
        'channel': channel,
        'security': passphrase == null ? 'None' : 'WPA2/WPA3-Mixed-Personal',
        if (passphrase != null)
          'wpaPersonalSettings': {'passphrase': passphrase},
      },
    };

/// One band of a `SetRadioSettings` payload: the band's settings as
/// [pnpRadio] holds them, with [ssid] and [passphrase].
Map<String, dynamic> pnpSavedBand(
  String radioID,
  String band, {
  required String ssid,
  String? passphrase,
  int channel = 0,
}) =>
    {
      'radioID': radioID,
      'settings': pnpRadio(radioID, band,
          ssid: ssid, passphrase: passphrase, channel: channel)['settings'],
    };

/// `GetRadioInfo` output of a two-band router.
Map<String, dynamic> pnpRadioInfo({
  List<Map<String, dynamic>>? radios,
}) =>
    {
      'isBandSteeringSupported': true,
      'radios': radios ??
          [
            pnpRadio('RADIO_2.4GHz', '2.4GHz'),
            pnpRadio('RADIO_5GHz', '5GHz', channel: 149),
          ],
    };

/// `GetGuestRadioSettings` output: guest WiFi off, on the router's defaults.
const Map<String, dynamic> pnpGuestRadioSettings = {
  'isGuestNetworkACaptivePortal': false,
  'isGuestNetworkEnabled': false,
  'radios': [
    {
      'radioID': 'RADIO_2.4GHz',
      'isEnabled': true,
      'broadcastGuestSSID': true,
      'guestSSID': 'Linksys00042-guest',
      'guestWPAPassphrase': 'BeMyGuest',
      'canEnableRadio': true,
    },
    {
      'radioID': 'RADIO_5GHz',
      'isEnabled': true,
      'broadcastGuestSSID': true,
      'guestSSID': 'Linksys00042-guest',
      'guestWPAPassphrase': 'BeMyGuest',
      'canEnableRadio': true,
    },
  ],
};

/// `GetFirmwareUpdateSettings` output: manual updates, in the router's window.
const Map<String, dynamic> pnpFirmwareUpdateSettings = {
  'updatePolicy': 'Manual',
  'autoUpdateWindow': {'startMinute': 120, 'durationMinutes': 180},
};

/// `GetAutoConfigurationSettings` output.
Map<String, dynamic> pnpAutoConfiguration({
  String method = 'PreConfigured',
  bool acknowledged = false,
}) =>
    {
      'isAutoConfigurationSupported': true,
      'userAcknowledgedAutoConfiguration': acknowledged,
      'autoConfigurationMethod': method,
    };

/// A device of `GetDevices` output: a node when [nodeType] is given, the
/// router itself when it is `Master`, and a client otherwise.
Map<String, dynamic> pnpDevice(String id,
        {String? nodeType, String? location}) =>
    {
      'connections': [
        {'macAddress': 'mac-$id', 'ipAddress': '192.168.1.${id.length + 10}'},
      ],
      'properties': [
        if (location != null) {'name': 'userDeviceLocation', 'value': location},
      ],
      'unit': <String, dynamic>{},
      'deviceID': id,
      'maxAllowedProperties': 16,
      'model': {
        'deviceType': nodeType == null ? 'Computer' : 'Infrastructure',
        if (nodeType != null) 'modelNumber': 'LN16',
      },
      'isAuthority': nodeType == 'Master',
      'lastChangeRevision': 1,
      'knownInterfaces': [
        {'macAddress': 'mac-$id', 'interfaceType': 'Wired'},
      ],
      if (nodeType != null) 'nodeType': nodeType,
    };

/// The router holds what PnP reads on the way to its save: the reads of
/// `fetchData`, the admin password state, and the device info it checks after
/// the save.
void holdPnpReads(
  RouterBoundary router, {
  Map<String, dynamic>? radioInfo,
  Map<String, dynamic> guestRadioSettings = pnpGuestRadioSettings,
  Map<String, dynamic>? autoConfiguration,
  bool passwordSetByUser = false,
}) {
  router
    ..holds(JNAPAction.getSimpleWiFiSettings, {'simpleWiFiSettings': []})
    ..holds(JNAPAction.getGuestRadioSettings, guestRadioSettings)
    ..holds(JNAPAction.getLedNightModeSetting,
        {'Enable': false, 'StartingTime': 20, 'EndingTime': 8})
    ..holds(JNAPAction.getAutoConfigurationSettings,
        autoConfiguration ?? pnpAutoConfiguration())
    ..holds(JNAPAction.getBluetoothAutoOnboardingSettings,
        {'isAutoOnboardingEnabled': false})
    ..holds(JNAPAction.getRadioInfo, radioInfo ?? pnpRadioInfo())
    ..holds(JNAPAction.getWANSettings, {'wanType': 'DHCP', 'mtu': 0})
    ..holds(JNAPAction.getFirmwareUpdateSettings, pnpFirmwareUpdateSettings)
    ..holds(JNAPAction.isAdminPasswordDefault,
        {'isAdminPasswordDefault': !passwordSetByUser})
    ..holds(JNAPAction.isAdminPasswordSetByUser,
        {'isAdminPasswordSetByUser': passwordSetByUser})
    ..holds(JNAPAction.getDeviceInfo, pnpDeviceInfo);
}
