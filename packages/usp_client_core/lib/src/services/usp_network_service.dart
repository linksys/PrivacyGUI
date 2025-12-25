/// USP Network Service
///
/// Provides network settings (WAN/LAN/Time) via USP/TR-181 protocol.
library;

import '../enums/_enums.dart';
import '../tr181_paths.dart';
import '../connection/usp_grpc_client_service.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

/// Service for retrieving network settings via USP.
///
/// This service handles WAN status, LAN settings, and time configuration.
class UspNetworkService {
  final UspGrpcClientService _grpcService;

  /// Creates a new [UspNetworkService].
  UspNetworkService(this._grpcService);

  /// Retrieves WAN status.
  ///
  /// Returns a map containing macAddress, detectedWANType, wanStatus,
  /// wanConnection, supportedWANTypes, etc.
  Future<Map<String, dynamic>> getWANStatus() async {
    final paths =
        Tr181Paths.wanStatusPaths.map((p) => UspPath.parse(p)).toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapWANStatus(response);
  }

  /// Retrieves LAN settings.
  ///
  /// Returns a map containing hostName, ipAddress, subnetMask, dhcpSettings, etc.
  Future<Map<String, dynamic>> getLANSettings() async {
    final paths =
        Tr181Paths.lanSettingsPaths.map((p) => UspPath.parse(p)).toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapLANSettings(response);
  }

  /// Retrieves time settings.
  ///
  /// Returns a map containing timeZone, autoAdjustForDST, currentLocalTime.
  Future<Map<String, dynamic>> getTimeSettings() async {
    final paths =
        Tr181Paths.timeSettingsPaths.map((p) => UspPath.parse(p)).toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapTimeSettings(response);
  }

  // ===========================================================================
  // Private Mapping Methods
  // ===========================================================================

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
    final wanType = addressingType == 'Static' ? WanType.static_ : WanType.dhcp;

    // Determine WAN status from interface status
    final ifStatus = values['Device.IP.Interface.1.Status']?.toString() ?? 'Up';
    final wanStatus =
        ifStatus == 'Up' ? WanStatus.connected : WanStatus.disconnected;

    return {
      'macAddress': macAddress,
      'detectedWANType': wanType.value,
      'wanStatus': wanStatus.value,
      'wanIPv6Status': WanStatus.disconnected.value, // Simplified for demo
      'isDetectingWANType': false,
      'wanConnection': {
        'wanType': wanType.value,
        'ipAddress': ipAddress,
        'networkPrefixLength': _subnetMaskToPrefix(subnetMask),
        'gateway': gateway,
        'mtu': 1500,
        'dhcpLeaseMinutes': wanType == WanType.dhcp ? 4320 : null,
        'dnsServer1': gateway.isNotEmpty ? gateway : '8.8.8.8',
      },
      // Use enum values for supported types
      'supportedWANTypes': WanType.values.map((e) => e.value).toList(),
      'supportedIPv6WANTypes': ['Automatic', 'PPPoE', 'Pass-through'],
      'supportedWANCombinations': [
        {'wanType': WanType.dhcp.value, 'wanIPv6Type': 'Automatic'},
        {'wanType': WanType.static_.value, 'wanIPv6Type': 'Automatic'},
        {'wanType': WanType.pppoe.value, 'wanIPv6Type': 'Automatic'},
      ],
    };
  }

  Map<String, dynamic> _mapLANSettings(UspGetResponse response) {
    final values = _flattenResults(response);

    final lanIp =
        values['Device.IP.Interface.2.IPv4Address.1.IPAddress']?.toString() ??
            '192.168.1.1';
    final subnetMask =
        values['Device.IP.Interface.2.IPv4Address.1.SubnetMask']?.toString() ??
            '255.255.255.0';

    return {
      'hostName': 'LinksysRouter',
      'ipAddress': lanIp,
      'networkPrefixLength': _subnetMaskToPrefix(subnetMask),
      'isDHCPEnabled':
          values['Device.DHCPv4.Server.Pool.1.Enable']?.toString() == 'true',
      'dhcpSettings': {
        'firstClientIPAddress':
            values['Device.DHCPv4.Server.Pool.1.MinAddress']?.toString() ??
                '192.168.1.100',
        'lastClientIPAddress':
            values['Device.DHCPv4.Server.Pool.1.MaxAddress']?.toString() ??
                '192.168.1.149',
        'leaseMinutes': int.tryParse(
                values['Device.DHCPv4.Server.Pool.1.LeaseTime']?.toString() ??
                    '1440') ??
            1440,
      },
      'minNetworkPrefixLength': 8,
      'maxNetworkPrefixLength': 30,
      'minAllowedDHCPLeaseMinutes': 60,
      'maxAllowedDHCPLeaseMinutes': 2880,
    };
  }

  Map<String, dynamic> _mapTimeSettings(UspGetResponse response) {
    final values = _flattenResults(response);

    return {
      'timeZone': values['Device.Time.LocalTimeZone']?.toString() ?? 'UTC',
      'autoAdjustForDST': true, // TR-181 doesn't have direct mapping
      'currentLocalTime':
          values['Device.Time.CurrentLocalTime']?.toString() ?? '',
    };
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
}
