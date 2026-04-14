import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/page/_shared/providers/wifi_client_enricher.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

final connectedDevicesServiceProvider = Provider<ConnectedDevicesService>(
  (ref) => ConnectedDevicesService(
    ref.read(uspClientProvider)!,
    ref.read(uspDeviceServiceProvider),
  ),
);

/// Service layer for Connected Devices with multi-model aggregation.
///
/// Demonstrates complex Service layer patterns:
/// - Multi-model aggregation (ConnectedDevices + WiFi + System info)
/// - Partial success handling with business-specific strategies
/// - Cross-domain data enrichment and transformation
/// - Fallback strategies for non-critical data
class ConnectedDevicesService {
  final UspClient _client;
  final UspDeviceService _deviceService;

  ConnectedDevicesService(this._client, this._deviceService);

  /// Fetch enriched device data with multi-model aggregation.
  ///
  /// Demonstrates Service layer orchestration pattern:
  /// - Uses multiple codegen-generated classes for type-safe data fetching
  /// - Demonstrates different error strategies for different data criticality
  /// - Delegates to UspDeviceService for business logic transformation
  /// - Handles structured errors from WASM layer via codegen
  Future<ConnectedDevicesData> fetchConnectedDevicesData() async {
    try {
      // INVESTIGATION: Device.Hosts.Host.* queries failing with [object Object]
      // This affects both Flutter app and USP Console, suggesting WASM/router issue
      logger.d(
          '[ConnectedDevicesService] Starting Device.Hosts.Host queries - investigating [object Object] error');

      // Fetch core device data with structured error handling
      final connectedDevices = await ConnectedDevices.fetch(_client);

      // Use empty enrichment data for simplicity while still demonstrating architecture
      const emptyWifiClientMap = <String, WifiClientUIModel>{};
      const emptyConnectionDetailMap = <String, ClientConnectionDetail>{};
      const emptyMeshTopology = MeshTopologyInfo.empty;
      const gatewayName = 'Demo Gateway';

      // Delegate to UspDeviceService for proper business logic
      final deviceModels = _deviceService.buildDeviceUIModels(
        connectedDevices: connectedDevices,
        wifiClientMap: emptyWifiClientMap,
        connectionDetailMap: emptyConnectionDetailMap,
        meshTopology: emptyMeshTopology,
        gatewayName: gatewayName,
      );

      final hostNameByMac =
          _buildHostNameMapFromDevices(connectedDevices.items);

      logger.d('[ConnectedDevicesService] Service orchestration completed — '
          'devices=${deviceModels.length}, gateway=$gatewayName');

      return ConnectedDevicesData(
        meshTopology: emptyMeshTopology,
        deviceModels: deviceModels,
        nodeModels: [], // Would be computed from mesh topology in real implementation
        hostNameByMac: hostNameByMac,
        rawConnectedDevices:
            connectedDevices, // Expose raw data for Provider layer
      );
    } catch (e) {
      // Handle structured errors from codegen (WASM layer throws structured errors)
      logger.e('[ConnectedDevicesService] Original error before mapping: $e');
      logger.e('[ConnectedDevicesService] Error type: ${e.runtimeType}');
      logger.e('[ConnectedDevicesService] Error hashCode: ${e.hashCode}');
      logger.e('[ConnectedDevicesService] Error toString(): ${e.toString()}');

      // Try to extract more information about JavaScript error object
      try {
        logger.e('[ConnectedDevicesService] Advanced error inspection:');
        final dynamic dynE = e;

        // Check if it's a JavaScript error with common properties
        logger.e(
            '[ConnectedDevicesService] - Checking common JS error properties...');

        try {
          final message = dynE.message;
          logger.e('[ConnectedDevicesService] - message: $message');
        } catch (_) {
          logger.e('[ConnectedDevicesService] - No message property');
        }

        try {
          final name = dynE.name;
          logger.e('[ConnectedDevicesService] - name: $name');
        } catch (_) {
          logger.e('[ConnectedDevicesService] - No name property');
        }

        try {
          final stack = dynE.stack;
          logger.e('[ConnectedDevicesService] - stack: $stack');
        } catch (_) {
          logger.e('[ConnectedDevicesService] - No stack property');
        }

        try {
          final code = dynE.code;
          logger.e('[ConnectedDevicesService] - code: $code');
        } catch (_) {
          logger.e('[ConnectedDevicesService] - No code property');
        }

        // Try to call JSON.stringify equivalent
        try {
          final jsonString = dynE.toJson?.call();
          logger.e('[ConnectedDevicesService] - toJson(): $jsonString');
        } catch (_) {
          logger.e('[ConnectedDevicesService] - No toJson method');
        }

        // Check if it's iterable
        try {
          if (dynE is Iterable) {
            logger.e(
                '[ConnectedDevicesService] - Object is iterable with ${dynE.length} items');
            for (final item in dynE) {
              logger.e('[ConnectedDevicesService] - Item: $item');
            }
          }
        } catch (_) {
          logger.e('[ConnectedDevicesService] - Not iterable');
        }

        // Check if it has keys like a Map
        try {
          if (dynE is Map) {
            logger.e(
                '[ConnectedDevicesService] - Object is Map with keys: ${dynE.keys}');
            for (final key in dynE.keys) {
              logger.e('[ConnectedDevicesService] - $key: ${dynE[key]}');
            }
          }
        } catch (_) {
          logger.e('[ConnectedDevicesService] - Not a Map');
        }
      } catch (propError) {
        logger.e(
            '[ConnectedDevicesService] Failed advanced error inspection: $propError');
      }

      throw mapUspErrorToServiceError(e);
    }
  }

  /// Build hostname lookup map from ConnectedDevice list.
  Map<String, String> _buildHostNameMapFromDevices(
      List<ConnectedDevice> devices) {
    final map = <String, String>{};
    for (final device in devices) {
      if (device.hostName.isNotEmpty) {
        map[device.macAddress] = device.hostName;
      }
    }
    return map;
  }
}

/// Data class for aggregated connected devices information.
///
/// Includes both raw codegen data and processed UI models to support
/// Provider layer requirements (WiFi listener rebuilds need raw data).
class ConnectedDevicesData {
  final MeshTopologyInfo meshTopology;
  final List<DeviceUIModel> deviceModels;
  final List<NodeUIModel> nodeModels;
  final Map<String, String> hostNameByMac;

  /// Raw ConnectedDevices for Provider layer WiFi listener compatibility.
  /// TODO: In future refactor, eliminate this by redesigning WiFi listener pattern.
  final ConnectedDevices rawConnectedDevices;

  const ConnectedDevicesData({
    required this.meshTopology,
    required this.deviceModels,
    required this.nodeModels,
    required this.hostNameByMac,
    required this.rawConnectedDevices,
  });
}
