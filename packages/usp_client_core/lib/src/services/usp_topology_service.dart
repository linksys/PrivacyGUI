/// USP Topology Service
///
/// Provides device topology and connection information via USP/TR-181 protocol.
library;

import '../tr181_paths.dart';
import '../connection/usp_grpc_client_service.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

/// Service for retrieving device topology via USP.
///
/// This service handles connected devices, mesh nodes, backhaul info,
/// and network connections.
class UspTopologyService {
  final UspGrpcClientService _grpcService;

  /// Creates a new [UspTopologyService].
  UspTopologyService(this._grpcService);

  /// Retrieves all connected devices.
  ///
  /// Returns a map containing devices list (clients + mesh nodes).
  Future<Map<String, dynamic>> getDevices() async {
    final paths = Tr181Paths.devicesPaths.map((p) => UspPath.parse(p)).toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapDevices(response);
  }

  /// Retrieves backhaul information for mesh nodes.
  ///
  /// Returns a map containing backhaulDevices list.
  Future<Map<String, dynamic>> getBackhaulInfo() async {
    final paths =
        Tr181Paths.backhaulInfoPaths.map((p) => UspPath.parse(p)).toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapBackhaulInfo(response);
  }

  /// Retrieves network connections for all hosts.
  ///
  /// Returns a map containing connections list with wireless/wired info.
  Future<Map<String, dynamic>> getNetworkConnections() async {
    final paths = Tr181Paths.networkConnectionsPaths
        .map((p) => UspPath.parse(p))
        .toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapNetworkConnections(response);
  }

  /// Retrieves nodes wireless network connections.
  ///
  /// Returns a map containing nodeWirelessConnections for mesh topology.
  Future<Map<String, dynamic>> getNodesWirelessNetworkConnections() async {
    final paths = Tr181Paths.nodesWirelessConnectionsPaths
        .map((p) => UspPath.parse(p))
        .toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapNodesWirelessNetworkConnections(response);
  }

  // ===========================================================================
  // Private Mapping Methods
  // ===========================================================================

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
            'ipAddress': '', // Nodes might have IP but not exposed easily
            'isOnline': 'true', // Mesh nodes derived from APDevice are active
            'interfaceType': 'Infrastructure',
            'parentDeviceID': isMaster ? null : parentMac,
          }
        ],
      });
    }

    return {'devices': devices};
  }

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

      // Mock IPs for demonstration
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

  Map<String, dynamic> _mapNetworkConnections(UspGetResponse response) {
    final values = _flattenResults(response);
    final connections = <Map<String, dynamic>>[];

    final hostCount = int.tryParse(
            values['Device.Hosts.HostNumberOfEntries']?.toString() ?? '0') ??
        0;

    // Helper to find Associated Device for a MAC
    Map<String, dynamic>? findWirelessInfo(String mac) {
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

      if (mac.isEmpty) continue;

      final connection = <String, dynamic>{
        'macAddress': mac,
        'ipAddress': ip,
      };

      if (interfaceType == '802.11' || interfaceType == 'Wireless') {
        final wirelessInfo = findWirelessInfo(mac);
        if (wirelessInfo != null) {
          final rateKbps =
              int.tryParse(wirelessInfo['downlinkRate']?.toString() ?? '0') ??
                  0;
          connection['negotiatedMbps'] = (rateKbps / 1000).round();

          final apIndex = wirelessInfo['apIndex'];
          String band = '5GHz';
          if (apIndex == 1) band = '2.4GHz';
          if (apIndex == 3) band = '6GHz';

          connection['wireless'] = {
            'signalDecibels': int.tryParse(
                    wirelessInfo['signalStrength']?.toString() ?? '-50') ??
                -50,
            'band': band,
            'bssid': values['Device.WiFi.SSID.$apIndex.MACAddress'] ??
                '00:00:00:00:00:A$apIndex',
            'isGuest': apIndex == 4,
            'radioID': 'RADIO_$band',
            'txRate': rateKbps,
            'rxRate': rateKbps,
            'isMLOCapable': false,
          };
        } else {
          connection['negotiatedMbps'] = 0;
          connection['wireless'] = {
            'signalDecibels': -99,
            'band': '2.4GHz',
            'isGuest': false
          };
        }
      } else {
        connection['negotiatedMbps'] = 1000; // Assume Gigabit for wired
      }
      connections.add(connection);
    }

    return {'connections': connections};
  }

  Map<String, dynamic> _mapNodesWirelessNetworkConnections(
      UspGetResponse response) {
    final values = _flattenResults(response);
    final nodeWirelessConnections = <Map<String, dynamic>>[];

    // 1. Find Master Node ID
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

          String band = '5GHz';
          if (i == 1) band = '2.4GHz';
          if (i == 3) band = '6GHz';

          connections.add({
            'macAddress': mac,
            'negotiatedMbps': (rateKbps / 1000).round(),
            'timestamp': DateTime.now().toIso8601String(),
            'wireless': {
              'bssid': values['Device.WiFi.SSID.$i.MACAddress'] ??
                  '00:00:00:00:00:00',
              'isGuest': i == 4,
              'radioID': 'RADIO_$band',
              'band': band,
              'signalDecibels': signal,
              'txRate': rateKbps,
              'rxRate': rateKbps,
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

    return {'nodeWirelessConnections': nodeWirelessConnections};
  }

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  Map<String, dynamic> _flattenResults(UspGetResponse response) {
    final result = <String, dynamic>{};
    for (final entry in response.results.entries) {
      result[entry.key.fullPath] = entry.value.value;
    }
    return result;
  }
}
