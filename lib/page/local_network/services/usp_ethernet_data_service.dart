import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspEthernetDataServiceProvider = Provider<UspEthernetDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspEthernetDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Fetch result
// ---------------------------------------------------------------------------

/// Result of an Ethernet data fetch.
class EthernetDataFetchResult {
  final List<EthernetPortUIModel> portModels;

  const EthernetDataFetchResult({required this.portModels});
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching Ethernet interface data.
///
/// Owns codegen calls, bridge port map query, and port UI model building
/// for [ethernetDataProvider].
class UspEthernetDataService {
  final UspClient _usp;

  UspEthernetDataService(this._usp);

  /// Fetches Ethernet interfaces + bridge port map, builds port UI models.
  Future<EthernetDataFetchResult> fetch({
    required List<ClientDevice> deviceModels,
  }) async {
    final List<Object> results;
    try {
      results = await Future.wait([
        EthernetInterfaces.fetch(_usp),
        _fetchBridgePortMap(),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final ethernetInterfaces = results[0] as EthernetInterfaces;
    final bridgePortMap = results[1] as Map<String, String>;

    final portModels = _buildEthernetPortUIModels(
      ethernetInterfaces: ethernetInterfaces,
      deviceModels: deviceModels,
      bridgePortMap: bridgePortMap,
    );

    return EthernetDataFetchResult(portModels: portModels);
  }

  // ---------------------------------------------------------------------------
  // Bridge port → Ethernet interface mapping
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _fetchBridgePortMap() async {
    try {
      final resp = await _usp.get([
        'Device.Bridging.Bridge.*.Port.*.LowerLayers',
      ]).timeout(const Duration(seconds: 20));
      final map = <String, String>{};
      for (final entry in resp.entries) {
        if (!entry.key.endsWith('.LowerLayers')) continue;
        final lowerLayers = entry.value?.toString() ?? '';
        if (lowerLayers.isEmpty) continue;
        final bridgePortPath = entry.key.substring(
          0,
          entry.key.length - 'LowerLayers'.length,
        );
        for (final layer in lowerLayers.split(',')) {
          final trimmed = layer.trim();
          if (trimmed.startsWith('Device.Ethernet.Interface.')) {
            final normalized = trimmed.endsWith('.') ? trimmed : '$trimmed.';
            map[bridgePortPath] = normalized;
            break;
          }
        }
      }
      return map;
    } catch (e) {
      logger.w('[USP][Ethernet]: Bridge port map fetch failed: $e');
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // Ethernet Port UI Models
  // ---------------------------------------------------------------------------

  /// Builds UI models for ethernet ports.
  ///
  /// Uses [bridgePortMap] to classify WAN vs LAN — the `Upstream` flag on
  /// `EthernetInterface` is unreliable (M60TB reports it inverted).
  /// An Ethernet Interface referenced by any bridge port is a LAN interface;
  /// one not referenced by any bridge is WAN.
  ///
  /// TR-181 aggregates physical switch ports into a single Ethernet Interface
  /// (e.g. 3 LAN ports → 1 eth1). Since per-port data isn't available, each
  /// active wired device is shown as its own LAN port entry.
  List<EthernetPortUIModel> _buildEthernetPortUIModels({
    required EthernetInterfaces ethernetInterfaces,
    required List<ClientDevice> deviceModels,
    Map<String, String> bridgePortMap = const {},
  }) {
    final result = <EthernetPortUIModel>[];

    final bridgeMemberPaths =
        bridgePortMap.values.map(_ensureTrailingDot).toSet();

    EthernetInterface? lanAggregate;
    for (final iface in ethernetInterfaces.items) {
      final path = _ensureTrailingDot(iface.instancePath);
      if (bridgeMemberPaths.contains(path)) {
        lanAggregate ??= iface;
      } else {
        final isUp = iface.status.toLowerCase() == 'up';
        result.add(EthernetPortUIModel(
          name: iface.name,
          label: 'WAN',
          isWan: true,
          isUp: isUp,
          instancePath: iface.instancePath,
          currentBitRate: iface.currentBitRate,
        ));
      }
    }

    if (lanAggregate != null) {
      // Collect wired connections from client devices.
      // A device may have multiple interfaces (WiFi + Ethernet); check both
      // the primary interface and additionalInterfaces for Ethernet.
      final wiredConnections =
          <({String displayName, String mac, String ip})>[];
      for (final d in deviceModels) {
        // Check primary interface
        if (d.isActive && !d.isWifi) {
          wiredConnections.add((
            displayName: d.displayName,
            mac: d.mac,
            ip: d.ip,
          ));
        }
        // Check additional interfaces for Ethernet connections
        for (final iface in d.additionalInterfaces) {
          if (iface.isActive && !iface.isWifi) {
            wiredConnections.add((
              displayName: d.displayName,
              mac: iface.mac,
              ip: iface.ip,
            ));
          }
        }
      }

      final lanBitRate = lanAggregate.currentBitRate;

      if (wiredConnections.isEmpty) {
        // No wired devices → show single LAN port as disconnected.
        // Note: lanAggregate.status reflects switch-chip link state, not
        // whether a device is plugged in, so we use isUp=false here.
        result.add(EthernetPortUIModel(
          name: lanAggregate.name,
          label: 'LAN',
          isWan: false,
          isUp: false,
          instancePath: lanAggregate.instancePath,
          currentBitRate: lanBitRate,
        ));
      } else {
        for (var i = 0; i < wiredConnections.length; i++) {
          final conn = wiredConnections[i];
          result.add(EthernetPortUIModel(
            name: lanAggregate.name,
            label: 'LAN ${i + 1}',
            isWan: false,
            isUp: true,
            instancePath: lanAggregate.instancePath,
            currentBitRate: lanBitRate,
            connectedDevices: [
              WiredDeviceInfo(
                hostName: conn.displayName,
                macAddress: conn.mac,
                ipAddress: conn.ip,
              ),
            ],
          ));
        }
      }
    }

    return result;
  }

  static String _ensureTrailingDot(String path) {
    if (path.isEmpty) return path;
    return path.endsWith('.') ? path : '$path.';
  }
}
