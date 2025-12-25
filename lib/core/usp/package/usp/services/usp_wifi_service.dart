/// USP WiFi Service
///
/// Provides WiFi settings via USP/TR-181 protocol.
library;

import '../tr181_paths.dart';
import '../connection/usp_grpc_client_service.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

/// Service for retrieving WiFi settings via USP.
///
/// This service handles radio configuration, guest networks, and MAC filtering.
class UspWifiService {
  final UspGrpcClientService _grpcService;

  /// Creates a new [UspWifiService].
  UspWifiService(this._grpcService);

  /// Retrieves radio information.
  ///
  /// Returns a map containing isBandSteeringSupported and radios list.
  Future<Map<String, dynamic>> getRadioInfo() async {
    final paths =
        Tr181Paths.radioInfoPaths.map((p) => UspPath.parse(p)).toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapRadioInfo(response);
  }

  /// Retrieves guest radio settings.
  ///
  /// Returns a map containing isGuestNetworkEnabled and radios list with guest settings.
  Future<Map<String, dynamic>> getGuestRadioSettings() async {
    final paths = Tr181Paths.guestRadioSettingsPaths
        .map((p) => UspPath.parse(p))
        .toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapGuestRadioSettings(response);
  }

  /// Retrieves MAC filter settings.
  ///
  /// Returns a map containing macFilterMode, isEnabled, macAddresses list.
  Future<Map<String, dynamic>> getMACFilterSettings() async {
    final paths =
        Tr181Paths.macFilterSettingsPaths.map((p) => UspPath.parse(p)).toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapMACFilterSettings(response);
  }

  // ===========================================================================
  // Private Mapping Methods
  // ===========================================================================

  Map<String, dynamic> _mapRadioInfo(UspGetResponse response) {
    final values = _flattenResults(response);

    // Group by radio instances
    final radios = <Map<String, dynamic>>[];
    final radioCount = int.tryParse(
            values['Device.WiFi.RadioNumberOfEntries']?.toString() ?? '0') ??
        0;

    for (int i = 1; i <= radioCount; i++) {
      final prefix = 'Device.WiFi.Radio.$i';
      final ssidPrefix = 'Device.WiFi.SSID.$i';
      final apPrefix = 'Device.WiFi.AccessPoint.$i';

      // Parse PossibleChannels: "1,2,3,4,5,6,7,8,9,10,11,12,13" -> [1,2,...]
      final possibleChannelsStr =
          values['$prefix.PossibleChannels']?.toString() ?? '';
      final possibleChannels = possibleChannelsStr.isNotEmpty
          ? possibleChannelsStr
              .split(',')
              .map((c) => int.tryParse(c.trim()) ?? 0)
              .toList()
          : <int>[];

      // Parse SupportedStandards: "b,g,n,ax" -> ["802.11bg", "802.11bgn", ...]
      final supportedStandardsStr =
          values['$prefix.SupportedStandards']?.toString() ?? 'n,ax';
      final supportedModes = _convertToJnapModes(supportedStandardsStr);

      // Get current operating mode
      final operatingStandards =
          values['$prefix.OperatingStandards']?.toString() ?? 'ax';
      final currentMode = _convertToJnapMode(operatingStandards);

      // Get channel width
      final channelWidth =
          values['$prefix.OperatingChannelBandwidth']?.toString() ?? 'Auto';

      // Build supportedChannelsForChannelWidths based on SupportedStandards
      final supportedChannelsForWidths = _buildSupportedChannelsForWidths(
          supportedStandardsStr, possibleChannels);

      // Parse Security.ModesSupported
      final securityModesStr =
          values['$apPrefix.Security.ModesSupported']?.toString() ?? '';
      final supportedSecurityTypes = securityModesStr.isNotEmpty
          ? securityModesStr.split(',').map((s) => s.trim()).toList()
          : <String>['None', 'WPA2-Personal', 'WPA3-Personal'];

      // Get radio ID and band from TR-181 Name field
      final radioName = values['$prefix.Name']?.toString() ?? 'RADIO_$i';
      final band = values['$prefix.OperatingFrequencyBand']?.toString() ?? '';

      radios.add({
        'radioID': radioName,
        'physicalRadioID': 'ath${i - 1}0',
        'bssid': values['$ssidPrefix.MACAddress']?.toString() ?? '',
        'band': band,
        'supportedModes': supportedModes,
        'defaultMixedMode':
            supportedModes.isNotEmpty ? supportedModes.last : currentMode,
        'supportedChannelsForChannelWidths': supportedChannelsForWidths,
        'supportedSecurityTypes': supportedSecurityTypes,
        'maxRADIUSSharedKeyLength': 64,
        'settings': {
          'isEnabled': values['$prefix.Enable']?.toString() == 'true',
          'mode': currentMode,
          'ssid': values['$ssidPrefix.SSID']?.toString() ?? '',
          'broadcastSSID':
              values['$apPrefix.SSIDAdvertisementEnabled']?.toString() ==
                  'true',
          'channelWidth': channelWidth,
          'channel':
              int.tryParse(values['$prefix.Channel']?.toString() ?? '0') ?? 0,
          'security': values['$apPrefix.Security.ModeEnabled']?.toString() ??
              'WPA2-Personal',
          'wpaPersonalSettings': {
            'passphrase':
                values['$apPrefix.Security.KeyPassphrase']?.toString() ?? '',
          },
        },
      });
    }

    return {
      'isBandSteeringSupported': false, // Demo default
      'radios': radios,
    };
  }

  Map<String, dynamic> _mapGuestRadioSettings(UspGetResponse response) {
    final values = _flattenResults(response);

    // Look for guest access points (typically IsolationEnable = true or index 4+)
    final guestRadios = <Map<String, dynamic>>[];
    final apCount = int.tryParse(
            values['Device.WiFi.AccessPointNumberOfEntries']?.toString() ??
                '4') ??
        4;

    // Guest AP is typically index 4 in Linksys setups
    for (int i = 4; i <= apCount; i++) {
      final apPrefix = 'Device.WiFi.AccessPoint.$i';
      final ssidPrefix = 'Device.WiFi.SSID.$i';

      // Check if this looks like a guest AP
      final isEnabled = values['$apPrefix.Enable']?.toString() == 'true';
      final ssid = values['$ssidPrefix.SSID']?.toString() ?? 'Guest';

      // Derive radio from SSID LowerLayers or use index heuristic
      String radioId = 'RADIO_2.4GHz';
      if (i == 5) radioId = 'RADIO_5GHz';
      if (i == 6) radioId = 'RADIO_6GHz';

      guestRadios.add({
        'radioID': radioId,
        'isEnabled': isEnabled,
        'broadcastGuestSSID':
            values['$apPrefix.SSIDAdvertisementEnabled']?.toString() == 'true',
        'guestSSID': ssid,
        'guestPassword':
            values['$apPrefix.Security.KeyPassphrase']?.toString() ?? '',
        'canEnableRadio': true,
        'maxSimultaneousGuests': 50,
      });
    }

    // If no specific guest APs found, provide default
    if (guestRadios.isEmpty) {
      guestRadios.add({
        'radioID': 'RADIO_2.4GHz',
        'isEnabled': false,
        'broadcastGuestSSID': true,
        'guestSSID': 'Guest',
        'guestPassword': '',
        'canEnableRadio': true,
        'maxSimultaneousGuests': 50,
      });
    }

    return {
      'isGuestNetworkACaptivePortal': false, // Not supported via TR-181
      'isGuestNetworkEnabled': guestRadios.any((r) => r['isEnabled'] == true),
      'radios': guestRadios,
      'maxSimultaneousGuests': 50,
    };
  }

  Map<String, dynamic> _mapMACFilterSettings(UspGetResponse response) {
    final values = _flattenResults(response);

    // Usually MAC filtering is global or per-AP
    final prefix = 'Device.WiFi.AccessPoint.1';

    final isEnabled =
        values['$prefix.MACAddressControlEnabled']?.toString() == 'true';
    final macListStr = values['$prefix.AllowedMACAddress']?.toString() ?? '';

    // TR-181 AllowedMACAddress is CSV
    final macList = macListStr.isNotEmpty
        ? macListStr.split(',').map((s) => s.trim()).toList()
        : <String>[];

    return {
      'macFilterMode': isEnabled ? 'Allow' : 'Deny', // Simple mapping
      'isEnabled': isEnabled,
      'macAddresses': macList,
      'maxMACAddresses': 32,
    };
  }

  // ===========================================================================
  // Helper Methods - WiFi Standards Conversion
  // ===========================================================================

  /// Convert TR-181 standards string to JNAP mode list.
  /// e.g., "b,g,n,ax" -> ["802.11bg", "802.11bgn", "802.11bgnax"]
  List<String> _convertToJnapModes(String standardsStr) {
    final standards = standardsStr.split(',').map((s) => s.trim()).toList();
    final modes = <String>[];

    if (standards.contains('b') && standards.contains('g')) {
      modes.add('802.11bg');
    }
    if (standards.contains('n')) {
      modes.add('802.11bgn');
    }
    if (standards.contains('ax')) {
      modes.add('802.11bgnax');
    }
    if (standards.contains('a')) {
      modes.add('802.11a');
    }
    if (standards.contains('ac')) {
      modes.add('802.11anac');
    }
    if (standards.contains('be')) {
      modes.add('802.11anacaxbe');
    }

    // Always add mixed mode as default
    if (modes.isNotEmpty) {
      modes.add('802.11mixed');
    }

    return modes.isEmpty ? ['802.11mixed'] : modes;
  }

  /// Convert single TR-181 standard to JNAP mode.
  String _convertToJnapMode(String standard) {
    switch (standard) {
      case 'ax':
        return '802.11ax';
      case 'ac':
        return '802.11ac';
      case 'n':
        return '802.11n';
      case 'be':
        return '802.11be';
      default:
        return '802.11mixed';
    }
  }

  /// Build supportedChannelsForChannelWidths from standards.
  List<Map<String, dynamic>> _buildSupportedChannelsForWidths(
      String standardsStr, List<int> channels) {
    final result = <Map<String, dynamic>>[];

    // Auto width always included
    result.add({
      'channelWidth': 'Auto',
      'channels': [0, ...channels],
    });

    // Standard (20MHz) always available
    result.add({
      'channelWidth': 'Standard',
      'channels': [0, ...channels],
    });

    // Wide (40MHz) if n/ac/ax/be
    if (standardsStr.contains('n') ||
        standardsStr.contains('ac') ||
        standardsStr.contains('ax') ||
        standardsStr.contains('be')) {
      result.add({
        'channelWidth': 'Wide',
        'channels': [0, ...channels],
      });
    }

    return result;
  }

  Map<String, dynamic> _flattenResults(UspGetResponse response) {
    final result = <String, dynamic>{};
    for (final entry in response.results.entries) {
      result[entry.key.fullPath] = entry.value.value;
    }
    return result;
  }
}
