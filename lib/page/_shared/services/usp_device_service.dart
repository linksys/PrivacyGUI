import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/wifi_client_enricher.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

/// Service provider — stateless, per Article VI.
final uspDeviceServiceProvider = Provider<UspDeviceService>(
  (ref) => UspDeviceService(),
);

/// Transforms raw codegen Data Models into Presentation Layer UI Models.
///
/// All Data → UI conversion is consolidated here so that UI widgets never
/// import codegen types directly (constitution Section 5.3).
class UspDeviceService {
  // ---------------------------------------------------------------------------
  // ConnectedDevices
  // ---------------------------------------------------------------------------

  List<DeviceUIModel> buildDeviceUIModels({
    required ConnectedDevices connectedDevices,
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required MeshTopologyInfo meshTopology,
    required String gatewayName,
  }) {
    return connectedDevices.items
        .where((d) => d.interface_.isNotEmpty)
        .map((d) => _toDeviceUIModel(
            d, wifiClientMap, connectionDetailMap, meshTopology, gatewayName))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // DHCP Clients (active leases)
  // ---------------------------------------------------------------------------

  List<DhcpClientUIModel> buildDhcpClientUIModels({
    required DhcpClients clients,
    required ConnectedDevices connectedDevices,
  }) {
    // Build MAC → hostname lookup from connected devices
    final hostNameByMac = <String, String>{};
    for (final d in connectedDevices.items) {
      if (d.hostName.isNotEmpty) {
        hostNameByMac[d.macAddress.trim().toUpperCase()] = d.hostName;
      }
    }

    return clients.items
        .map((c) => DhcpClientUIModel(
              mac: c.chaddr,
              ip: c.ipAddress,
              active: c.active,
              hostName: hostNameByMac[c.chaddr.trim().toUpperCase()] ?? '',
              leaseExpiry: c.leaseTimeRemaining,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // DHCP Reservations
  // ---------------------------------------------------------------------------

  List<DhcpReservationUIModel> buildDhcpReservationUIModels(
      DhcpReservations reservations) {
    return reservations.items
        .map((r) => DhcpReservationUIModel(
              instancePath: r.instancePath,
              mac: r.chaddr,
              ip: r.yiaddr,
              enable: r.enable,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Port Forwarding
  // ---------------------------------------------------------------------------

  List<PortForwardingRuleUIModel> buildPortForwardingRuleUIModels(
      PortForwarding portForwarding) {
    return portForwarding.items
        .map((r) => PortForwardingRuleUIModel(
              instancePath: r.instancePath,
              description: r.description,
              externalPort: r.externalPort,
              externalPortEndRange: r.externalPortEndRange,
              internalPort: r.internalPort,
              internalClient: r.internalClient,
              protocol: r.protocol,
              enabled: r.enabled,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Port Triggering
  // ---------------------------------------------------------------------------

  List<PortTriggeringRuleUIModel> buildPortTriggeringRuleUIModels(
      PortTriggering portTriggering) {
    return portTriggering.items
        .map((t) => PortTriggeringRuleUIModel(
              instancePath: t.instancePath,
              enabled: t.enabled,
              description: t.description,
              triggerPort: t.triggerPort,
              triggerPortEndRange: t.triggerPortEndRange,
              triggerProtocol: t.triggerProtocol,
              forwardRules: t.rules
                  .map((r) => PortTriggerForwardRuleUIModel(
                        instancePath: r.instancePath,
                        forwardPort: r.forwardPort,
                        forwardPortEndRange: r.forwardPortEndRange,
                        forwardProtocol: r.forwardProtocol,
                      ))
                  .toList(),
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // LAN Info
  // ---------------------------------------------------------------------------

  LanInfoUIModel buildLanInfoUIModel(
    LanNetworkInfo info, {
    List<String> ipv6Addresses = const [],
  }) {
    return LanInfoUIModel(
      hostName: info.hostName,
      ipAddress: info.ipAddress,
      subnetMask: info.subnetMask,
      dhcpEnabled: info.dhcpEnabled,
      minAddress: info.minAddress,
      maxAddress: info.maxAddress,
      leaseTimeMinutes: (info.leaseTime / 60).round(),
      dnsServers: info.dnsServers,
      ipv6Enabled: info.ipv6Enabled,
      ipv6Addresses: ipv6Addresses,
    );
  }

  // ---------------------------------------------------------------------------
  // WAN Status
  // ---------------------------------------------------------------------------

  WanStatusUIModel buildWanStatusUIModel({
    required WanStatus wanStatus,
    required String gateway,
    List<String> ipv6Addresses = const [],
  }) {
    return WanStatusUIModel(
      isUp: wanStatus.status.toLowerCase() == 'up',
      ipAddress: wanStatus.ipAddress,
      subnetMask: wanStatus.subnetMask,
      addressingType: wanStatus.addressingType,
      mtu: wanStatus.maxMtuSize,
      gateway: gateway,
      ipv6Enabled: wanStatus.ipv6Enabled,
      ipv6Addresses: ipv6Addresses,
    );
  }

  // ---------------------------------------------------------------------------
  // Ethernet Ports
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
  List<EthernetPortUIModel> buildEthernetPortUIModels({
    required EthernetInterfaces ethernetInterfaces,
    required List<DeviceUIModel> deviceModels,
    Map<String, String> bridgePortMap = const {},
  }) {
    final result = <EthernetPortUIModel>[];

    // Collect all Ethernet Interface paths that are bridge members → LAN.
    final bridgeMemberPaths =
        bridgePortMap.values.map(_ensureTrailingDot).toSet();

    // Classify by bridge membership (reliable) instead of Upstream flag.
    EthernetInterface? lanAggregate;
    for (final iface in ethernetInterfaces.items) {
      final path = _ensureTrailingDot(iface.instancePath);
      if (bridgeMemberPaths.contains(path)) {
        lanAggregate ??= iface;
      } else {
        // WAN port
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

    // LAN port entries: one per active wired device, or a single entry
    // showing the physical interface when no wired devices are connected.
    if (lanAggregate != null) {
      final wiredDevices =
          deviceModels.where((d) => d.isActive && !d.isWifi).toList();
      final lanBitRate = lanAggregate.currentBitRate;
      final lanIsUp = lanAggregate.status.toLowerCase() == 'up';

      if (wiredDevices.isEmpty) {
        // No wired devices — still show the physical LAN port.
        result.add(EthernetPortUIModel(
          name: lanAggregate.name,
          label: 'LAN',
          isWan: false,
          isUp: lanIsUp,
          instancePath: lanAggregate.instancePath,
          currentBitRate: lanBitRate,
        ));
      } else {
        for (var i = 0; i < wiredDevices.length; i++) {
          final d = wiredDevices[i];
          result.add(EthernetPortUIModel(
            name: lanAggregate.name,
            label: 'LAN ${i + 1}',
            isWan: false,
            isUp: true,
            instancePath: lanAggregate.instancePath,
            currentBitRate: lanBitRate,
            connectedDevices: [
              WiredDeviceInfo(
                hostName: d.hostName,
                macAddress: d.mac,
                ipAddress: d.ip,
              ),
            ],
          ));
        }
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Mesh Nodes
  // ---------------------------------------------------------------------------

  List<NodeUIModel> buildNodeUIModels({
    required MeshTopologyInfo meshTopology,
    required List<DeviceUIModel> deviceModels,
    required SystemInfoUIModel systemInfo,
  }) {
    // Non-mesh / DataElements unsupported: create a synthetic gateway node
    // from SystemInfo so the node detail page has something to display.
    if (meshTopology.isEmpty) {
      return [
        NodeUIModel(
          deviceId: 'gateway',
          model: systemInfo.modelName,
          manufacturer: systemInfo.manufacturer,
          serialNumber: systemInfo.serialNumber,
          softwareVersion: systemInfo.softwareVersion,
          isMaster: true,
          connectedDeviceCount: deviceModels.where((d) => d.isActive).length,
        ),
      ];
    }

    return meshTopology.nodes.asMap().entries.map((entry) {
      final index = entry.key;
      final node = entry.value;
      final isMaster = index == 0;

      final connectedCount = deviceModels
          .where((d) =>
              d.isActive &&
              d.parentNodeId != null &&
              d.parentNodeId!.toUpperCase() == node.deviceId.toUpperCase())
          .length;

      return NodeUIModel(
        deviceId: node.deviceId,
        model: node.model,
        manufacturer: node.manufacturer,
        serialNumber: node.serialNumber,
        softwareVersion: node.softwareVersion,
        isMaster: isMaster,
        connectedDeviceCount: connectedCount,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  DeviceUIModel _toDeviceUIModel(
    ConnectedDevice device,
    Map<String, WifiClientUIModel> wifiClientMap,
    Map<String, ClientConnectionDetail> connectionDetailMap,
    MeshTopologyInfo meshTopology,
    String gatewayName,
  ) {
    final mac = device.macAddress.trim().toUpperCase();
    final isWifi = device.interface_.toLowerCase().contains('wifi');
    final wifiClient = wifiClientMap[mac];
    final detail = connectionDetailMap[mac];

    String? parentNodeId;
    String? parentNodeName;
    if (meshTopology.isEmpty) {
      if (device.isActive) parentNodeName = gatewayName;
    } else {
      parentNodeId = meshTopology.clientToNodeMap[mac];
      if (parentNodeId != null) {
        final isGateway = meshTopology.nodes.isNotEmpty &&
            meshTopology.nodes.first.deviceId == parentNodeId;
        if (isGateway) {
          parentNodeName = gatewayName;
        } else {
          final matchingNode = meshTopology.nodes
              .where((n) => n.deviceId == parentNodeId)
              .firstOrNull;
          parentNodeName = matchingNode?.model.isNotEmpty == true
              ? matchingNode!.model
              : parentNodeId;
        }
      } else {
        parentNodeName = gatewayName;
      }
    }

    return DeviceUIModel(
      mac: mac,
      ip: device.ipAddress,
      hostName: device.hostName,
      isActive: device.isActive,
      isWifi: isWifi,
      layer1Interface: device.interface_,
      ipv6Addresses: device.ipv6Addresses
          .map((e) => e.address)
          .where((a) => a.isNotEmpty)
          .toList(),
      signalStrength: isWifi ? wifiClient?.signalStrength : null,
      downlinkRate: isWifi ? wifiClient?.lastDataDownlinkRate : null,
      uplinkRate: isWifi ? wifiClient?.lastDataUplinkRate : null,
      band: detail?.band,
      ssidName: detail?.ssidName,
      parentNodeId: parentNodeId,
      parentNodeName: parentNodeName,
    );
  }

  static String _ensureTrailingDot(String path) {
    if (path.isEmpty) return path;
    return path.endsWith('.') ? path : '$path.';
  }
}
