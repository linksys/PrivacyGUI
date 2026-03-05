import 'package:flutter/material.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/wifi_client_enricher.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_status_dot.dart';

class UspConnectedDevicesCard extends StatelessWidget {
  final List<ConnectedDevice> devices;
  final Map<String, WifiClient> wifiClientMap;
  final MeshTopologyInfo meshTopology;
  final Map<String, ClientConnectionDetail> connectionDetailMap;

  /// Display name for the gateway (router model). Used to show "via [model]"
  /// for devices connected to the master node.
  final String gatewayName;

  const UspConnectedDevicesCard({
    super.key,
    required this.devices,
    this.wifiClientMap = const {},
    this.meshTopology = MeshTopologyInfo.empty,
    this.connectionDetailMap = const {},
    this.gatewayName = 'Router',
  });

  @override
  Widget build(BuildContext context) {
    final activeDevices = devices.where((d) => d.isActive).toList();
    final inactiveDevices = devices.where((d) => !d.isActive).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Connected Devices'),
              AppText.labelLarge(
                '${activeDevices.length} / ${devices.length}',
              ),
            ],
          ),
          AppGap.xl(),
          if (devices.isEmpty)
            AppText.bodyMedium('No devices found')
          else ...[
            if (activeDevices.isNotEmpty) ...[
              AppText.labelLarge('Online'),
              AppGap.sm(),
              ...activeDevices.map(_buildDeviceRow),
            ],
            if (inactiveDevices.isNotEmpty) ...[
              if (activeDevices.isNotEmpty) AppGap.lg(),
              AppText.labelLarge('Offline'),
              AppGap.sm(),
              ...inactiveDevices.map(_buildDeviceRow),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceRow(ConnectedDevice device) {
    final mac = device.macAddress.toUpperCase();
    final wifiInfo = wifiClientMap[mac];
    final isWifi = wifiInfo != null;
    final connDetail = connectionDetailMap[mac];
    final parentNodeName =
        device.isActive ? _resolveParentNodeName(mac) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          UspStatusDot(isActive: device.isActive),
          AppGap.sm(),
          // Connection type icon
          _buildConnectionIcon(isWifi, wifiInfo, device.isActive),
          AppGap.sm(),
          // Name + subtitle (MAC, band/SSID, parent node)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(
                  device.hostName.isNotEmpty
                      ? device.hostName
                      : device.macAddress,
                ),
                Builder(builder: (context) {
                  final subtitle = _buildSubtitle(
                    device: device,
                    isWifi: isWifi,
                    connDetail: connDetail,
                    parentNodeName: parentNodeName,
                  );
                  if (subtitle.isEmpty) return const SizedBox.shrink();
                  return AppText.bodySmall(
                    subtitle,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  );
                }),
              ],
            ),
          ),
          // Signal strength or connection type badge
          if (device.isActive && isWifi)
            _buildSignalBadge(wifiInfo.signalStrength)
          else if (device.isActive && !isWifi)
            Builder(builder: (context) {
              return AppText.bodySmall(
                'Ethernet',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              );
            }),
          AppGap.sm(),
          // IP address
          Builder(builder: (context) {
            return SizedBox(
              width: 130,
              child: AppText.bodySmall(
                device.ipAddress,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Builds the subtitle line: "MAC · 5GHz MyNetwork · via MR7500"
  String _buildSubtitle({
    required ConnectedDevice device,
    required bool isWifi,
    ClientConnectionDetail? connDetail,
    String? parentNodeName,
  }) {
    final parts = <String>[];

    // MAC (only if hostname is shown as primary)
    if (device.hostName.isNotEmpty) parts.add(device.macAddress);

    // Band + SSID or Ethernet
    if (isWifi && connDetail != null) {
      final bandSsid = [
        if (connDetail.band.isNotEmpty) connDetail.band,
        if (connDetail.ssidName.isNotEmpty) connDetail.ssidName,
      ].join(' ');
      if (bandSsid.isNotEmpty) parts.add(bandSsid);
    } else if (!isWifi && device.isActive) {
      parts.add('Ethernet');
    }

    // Parent node
    if (parentNodeName != null) parts.add('via $parentNodeName');

    return parts.join(' · ');
  }

  Widget _buildConnectionIcon(
      bool isWifi, WifiClient? wifiInfo, bool isActive) {
    return Builder(builder: (context) {
      if (!isWifi) {
        return Icon(
          Icons.settings_ethernet,
          size: 18,
          color: isActive
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
        );
      }
      return Icon(
        _wifiIconForSignal(wifiInfo!.signalStrength),
        size: 18,
        color: isActive
            ? _signalColor(context, wifiInfo.signalStrength)
            : Theme.of(context).colorScheme.onSurfaceVariant,
      );
    });
  }

  Widget _buildSignalBadge(int rssi) {
    return Builder(builder: (context) {
      return AppText.bodySmall(
        '$rssi dBm',
        color: _signalColor(context, rssi),
      );
    });
  }

  static IconData _wifiIconForSignal(int rssi) {
    if (rssi >= -50) return Icons.wifi;
    if (rssi >= -60) return Icons.wifi_2_bar;
    if (rssi >= -70) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

  static Color _signalColor(BuildContext context, int rssi) {
    final scheme = Theme.of(context).colorScheme;
    if (rssi >= -50) return Colors.green;
    if (rssi >= -60) return Colors.lightGreen;
    if (rssi >= -70) return Colors.orange;
    return scheme.error;
  }

  /// Resolves the parent node name for a client device.
  ///
  /// - Single router (no mesh): returns [gatewayName] so active devices show
  ///   "via MR7500" (or whatever the router model is).
  /// - Mesh, client on gateway: returns [gatewayName].
  /// - Mesh, client on extender: returns the extender model / device ID.
  String? _resolveParentNodeName(String clientMac) {
    // No mesh data — single router, all clients are on the gateway
    if (meshTopology.isEmpty) return gatewayName;

    final nodeId = meshTopology.clientToNodeMap[clientMac.toUpperCase()];
    if (nodeId == null) return gatewayName; // not in map — assume gateway

    // Gateway-connected client
    if (meshTopology.nodes.isNotEmpty &&
        meshTopology.nodes.first.deviceId == nodeId) {
      return gatewayName;
    }

    // Extender-connected client
    final node = meshTopology.nodes
        .where((n) => n.deviceId == nodeId)
        .firstOrNull;
    if (node == null) return null;
    return node.model.isNotEmpty ? node.model : nodeId;
  }
}
