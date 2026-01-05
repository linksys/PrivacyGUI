/// USP Diagnostics Service
///
/// Provides diagnostics information via USP/TR-181 protocol.
library;

import '../enums/_enums.dart';
import '../tr181_paths.dart';
import '../connection/usp_grpc_client_service.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

/// Service for retrieving diagnostics information via USP.
///
/// This service handles network connectivity status and port connections.
class UspDiagnosticsService {
  final UspGrpcClientService _grpcService;

  /// Creates a new [UspDiagnosticsService].
  UspDiagnosticsService(this._grpcService);

  /// Retrieves internet connection status.
  ///
  /// Returns a map containing connectionStatus (InternetConnected/Disconnected).
  Future<Map<String, dynamic>> getInternetConnectionStatus() async {
    final paths = Tr181Paths.internetConnectionStatusPaths
        .map((p) => UspPath.parse(p))
        .toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapInternetConnectionStatus(response);
  }

  /// Retrieves ethernet port connection status.
  ///
  /// Returns a map containing wanPortConnection and lanPortConnections list.
  Future<Map<String, dynamic>> getEthernetPortConnections() async {
    final paths = Tr181Paths.ethernetPortConnectionsPaths
        .map((p) => UspPath.parse(p))
        .toList();

    final response = await _grpcService.sendRequest(UspGetRequest(paths));

    if (response is! UspGetResponse) {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }

    return _mapEthernetPortConnections(response);
  }

  // ===========================================================================
  // Private Mapping Methods
  // ===========================================================================

  Map<String, dynamic> _mapInternetConnectionStatus(UspGetResponse response) {
    final values = _flattenResults(response);
    final status = values['Device.IP.Interface.1.Status']?.toString() ?? 'Down';

    final connectionStatus = (status == 'Up')
        ? InternetConnectionStatus.connected
        : InternetConnectionStatus.disconnected;

    return {
      'connectionStatus': connectionStatus.value,
    };
  }

  Map<String, dynamic> _mapEthernetPortConnections(UspGetResponse response) {
    final values = _flattenResults(response);

    // WAN -> Device.Ethernet.Interface.1
    final wanEnable =
        values['Device.Ethernet.Interface.1.Enable']?.toString() == 'true';
    final wanBitRate = int.tryParse(
            values['Device.Ethernet.Interface.1.MaxBitRate']?.toString() ??
                '0') ??
        0;

    final wanSpeed = wanEnable
        ? EthernetSpeed.fromBitRate(wanBitRate)
        : EthernetSpeed.disconnected;

    // LAN Ports (Interfaces 3+ in mock data)
    final lanList = <String>[];
    final interfaceCount = int.tryParse(
            values['Device.Ethernet.InterfaceNumberOfEntries']?.toString() ??
                '6') ??
        6;

    // LAN ports usually start at index 3 (1=WAN, 2=Bridge)
    for (int i = 3; i <= interfaceCount; i++) {
      final enableKey = 'Device.Ethernet.Interface.$i.Enable';
      if (!values.containsKey(enableKey)) {
        continue;
      }

      final enable = values[enableKey]?.toString() == 'true';
      final bitRate = int.tryParse(
              values['Device.Ethernet.Interface.$i.MaxBitRate']?.toString() ??
                  '0') ??
          0;

      final portSpeed = enable
          ? EthernetSpeed.fromBitRate(bitRate)
          : EthernetSpeed.disconnected;

      lanList.add(portSpeed.value);
    }

    return {
      'wanPortConnection': wanSpeed.value,
      'lanPortConnections': lanList,
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
}
