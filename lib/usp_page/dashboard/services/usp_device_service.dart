import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/lan_info_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_info_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/time_settings_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/wan_status_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/wifi_client_enricher.dart';
import 'package:privacy_gui/usp_page/topology/models/node_ui_model.dart';

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
  // SystemInfo
  // ---------------------------------------------------------------------------

  SystemInfoUIModel buildSystemInfoUIModel(SystemInfo info) {
    return SystemInfoUIModel(
      manufacturer: info.manufacturer,
      modelName: info.modelName,
      serialNumber: info.serialNumber,
      hardwareVersion: info.hardwareVersion,
      softwareVersion: info.softwareVersion,
      uptime: info.uptime,
      totalMemory: info.totalMemory,
      freeMemory: info.freeMemory,
      cpuUsage: info.cpuUsage,
    );
  }

  // ---------------------------------------------------------------------------
  // ConnectedDevices
  // ---------------------------------------------------------------------------

  List<DeviceUIModel> buildDeviceUIModels({
    required ConnectedDevices connectedDevices,
    required Map<String, WifiClient> wifiClientMap,
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
  // WiFi Radios
  // ---------------------------------------------------------------------------

  List<WifiRadioUIModel> buildWifiRadioUIModels({
    required WiFiRadios radios,
    required WiFiSsids ssids,
    required WiFiAccessPoints accessPoints,
  }) {
    final ssidByPath = {
      for (final s in ssids.items) _ensureTrailingDot(s.instancePath): s,
    };

    // Group APs by radio: AP.ssidReference → SSID.lowerLayers → Radio
    final apsByRadioPath = <String, List<_ApWithSsid>>{};
    for (final ap in accessPoints.items) {
      final ssid = ssidByPath[_ensureTrailingDot(ap.ssidReference)];
      if (ssid == null) continue;
      final radioPath = _ensureTrailingDot(ssid.lowerLayers);
      apsByRadioPath
          .putIfAbsent(radioPath, () => [])
          .add(_ApWithSsid(ap, ssid));
    }

    return radios.items.map((radio) {
      final radioAps =
          apsByRadioPath[_ensureTrailingDot(radio.instancePath)] ?? [];
      return WifiRadioUIModel(
        instancePath: radio.instancePath,
        band: radio.operatingFrequencyBand,
        enable: radio.enable,
        transmitPower: radio.transmitPower,
        maxBitRate: radio.maxBitRate,
        channel: radio.channel,
        autoChannelEnable: radio.autoChannelEnable,
        channelBandwidth: radio.operatingChannelBandwidth,
        supportedStandards: radio.supportedStandards,
        accessPoints: radioAps
            .map((a) => WifiAccessPointUIModel(
                  enable: a.ap.enable,
                  ssidName:
                      a.ssid.ssid.isNotEmpty ? a.ssid.ssid : a.ap.ssidReference,
                  securityMode: a.ap.securityModeEnabled,
                  encryptionMode: a.ap.encryptionMode,
                ))
            .toList(),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Time Settings
  // ---------------------------------------------------------------------------

  TimeSettingsUIModel buildTimeSettingsUIModel(TimeSettings settings) {
    return TimeSettingsUIModel(
      enable: settings.enable,
      status: settings.status,
      currentLocalTime: settings.currentLocalTime,
      localTimeZone: settings.localTimeZone,
      ntpServer1: settings.ntpServer1,
      ntpServer2: settings.ntpServer2,
    );
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
    bool ipv6Enabled = false,
    List<String> ipv6Addresses = const [],
  }) {
    return LanInfoUIModel(
      ipAddress: info.ipAddress,
      subnetMask: info.subnetMask,
      dhcpEnabled: info.dhcpEnabled,
      minAddress: info.minAddress,
      maxAddress: info.maxAddress,
      dnsServers: info.dnsServers,
      ipv6Enabled: ipv6Enabled,
      ipv6Addresses: ipv6Addresses,
    );
  }

  // ---------------------------------------------------------------------------
  // WAN Status
  // ---------------------------------------------------------------------------

  WanStatusUIModel buildWanStatusUIModel({
    required WanStatus wanStatus,
    required String gateway,
    bool ipv6Enabled = false,
    List<String> ipv6Addresses = const [],
  }) {
    return WanStatusUIModel(
      isUp: wanStatus.status.toLowerCase() == 'up',
      ipAddress: wanStatus.ipAddress,
      subnetMask: wanStatus.subnetMask,
      addressingType: wanStatus.addressingType,
      mtu: wanStatus.maxMtuSize,
      gateway: gateway,
      ipv6Enabled: ipv6Enabled,
      ipv6Addresses: ipv6Addresses,
    );
  }

  // ---------------------------------------------------------------------------
  // Ethernet Ports
  // ---------------------------------------------------------------------------

  List<EthernetPortUIModel> buildEthernetPortUIModels({
    required EthernetInterfaces ethernetInterfaces,
    required ConnectedDevices connectedDevices,
  }) {
    final result = <EthernetPortUIModel>[];

    // WAN (upstream): real physical port — use interface Status directly.
    // LAN (non-upstream): switch chip aggregate — Status is always Up
    // regardless of cable connections. Derive effective status from
    // whether any active ConnectedDevice is wired to this interface.
    final wanPorts = <EthernetInterface>[];
    final lanPorts = <EthernetInterface>[];
    for (final iface in ethernetInterfaces.items) {
      if (iface.upstream) {
        wanPorts.add(iface);
      } else {
        lanPorts.add(iface);
      }
    }

    // WAN ports
    for (final port in wanPorts) {
      final isUp = port.status.toLowerCase() == 'up';
      result.add(EthernetPortUIModel(
        name: port.name,
        label: 'WAN',
        isWan: true,
        isUp: isUp,
        instancePath: port.instancePath,
        currentBitRate: port.currentBitRate,
      ));
    }

    // LAN ports — effective status from ConnectedDevices
    lanPorts.sort((a, b) => a.name.compareTo(b.name));
    for (var i = 0; i < lanPorts.length; i++) {
      final port = lanPorts[i];
      final portPath = _ensureTrailingDot(port.instancePath);
      final wiredDevices = connectedDevices.items
          .where((d) =>
              d.isActive &&
              d.interface_.isNotEmpty &&
              _ensureTrailingDot(d.interface_) == portPath)
          .toList();

      final effectivelyUp = wiredDevices.isNotEmpty;
      final deviceInfos = wiredDevices
          .map((d) => WiredDeviceInfo(
                hostName: d.hostName,
                macAddress: d.macAddress,
                ipAddress: d.ipAddress,
              ))
          .toList();

      result.add(EthernetPortUIModel(
        name: port.name,
        label: lanPorts.length == 1 ? 'LAN' : 'LAN ${i + 1}',
        isWan: false,
        isUp: effectivelyUp,
        instancePath: port.instancePath,
        currentBitRate: effectivelyUp ? port.currentBitRate : 0,
        connectedDevices: deviceInfos,
      ));
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
        radioCount: node.radioCount,
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
    Map<String, WifiClient> wifiClientMap,
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

/// Internal helper to pair AP with its resolved SSID.
class _ApWithSsid {
  final WiFiAccessPoint ap;
  final WiFiSsid ssid;
  const _ApWithSsid(this.ap, this.ssid);
}
