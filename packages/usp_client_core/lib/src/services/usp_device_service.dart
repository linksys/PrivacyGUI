/// USP Device Service
///
/// Provides device information via USP/TR-181 protocol.
library;

import 'package:usp_protocol_common/usp_protocol_common.dart';
import '../tr181_paths.dart';
import '../connection/usp_grpc_client_service.dart';

/// Service for retrieving device information via USP.
///
/// This service communicates with the USP Agent to retrieve
/// TR-181 Device.DeviceInfo.* data.
class UspDeviceService {
  final UspGrpcClientService _grpcService;

  /// Creates a new [UspDeviceService].
  UspDeviceService(this._grpcService);

  /// Retrieves device information as a Map.
  ///
  /// Returns a map containing manufacturer, modelNumber, serialNumber,
  /// firmwareVersion, etc. in JNAP-compatible format.
  Future<Map<String, dynamic>> getDeviceInfo() async {
    final paths =
        Tr181Paths.deviceInfoPaths.map((p) => UspPath.parse(p)).toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapDeviceInfo(response);
  }

  /// Retrieves system statistics.
  ///
  /// Returns a map containing uptimeSeconds, CPULoad, MemoryLoad.
  Future<Map<String, dynamic>> getSystemStats() async {
    final paths =
        Tr181Paths.systemStatsPaths.map((p) => UspPath.parse(p)).toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapSystemStats(response);
  }

  // ===========================================================================
  // Private Mapping Methods
  // ===========================================================================

  /// Maps USP response to device info map.
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
      'firmwareDate': '', // TR-181 doesn't have this field
      'description': values['Device.DeviceInfo.Description']?.toString() ?? '',
      'services': _supportedServices,
    };
  }

  /// Maps USP response to system stats map.
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

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  /// Flattens USP results into a simple key-value map.
  Map<String, dynamic> _flattenResults(UspGetResponse response) {
    final result = <String, dynamic>{};
    for (final entry in response.results.entries) {
      result[entry.key.fullPath] = entry.value.value;
    }
    return result;
  }

  /// List of JNAP services supported.
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
}
