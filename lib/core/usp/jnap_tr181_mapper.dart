/// JNAP to TR-181 Mapper
///
/// Maps JNAP Actions to TR-181 paths and converts responses.
library;

import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

/// Mapper for converting between JNAP Actions and TR-181 paths.
///
/// This mapper supports:
/// - Converting JNAP Actions to TR-181 path patterns
/// - Converting USP GetResponse to JNAP-style output maps
class JnapTr181Mapper {
  /// Maps JNAP Action names to their corresponding TR-181 paths.
  ///
  /// Note: Only include actions here if toJnapResponse has a proper handler.
  /// Actions without handlers should use fallback responses instead.
  ///
  /// GetDeviceInfo is NOT included here intentionally - the app needs the
  /// full services list (150+ items) from demo_cache_data.json for
  /// buildBetterActions() to work properly.
  ///
  /// Use BASE NAMES only (no version suffix). The lookup logic will strip
  /// version suffixes automatically, e.g., GetRadioInfo3 → GetRadioInfo.
  static const _actionPathMappings = <String, List<String>>{
    // Device Info - services list handled by mock serviceHelper
    'GetDeviceInfo': ['Device.DeviceInfo.'],

    // WiFi - Radio
    'GetRadioInfo': [
      'Device.WiFi.', // For RadioNumberOfEntries
      'Device.WiFi.Radio.',
      'Device.WiFi.SSID.',
      'Device.WiFi.AccessPoint.',
    ],

    // Connected Devices - Clients + Mesh Nodes
    'GetDevices': [
      'Device.Hosts.', // For HostNumberOfEntries
      'Device.Hosts.Host.', // Client devices
      'Device.WiFi.MultiAP.', // For APDeviceNumberOfEntries
      'Device.WiFi.MultiAP.APDevice.', // Mesh nodes
    ],

    // Backhaul Info for mesh nodes
    'GetBackhaulInfo': [
      'Device.WiFi.MultiAP.',
      'Device.WiFi.MultiAP.APDevice.',
    ],

    // Network - WAN Status
    'GetWANStatus': [
      'Device.IP.Interface.1.',
      'Device.Ethernet.Interface.1.',
      'Device.DHCPv4.Client.',
      'Device.Routing.Router.1.',
    ],

    // Diagnostics
    'GetSystemStats': ['Device.DeviceInfo.'],
    'GetInternetConnectionStatus': ['Device.IP.Interface.1.'],
    'GetEthernetPortConnections': ['Device.Ethernet.Interface.'],
    'GetNetworkConnections': [
      'Device.Hosts.Host.',
      'Device.WiFi.Radio.', // To map Frequency Band
      'Device.WiFi.AccessPoint.', // To map AssociatedDevice
      'Device.WiFi.SSID.', // To map BSSID (MACAddress)
    ],
    'GetNodesWirelessNetworkConnections': [
      'Device.WiFi.MultiAP.APDevice.', // To find Master Node ID
      'Device.WiFi.AccessPoint.', // To get AssociatedDevice connections
      'Device.WiFi.SSID.', // To map BSSID (MACAddress)
    ],

    // LAN Settings - WORKS!
    'GetLANSettings': ['Device.IP.Interface.2.', 'Device.DHCPv4.'],

    // Time
    'GetLocalTime': ['Device.Time.'],
    'GetTimeSettings': ['Device.Time.'],

    // Guest Network
    'GetGuestRadioSettings': [
      'Device.WiFi.', // For AccessPointNumberOfEntries
      'Device.WiFi.AccessPoint.',
      'Device.WiFi.SSID.',
      'Device.WiFi.Radio.',
    ],

    // MAC Filtering
    'GetMACFilterSettings': [
      'Device.WiFi.AccessPoint.',
    ],
  };

  /// Gets the TR-181 paths for a given JNAP Action.
  ///
  /// Strips version suffix from action name to match base mapping.
  /// e.g., GetRadioInfo3 → GetRadioInfo
  List<String> getTr181Paths(JNAPAction action) {
    final actionName = _extractActionName(action.actionValue);

    // Try exact match first
    var paths = _actionPathMappings[actionName];
    if (paths != null) return paths;

    // Try base name without version suffix
    final baseName = _stripVersionSuffix(actionName);
    if (baseName != actionName) {
      paths = _actionPathMappings[baseName];
      if (paths != null) return paths;
    }

    return [];
  }

  /// Strips version suffix from action name.
  /// e.g., "GetRadioInfo3" → "GetRadioInfo"
  String _stripVersionSuffix(String actionName) {
    final regex = RegExp(r'[2-9]+$');
    return actionName.replaceFirst(regex, '');
  }

  /// Extracts the action name from a JNAP action URL.
  ///
  /// Example: 'http://linksys.com/jnap/core/GetDeviceInfo' → 'GetDeviceInfo'
  String _extractActionName(String actionUrl) {
    return actionUrl.split('/').last;
  }

  /// Converts a USP GetResponse to a JNAP-style output map.
  ///
  /// The conversion is based on the original JNAP Action type.
  Map<String, dynamic> toJnapResponse(
    JNAPAction action,
    UspGetResponse response,
  ) {
    final actionName = _extractActionName(action.actionValue);
    // Use base name for switch matching (strips version suffix)
    final baseName = _stripVersionSuffix(actionName);

    logger.d('🔄 Mapping USP response for $actionName (base: $baseName)');
    logger.d('   Raw USP values: ${response.results.length} items');

    // Print raw TR-181 data received
    final buffer = StringBuffer();
    buffer.writeln('   📦 Raw TR-181 Data:');
    for (final entry in response.results.entries) {
      buffer.writeln('      ${entry.key.fullPath} = ${entry.value.value}');
    }
    logger.d(buffer.toString());

    Map<String, dynamic> result;
    switch (baseName) {
      case 'GetDeviceInfo':
        result = _mapDeviceInfo(response);
        break;
      case 'GetRadioInfo':
        result = _mapRadioInfo(response);
        break;
      case 'GetDevices':
        result = _mapDevices(response);
        break;
      case 'GetBackhaulInfo':
        result = _mapBackhaulInfo(response);
        break;
      case 'GetWANStatus':
      case 'GetWANSettings':
        result = _mapWANStatus(response);
        break;
      case 'GetLANSettings':
        result = _mapLANSettings(response);
        break;
      case 'GetLocalTime':
      case 'GetTimeSettings':
        result = _mapTimeSettings(response);
        break;
      case 'GetGuestRadioSettings':
        result = _mapGuestRadioSettings(response);
        break;
      case 'GetMACFilterSettings':
        result = _mapMACFilterSettings(response);
        break;
      case 'GetSystemStats':
        result = _mapSystemStats(response);
        break;
      case 'GetInternetConnectionStatus':
        result = _mapInternetConnectionStatus(response);
        break;
      case 'GetEthernetPortConnections':
        result = _mapEthernetPortConnections(response);
        break;
      case 'GetNetworkConnections':
        result = _mapNetworkConnections2(response);
        break;
      case 'GetNodesWirelessNetworkConnections':
        result = _mapNodesWirelessNetworkConnections2(response);
        break;
      default:
        logger.w('⚠️ No mapper for action: $baseName');
        result = _mapGeneric(response);
    }

    // Print mapped JNAP output
    logger.d('   ✅ Mapped JNAP output: $result');
    return result;
  }

  /// Maps Device.DeviceInfo.* to JNAP GetDeviceInfo response format.
  ///
  /// Required fields for NodeDeviceInfo:
  /// - modelNumber, firmwareVersion, description, firmwareDate
  /// - manufacturer, serialNumber, hardwareVersion, services (List)
  Map<String, dynamic> _mapDeviceInfo(UspGetResponse response) {
    final values = _flattenResults(response);
    return {
      'manufacturer':
          values['Device.DeviceInfo.Manufacturer']?.toString() ?? 'Unknown',
      'modelNumber':
          values['Device.DeviceInfo.ModelName']?.toString() ?? 'Unknown',
      'serialNumber':
          values['Device.DeviceInfo.SerialNumber']?.toString() ?? 'Unknown',
      'hardwareVersion':
          values['Device.DeviceInfo.HardwareVersion']?.toString() ?? 'v1.0',
      'firmwareVersion':
          values['Device.DeviceInfo.SoftwareVersion']?.toString() ?? '1.0.0',
      'firmwareDate': '', // TR-181 doesn't have this, use empty string
      'description': values['Device.DeviceInfo.Description']?.toString() ?? '',
      'services': _supportedServices,
    };
  }

  /// List of JNAP services supported by this mapper.
  /// This is used to populate the 'services' field in GetDeviceInfo.
  /// NOTE: These must be SERVICE URLs (e.g. .../core/Core), NOT Action URLs.
  static const _supportedServices = <String>[
    'http://linksys.com/jnap/core/Core',
    'http://linksys.com/jnap/wirelessap/WirelessAP',
    'http://linksys.com/jnap/wirelessap/WirelessAP2',
    'http://linksys.com/jnap/wirelessap/WirelessAP3',
    'http://linksys.com/jnap/devicelist/DeviceList',
    'http://linksys.com/jnap/devicelist/DeviceList2',
    'http://linksys.com/jnap/nodes/diagnostics/Diagnostics',
    'http://linksys.com/jnap/nodes/diagnostics/Diagnostics2',
    'http://linksys.com/jnap/router/Router',
    'http://linksys.com/jnap/router/Router2',
    'http://linksys.com/jnap/router/Router3',
    'http://linksys.com/jnap/locale/Locale',
    'http://linksys.com/jnap/guestnetwork/GuestNetwork',
    'http://linksys.com/jnap/guestnetwork/GuestNetwork2',
    'http://linksys.com/jnap/macfilter/MACFilter',
    'http://linksys.com/jnap/macfilter/MACFilter2',
    'http://linksys.com/jnap/networkconnections/NetworkConnections',
    'http://linksys.com/jnap/networkconnections/NetworkConnections2',
  ];

  /// Maps Device.WiFi.* to JNAP GetRadioInfo response format.
  ///
  /// Uses TR-181 standard fields:
  /// - PossibleChannels: "1,2,3,4,5,6,7,8,9,10,11,12,13"
  /// - SupportedStandards: "b,g,n,ax"
  /// - OperatingChannelBandwidth: "Auto", "20MHz", "40MHz", etc.
  /// - Security.ModesSupported: "None,WPA2-Personal,WPA3-Personal"
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

  /// Maps Device.Hosts.Host.* + Device.WiFi.MultiAP.APDevice.* to GetDevices.
  ///
  /// Combines client devices from Hosts and mesh nodes from MultiAP.
  Map<String, dynamic> _mapDevices(UspGetResponse response) {
    final values = _flattenResults(response);
    final devices = <Map<String, dynamic>>[];

    // 1. Add client devices from Hosts
    final hostCount = int.tryParse(
            values['Device.Hosts.HostNumberOfEntries']?.toString() ?? '0') ??
        0;

    // Find Master Node ID for parentDeviceID linkage
    String masterNodeId = '';
    final multiApCount = int.tryParse(
            values['Device.WiFi.MultiAP.APDeviceNumberOfEntries']?.toString() ??
                '0') ??
        0;
    for (int i = 1; i <= multiApCount; i++) {
      if (values['Device.WiFi.MultiAP.APDevice.$i.BackhaulLinkType']
              ?.toString() ==
          'None') {
        masterNodeId =
            values['Device.WiFi.MultiAP.APDevice.$i.MACAddress']?.toString() ??
                '';
        break;
      }
    }
    if (masterNodeId.isEmpty) masterNodeId = '00:00:00:00:00:00'; // Fallback

    for (int i = 1; i <= hostCount; i++) {
      final prefix = 'Device.Hosts.Host.$i';
      final mac = values['$prefix.PhysAddress']?.toString() ?? '';
      final ifType = values['$prefix.InterfaceType']?.toString() ?? '';
      final layer1 = values['$prefix.Layer1Interface']?.toString() ?? '';

      String? band;
      if (ifType == '802.11') {
        // Derive band from SSID reference: Device.WiFi.SSID.1 -> 2.4GHz
        final ssidIndex = int.tryParse(layer1.split('.').lastOrNull ?? '') ?? 0;
        if (ssidIndex == 1 || ssidIndex == 4) band = '2.4GHz';
        if (ssidIndex == 2) band = '5GHz';
        if (ssidIndex == 3) band = '6GHz';
      }

      devices.add(<String, dynamic>{
        'deviceID': mac.isNotEmpty ? mac : 'unknown-$i',
        'properties': <Map<String, dynamic>>[],
        'unit': <String, dynamic>{},
        'maxAllowedProperties': 10,
        'model': <String, dynamic>{'deviceType': 'Computer'},
        'lastChangeRevision': 0,
        'knownMACAddresses': [mac],
        'knownInterfaces': [
          {
            'macAddress': mac,
            'interfaceType': ifType == '802.11' ? 'Wireless' : 'Wired',
            if (band != null) 'band': band,
          }
        ],
        'friendlyName': values['$prefix.HostName']?.toString() ?? 'Device $i',
        'isAuthority': false,
        'connections': [
          <String, dynamic>{
            'macAddress': mac,
            'ipAddress': values['$prefix.IPAddress']?.toString() ?? '',
            'isOnline': values['$prefix.Active']?.toString() == 'true',
            'interfaceType': ifType == '802.11' ? 'Wireless' : 'Wired',
            'parentDeviceID': masterNodeId,
          }
        ],
      });
    }

    // 2. Add mesh nodes from MultiAP.APDevice
    final apCount = int.tryParse(
            values['Device.WiFi.MultiAP.APDeviceNumberOfEntries']?.toString() ??
                '0') ??
        0;

    for (int i = 1; i <= apCount; i++) {
      final prefix = 'Device.WiFi.MultiAP.APDevice.$i';
      // Use MACAddress as device ID since ID/ALID are not available
      final mac = values['$prefix.MACAddress']?.toString() ?? '';
      final backhaulType =
          values['$prefix.BackhaulLinkType']?.toString() ?? 'None';
      final isMaster = backhaulType == 'None'; // Master has no backhaul
      final serial = values['$prefix.SerialNumber']?.toString() ?? '';
      final parentMac = values['$prefix.BackhaulMACAddress']?.toString() ?? '';

      devices.add(<String, dynamic>{
        'deviceID': mac,
        'properties': <Map<String, dynamic>>[],
        'unit': <String, dynamic>{'serialNumber': serial},
        'maxAllowedProperties': 10,
        'model': <String, dynamic>{
          'deviceType': 'Infrastructure',
          'manufacturer': values['$prefix.Manufacturer']?.toString(),
          'modelNumber': isMaster ? 'Master' : 'Slave',
        },
        'lastChangeRevision': 0,
        'knownMACAddresses': [mac],
        'knownInterfaces': [
          {
            'macAddress': mac,
            'interfaceType':
                (backhaulType == 'Wi-Fi' || isMaster) ? 'Wireless' : 'Wired',
          }
        ],
        'friendlyName': isMaster ? 'Master Router' : 'Mesh Node',
        'isAuthority': isMaster,
        'nodeType': isMaster ? 'Master' : 'Slave',
        'connections': [
          <String, dynamic>{
            'macAddress': mac,
            'ipAddress':
                '', // Nodes might have IP but we don't have it easily here
            'isOnline': 'true', // Mesh nodes derived from APDevice are active
            'interfaceType': 'Infrastructure',
            'parentDeviceID': isMaster ? null : parentMac,
          }
        ],
      });
    }

    return {'devices': devices};
  }

  /// Maps Device.WiFi.MultiAP.APDevice.* to GetBackhaulInfo response format.
  /// Matches BackHaulInfoData model keys.
  Map<String, dynamic> _mapBackhaulInfo(UspGetResponse response) {
    final values = _flattenResults(response);
    final backhaulDevices = <Map<String, dynamic>>[];

    final apCount = int.tryParse(
            values['Device.WiFi.MultiAP.APDeviceNumberOfEntries']?.toString() ??
                '0') ??
        0;

    for (int i = 1; i <= apCount; i++) {
      final prefix = 'Device.WiFi.MultiAP.APDevice.$i';
      final backhaulType =
          values['$prefix.BackhaulLinkType']?.toString() ?? 'None';

      // Skip master node (no backhaul)
      if (backhaulType == 'None') continue;

      final rssi = int.tryParse(
              values['$prefix.BackhaulSignalStrength']?.toString() ?? '0') ??
          0;

      int rssiDbm;
      // If RSSI is negative, it's already in dBm. If positive (0-220), it's RCPI.
      if (rssi < 0) {
        rssiDbm = rssi;
      } else {
        // Convert RCPI (0-220) to dBm: (RCPI / 2) - 110
        rssiDbm = (rssi / 2).round() - 110;
      }

      final mac = values['$prefix.MACAddress']?.toString() ?? '';
      final parentMac = values['$prefix.BackhaulMACAddress']?.toString() ?? '';

      // Mock IPs for demonstration as standard MultiAP APDevice doesn't expose IP easily
      // In real scenario, we might look this up or USP provides it.
      final mockIp = '192.168.1.${10 + i}';
      final mockParentIp = '192.168.1.1'; // Assume master is parent

      backhaulDevices.add(<String, dynamic>{
        'deviceUUID': mac,
        'ipAddress': mockIp,
        'parentIPAddress': mockParentIp,
        'timestamp': DateTime.now().toIso8601String(),
        'connectionType': backhaulType == 'Wi-Fi' ? 'Wireless' : 'Wired',
        'wirelessConnectionInfo': backhaulType == 'Wi-Fi'
            ? <String, dynamic>{
                'radioID': 'RADIO_5GHz', // Mock band
                'channel': 0,
                'apRSSI': rssiDbm,
                'stationRSSI': rssiDbm,
                'apBSSID': parentMac,
                'stationBSSID': mac,
                'txRate': 0,
                'rxRate': 0,
                'isMultiLinkOperation': false,
              }
            : null, // Must be null for Wired
        'speedMbps': '0',
      });
    }

    return {'backhaulDevices': backhaulDevices};
  }

  /// Maps Device.IP.Interface.1.* to JNAP GetWANStatus response format.
  ///
  /// Provides complete WAN status including supportedWANTypes, wanConnection, etc.
  Map<String, dynamic> _mapWANStatus(UspGetResponse response) {
    final values = _flattenResults(response);

    // Get WAN IP info
    final ipAddress =
        values['Device.IP.Interface.1.IPv4Address.1.IPAddress']?.toString() ??
            '';
    final subnetMask =
        values['Device.IP.Interface.1.IPv4Address.1.SubnetMask']?.toString() ??
            '';
    final gateway =
        values['Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress']
                ?.toString() ??
            '';
    final macAddress =
        values['Device.Ethernet.Interface.1.MACAddress']?.toString() ?? '';

    // Determine WAN type from AddressingType
    final addressingType =
        values['Device.IP.Interface.1.IPv4Address.1.AddressingType']
                ?.toString() ??
            'DHCP';
    final wanType = addressingType == 'Static' ? 'Static' : 'DHCP';

    // Determine WAN status from interface status
    final ifStatus = values['Device.IP.Interface.1.Status']?.toString() ?? 'Up';
    final wanStatus = ifStatus == 'Up' ? 'Connected' : 'Disconnected';

    return {
      'macAddress': macAddress,
      'detectedWANType': wanType,
      'wanStatus': wanStatus,
      'wanIPv6Status': 'Disconnected', // Simplified for demo
      'isDetectingWANType': false,
      'wanConnection': {
        'wanType': wanType,
        'ipAddress': ipAddress,
        'networkPrefixLength': _subnetMaskToPrefix(subnetMask),
        'gateway': gateway,
        'mtu': 1500,
        'dhcpLeaseMinutes': wanType == 'DHCP' ? 4320 : null,
        'dnsServer1': gateway.isNotEmpty ? gateway : '8.8.8.8',
      },
      // Hardcoded supported types for demo
      'supportedWANTypes': [
        'DHCP',
        'Static',
        'PPPoE',
        'PPTP',
        'L2TP',
        'Bridge'
      ],
      'supportedIPv6WANTypes': ['Automatic', 'PPPoE', 'Pass-through'],
      'supportedWANCombinations': [
        {'wanType': 'DHCP', 'wanIPv6Type': 'Automatic'},
        {'wanType': 'Static', 'wanIPv6Type': 'Automatic'},
        {'wanType': 'PPPoE', 'wanIPv6Type': 'Automatic'},
      ],
    };
  }

  Map<String, dynamic> _mapSystemStats(UspGetResponse response) {
    final values = _flattenResults(response);
    final uptime =
        int.tryParse(values['Device.DeviceInfo.UpTime']?.toString() ?? '0') ??
            0;
    final cpuUsage = int.tryParse(
            values['Device.DeviceInfo.ProcessStatus.CPUUsage']?.toString() ??
                '0') ??
        0;
    final memTotal = int.tryParse(
            values['Device.DeviceInfo.MemoryStatus.Total']?.toString() ??
                '1') ??
        1;
    final memFree = int.tryParse(
            values['Device.DeviceInfo.MemoryStatus.Free']?.toString() ?? '0') ??
        0;

    // Calculate memory load (0.0 - 1.0)
    final memLoad = (memTotal > 0) ? (memTotal - memFree) / memTotal : 0.0;

    return {
      'uptimeSeconds': uptime,
      'CPULoad': (cpuUsage / 100).toString(),
      'MemoryLoad': memLoad.toStringAsFixed(2),
    };
  }

  Map<String, dynamic> _mapInternetConnectionStatus(UspGetResponse response) {
    final values = _flattenResults(response);
    final status = values['Device.IP.Interface.1.Status']?.toString() ?? 'Down';

    final jnapStatus =
        (status == 'Up') ? 'InternetConnected' : 'InternetDisconnected';

    return {
      'connectionStatus': jnapStatus,
    };
  }

  Map<String, dynamic> _mapEthernetPortConnections(UspGetResponse response) {
    final values = _flattenResults(response);
    // WAN -> Device.Ethernet.Interface.1
    final wanEnable =
        values['Device.Ethernet.Interface.1.Enable']?.toString() == 'true';
    final wanBitRate =
        values['Device.Ethernet.Interface.1.MaxBitRate']?.toString() ?? '0';

    String wanConnection = 'Disconnected';
    if (wanEnable) {
      if (wanBitRate == '1000')
        wanConnection = '1Gbps';
      else if (wanBitRate == '100')
        wanConnection = '100Mbps';
      else if (wanBitRate != '0') wanConnection = '${wanBitRate}Mbps';
    }

    // LAN Ports (Interfaces 3+ in mock data)
    final lanList = <String>[];
    final interfaceCount = int.tryParse(
            values['Device.Ethernet.InterfaceNumberOfEntries']?.toString() ??
                '6') ??
        6;

    // LAN ports usually start at index 3 (1=WAN, 2=Bridge)
    for (int i = 3; i <= interfaceCount; i++) {
      // Check if data exists for this index (User might have deleted the entry from JSON)
      final enableKey = 'Device.Ethernet.Interface.$i.Enable';
      if (!values.containsKey(enableKey)) {
        continue;
      }

      final enable = values[enableKey]?.toString() == 'true';
      final bitRate =
          values['Device.Ethernet.Interface.$i.MaxBitRate']?.toString() ?? '0';

      String status = 'Disconnected';
      if (enable) {
        if (bitRate == '1000')
          status = '1Gbps';
        else if (bitRate == '100')
          status = '100Mbps';
        else if (bitRate == '10')
          status = '10Mbps';
        else if (bitRate != '0') status = '${bitRate}Mbps';
      }
      lanList.add(status);
    }

    return {
      'wanPortConnection': wanConnection,
      'lanPortConnections': lanList,
    };
  }

  /// Convert subnet mask to prefix length.
  /// e.g., "255.255.255.0" -> 24
  int _subnetMaskToPrefix(String subnetMask) {
    if (subnetMask.isEmpty) return 24;
    try {
      final parts = subnetMask.split('.');
      if (parts.length != 4) return 24;
      int prefix = 0;
      for (final part in parts) {
        int octet = int.parse(part);
        while (octet > 0) {
          prefix += octet & 1;
          octet >>= 1;
        }
      }
      return prefix;
    } catch (_) {
      return 24;
    }
  }

  /// Maps Device.IP.Interface.2.* and Device.DHCPv4.* to JNAP GetLANSettings.
  Map<String, dynamic> _mapLANSettings(UspGetResponse response) {
    final values = _flattenResults(response);
    final ipAddress = values['Device.IP.Interface.2.IPv4Address.1.IPAddress'] ??
        '192.168.1.1';
    final subnetMask =
        values['Device.IP.Interface.2.IPv4Address.1.SubnetMask'] ??
            '255.255.255.0';
    final isDhcpEnabled = values['Device.DHCPv4.Server.Enable'] == 'true'
        ? true
        : true; // Default true if missing
    final hostName = values['Device.DeviceInfo.HostName'] ?? 'Linksys01234';

    return {
      'ipAddress': ipAddress,
      // 'subnetMask': subnetMask, // Not directly in top-level model, handled by networkPrefixLength
      'minNetworkPrefixLength': 16,
      'maxNetworkPrefixLength': 30,
      'networkPrefixLength': _subnetMaskToPrefix(subnetMask),
      'minAllowedDHCPLeaseMinutes': 1,
      'hostName': hostName,
      'maxDHCPReservationDescriptionLength': 63,
      'isDHCPEnabled': isDhcpEnabled,
      'maxAllowedDHCPLeaseMinutes': 525600,
      'dhcpSettings': {
        // 'isEnabled': isDhcpEnabled, // Not in DHCPSettings model, it's boolean in JNAP
        'lastClientIPAddress':
            values['Device.DHCPv4.Server.Pool.1.MinAddress'] ??
                '192.168.1.2', // Usually .100+
        'firstClientIPAddress':
            values['Device.DHCPv4.Server.Pool.1.MinAddress'] ?? '192.168.1.100',
        'leaseMinutes': 1440,
        'reservations': [],
        // Optional DNS
        'dnsServer1': '8.8.8.8',
        'dnsServer2': '8.8.4.4',
      },
    };
  }

  /// Maps Device.Time.* to JNAP GetLocalTime/GetTimeSettings.
  Map<String, dynamic> _mapTimeSettings(UspGetResponse response) {
    final values = _flattenResults(response);
    final currentTime = values['Device.Time.CurrentLocalTime']?.toString() ??
        DateTime.now().toIso8601String();

    return {
      'currentTime': currentTime,
      'timeZoneID': values['Device.Time.LocalTimeZone'] ?? 'Asia/Taipei',
      'ntpServer1': values['Device.Time.NTPServer1'] ?? '',
      'ntpServer2': values['Device.Time.NTPServer2'] ?? '',
      'isDaylightSaving':
          false, // No easy way to tell from TR-181 without parse
      // Fields requested by various Time actions
      'dstSetting': 'Auto',
      'autoAdjustDST': true,
    };
  }

  /// Maps Device.WiFi.AccessPoint.* to GetGuestRadioSettings.
  /// Looks for AccessPoints where IsolationEnable is true.
  Map<String, dynamic> _mapGuestRadioSettings(UspGetResponse response) {
    final values = _flattenResults(response);
    final guestRadios = <Map<String, dynamic>>[];

    final apCount = int.tryParse(
            values['Device.WiFi.AccessPointNumberOfEntries']?.toString() ??
                '0') ??
        0;

    // We assume 2.4GHz and 5GHz for guest radios if not explicitly mapped
    // But here we iterate APs to find guest ones
    bool isGuestEnabled = false;

    // Pre-scan to check global guest enabled status (if any guest AP is enabled)
    for (int i = 1; i <= apCount; i++) {
      if (values['Device.WiFi.AccessPoint.$i.IsolationEnable']?.toString() ==
          'true') {
        if (values['Device.WiFi.AccessPoint.$i.Enable']?.toString() == 'true') {
          isGuestEnabled = true;
        }
      }
    }

    // Now build radio info list
    // In a real device, we'd map physical radios to guest APs.
    // For this simulation, we'll scan APs, find the guest one,
    // and assume it effectively represents the guest settings for that band.
    for (int i = 1; i <= apCount; i++) {
      final prefix = 'Device.WiFi.AccessPoint.$i';
      final isIsolation =
          values['$prefix.IsolationEnable']?.toString() == 'true';

      if (!isIsolation) continue;

      // Resolve SSID name/enable from reference would require complex lookups
      // or we just trust the flat list has the SSID object data if we asked for it.
      // Since we requested Device.WiFi.SSID., we can try to key match if we knew ID.
      // But typically GetGuestRadioSettings just wants the config.

      // We'll create a GuestRadioInfo entry for this AP
      guestRadios.add(<String, dynamic>{
        // Guess radio ID based on index or just hardcode for demo completeness
        'radioID': (i % 2 == 0) ? 'RADIO_5GHz' : 'RADIO_2.4GHz',
        'isEnabled': values['$prefix.Enable']?.toString() == 'true',
        'broadcastGuestSSID':
            values['$prefix.SSIDAdvertisementEnabled']?.toString() == 'true',
        'guestSSID': 'DartSim_Guest', // Placeholder or need cross-ref
        'guestPassword':
            values['$prefix.Security.KeyPassphrase']?.toString() ?? '',
        'canEnableRadio': true,
      });
    }

    return {
      'isGuestNetworkEnabled': isGuestEnabled,
      'isGuestNetworkACaptivePortal': false,
      'radios': guestRadios,
      'maxSimultaneousGuests': 50,
    };
  }

  /// Maps Device.WiFi.AccessPoint.* to GetMACFilterSettings.
  Map<String, dynamic> _mapMACFilterSettings(UspGetResponse response) {
    final values = _flattenResults(response);

    // Usually MAC filtering is global or per-AP. JNAP usually sets it globally or
    // for the main APs. We'll look at the first AP as the "master" switch.
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

  /// Maps Device.Hosts.Host.* combined with Device.WiFi.AccessPoint.{i}.AssociatedDevice.* to JNAP GetNetworkConnections2.
  Map<String, dynamic> _mapNetworkConnections2(UspGetResponse response) {
    final values = _flattenResults(response);
    final connections = <Map<String, dynamic>>[];

    // 1. Parse Hosts
    final hostCount = int.tryParse(
            values['Device.Hosts.HostNumberOfEntries']?.toString() ?? '0') ??
        0;

    // Helper to find Associated Device for a MAC
    // Returns {downlinkRate, signalStrength, apIndex} or null
    Map<String, dynamic>? findWirelessInfo(String mac) {
      // Iterate APs to find this MAC in AssociatedDevice table
      // Note: In real world, we'd know which AP. Here we scan due to flat structure.
      // We don't have AP count easily available unless we parse AccessPointNumberOfEntries which we requested.
      final apCount = int.tryParse(
              values['Device.WiFi.AccessPointNumberOfEntries']?.toString() ??
                  '4') ??
          4;

      for (int i = 1; i <= apCount; i++) {
        final assocCount = int.tryParse(
                values['Device.WiFi.AccessPoint.$i.AssociatedDeviceNumberOfEntries']
                        ?.toString() ??
                    '0') ??
            0;
        for (int j = 1; j <= assocCount; j++) {
          final assocMac = values[
              'Device.WiFi.AccessPoint.$i.AssociatedDevice.$j.MACAddress'];
          if (assocMac?.toString().toLowerCase() == mac.toLowerCase()) {
            return {
              'downlinkRate': values[
                  'Device.WiFi.AccessPoint.$i.AssociatedDevice.$j.LastDataDownlinkRate'],
              'signalStrength': values[
                  'Device.WiFi.AccessPoint.$i.AssociatedDevice.$j.SignalStrength'],
              'apIndex': i,
              'bssid': values[
                  'Device.WiFi.AccessPoint.$i.SSIDReference'], // Usually mapped via SSIDRef -> SSID -> Radio
            };
          }
        }
      }
      return null;
    }

    for (int i = 1; i <= hostCount; i++) {
      final mac = values['Device.Hosts.Host.$i.PhysAddress']?.toString() ?? '';
      final ip = values['Device.Hosts.Host.$i.IPAddress']?.toString() ?? '';
      final interfaceType =
          values['Device.Hosts.Host.$i.InterfaceType']?.toString() ?? '';

      // Skip invalid entries
      if (mac.isEmpty) continue;

      final connection = <String, dynamic>{
        'macAddress': mac,
        'ipAddress': ip,
      };

      if (interfaceType == '802.11' || interfaceType == 'Wireless') {
        final wirelessInfo = findWirelessInfo(mac);
        if (wirelessInfo != null) {
          // Found detailed stats
          final rateKbps =
              int.tryParse(wirelessInfo['downlinkRate']?.toString() ?? '0') ??
                  0;
          connection['negotiatedMbps'] =
              (rateKbps / 1000).round(); // Kbps to Mbps

          final apIndex = wirelessInfo['apIndex'];
          // Determine Band from Radio (Simplified: AP 1=2.4G, 2=5G, 3=6G based on mock)
          // Real lookup: AP -> SSID -> LowerLayers (Radio) -> OperatingFrequencyBand
          // We'll use a heuristic based on AP Index matching typical mock setup
          String band = '5GHz';
          if (apIndex == 1) band = '2.4GHz';
          if (apIndex == 3) band = '6GHz';

          connection['wireless'] = {
            'signalDecibels': int.tryParse(
                    wirelessInfo['signalStrength']?.toString() ?? '-50') ??
                -50,
            'band': band,
            'bssid': values['Device.WiFi.SSID.$apIndex.MACAddress'] ??
                '00:00:00:00:00:A$apIndex', // Use SSID MAC as BSSID
            'isGuest': apIndex == 4, // Guest AP is usually index 4 in mock
            'radioID': 'RADIO_$band',
            'txRate': rateKbps,
            'rxRate': rateKbps,
            'isMLOCapable': false,
          };
        } else {
          // Wireless host but no active association found (offline?)
          // Provide basic minimal data
          connection['negotiatedMbps'] = 0;
          connection['wireless'] = {
            'signalDecibels': -99,
            'band': '2.4GHz', // Default
            'isGuest': false
          };
        }
      } else {
        // Wired
        connection['negotiatedMbps'] = 1000; // Assume Gigabit for wired
      }
      connections.add(connection);
    }

    return {
      'connections': connections,
    };
  }

  /// Maps Device.WiFi.AccessPoint.{i}.AssociatedDevice.* to JNAP GetNodesWirelessNetworkConnections2.
  /// Aggregates all local clients under the Master Node ID.
  Map<String, dynamic> _mapNodesWirelessNetworkConnections2(
      UspGetResponse response) {
    final values = _flattenResults(response);
    final nodeWirelessConnections = <Map<String, dynamic>>[];

    // 1. Find Master Node ID (BackhaulLinkType == None)
    String masterNodeId = '';
    final apDeviceCount = int.tryParse(
            values['Device.WiFi.MultiAP.APDeviceNumberOfEntries']?.toString() ??
                '0') ??
        0;

    for (int i = 1; i <= apDeviceCount; i++) {
      final backhaulType =
          values['Device.WiFi.MultiAP.APDevice.$i.BackhaulLinkType']
              ?.toString();
      if (backhaulType == 'None') {
        masterNodeId =
            values['Device.WiFi.MultiAP.APDevice.$i.MACAddress']?.toString() ??
                '';
        break;
      }
    }

    if (masterNodeId.isEmpty) {
      // Fallback if no master found in MultiAP table
      masterNodeId = '00:00:00:00:00:00';
    }

    // 2. Aggregate all local Associated Devices
    final connections = <Map<String, dynamic>>[];
    final apCount = int.tryParse(
            values['Device.WiFi.AccessPointNumberOfEntries']?.toString() ??
                '4') ??
        4;

    for (int i = 1; i <= apCount; i++) {
      final assocCount = int.tryParse(
              values['Device.WiFi.AccessPoint.$i.AssociatedDeviceNumberOfEntries']
                      ?.toString() ??
                  '0') ??
          0;

      for (int j = 1; j <= assocCount; j++) {
        final mac =
            values['Device.WiFi.AccessPoint.$i.AssociatedDevice.$j.MACAddress'];
        if (mac != null) {
          final rateKbps = int.tryParse(
                  values['Device.WiFi.AccessPoint.$i.AssociatedDevice.$j.LastDataDownlinkRate']
                          ?.toString() ??
                      '0') ??
              0;
          final signal = int.tryParse(
                  values['Device.WiFi.AccessPoint.$i.AssociatedDevice.$j.SignalStrength']
                          ?.toString() ??
                      '-50') ??
              -50;

          // Determine Band from AP Index (Heuristic)
          String band = '5GHz';
          if (i == 1) band = '2.4GHz';
          if (i == 3) band = '6GHz';

          connections.add({
            'macAddress': mac,
            'negotiatedMbps': (rateKbps / 1000).round(),
            'timestamp': DateTime.now().toIso8601String(), // Mock timestamp
            'wireless': {
              'bssid': values['Device.WiFi.SSID.$i.MACAddress'] ??
                  '00:00:00:00:00:00', // Use SSID MAC as BSSID
              'isGuest': i == 4,
              'radioID': 'RADIO_$band',
              'band': band,
              'signalDecibels': signal,
              'txRate': rateKbps, // Raw value
              'rxRate': rateKbps, // Mock as symmetric
              'isMLOCapable': false,
            }
          });
        }
      }
    }

    // 3. Construct response structure
    if (connections.isNotEmpty) {
      nodeWirelessConnections.add({
        'deviceID': masterNodeId,
        'connections': connections,
      });
    }

    final result = {
      'nodeWirelessConnections': nodeWirelessConnections,
    };
    logger.d('🚀 _mapNodesWirelessNetworkConnections2 result: $result');
    return result;
  }

  /// Generic mapper for unmapped actions.
  Map<String, dynamic> _mapGeneric(UspGetResponse response) {
    return _flattenResults(response);
  }

  /// Flattens USP results into a simple key-value map.
  Map<String, dynamic> _flattenResults(UspGetResponse response) {
    final result = <String, dynamic>{};

    for (final entry in response.results.entries) {
      result[entry.key.fullPath] = entry.value.value;
    }

    return result;
  }
}
