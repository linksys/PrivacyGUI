import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/ai/abstraction/_abstraction.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

void _log(String message) {
  logger.d('[AI]: $message');
}

/// USP-based implementation of [IRouterCommandProvider].
///
/// Reads data from existing dashboard providers (L1 cache) instead of
/// re-fetching from the device, reducing latency and avoiding duplicate requests.
///
/// Write commands are not yet implemented — they will use UspClient directly.
class UspCommandProvider implements IRouterCommandProvider {
  UspCommandProvider(this._ref);

  final Ref _ref;

  static const _emptySchema = {
    'type': 'object',
    'properties': {},
  };

  static const _readCommands = [
    RouterCommand(
      name: 'getSystemInfo',
      description:
          'Get router system information including model, firmware version, and uptime.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getConnectedDevices',
      description:
          'Get list of all devices connected to the router, including name, IP, MAC, and connection type.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getWifiSettings',
      description:
          'Get WiFi settings including SSID, security mode, and radio status for all bands.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getWanStatus',
      description:
          'Get WAN (internet) connection status including IP address, gateway, and connection state.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getNetworkOverview',
      description:
          'Get a comprehensive overview of the network including device count, WAN status, and WiFi status.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    // === New commands ===
    RouterCommand(
      name: 'getLanInfo',
      description:
          'Get LAN configuration including IP address, subnet mask, DHCP settings, and DNS servers.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getDhcpInfo',
      description:
          'Get DHCP reservations and active DHCP clients with their IP assignments and lease times.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getEthernetPorts',
      description:
          'Get physical ethernet port status including WAN/LAN ports, link status, speed, and connected devices.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getFirewallStatus',
      description:
          'Get firewall configuration including IPv4/IPv6 firewall status, passthrough settings, and DMZ status.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getPortForwarding',
      description:
          'Get port forwarding rules including port ranges, protocols, and target devices.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getTimeSettings',
      description:
          'Get time settings including NTP status, timezone, and current router time.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getTrafficStats',
      description:
          'Get real-time traffic statistics including upload/download speeds and history for charts.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getSystemMonitor',
      description:
          'Get CPU and memory usage history for system performance charts.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getDeviceAnalytics',
      description:
          'Get device distribution analytics: WiFi vs Wired counts, band distribution, signal quality stats.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
    RouterCommand(
      name: 'getWifiStatus',
      description:
          'Get detailed WiFi radio status: Tx power, bit rate, channel, bandwidth, standards, and access points per band.',
      inputSchema: _emptySchema,
      accessLevel: AccessLevel.read,
    ),
  ];

  static const _writeCommands = <RouterCommand>[
    // TODO: Add write commands when ready
    // RouterCommand(
    //   name: 'setWifiPassword',
    //   description: 'Change WiFi password for a specific SSID.',
    //   inputSchema: {
    //     'type': 'object',
    //     'properties': {
    //       'ssid': {'type': 'string', 'description': 'Target SSID name'},
    //       'password': {'type': 'string', 'description': 'New password'},
    //     },
    //     'required': ['ssid', 'password'],
    //   },
    //   requiresConfirmation: true,
    //   accessLevel: AccessLevel.write,
    // ),
  ];

  static const _resources = [
    RouterResourceDescriptor(
      uri: 'router://system',
      name: 'System Info',
      description: 'Router model, firmware, uptime, and hardware details.',
    ),
    RouterResourceDescriptor(
      uri: 'router://devices',
      name: 'Connected Devices',
      description: 'List of all connected clients with connection details.',
    ),
    RouterResourceDescriptor(
      uri: 'router://wifi',
      name: 'WiFi Settings',
      description: 'WiFi radio and SSID configuration.',
    ),
    RouterResourceDescriptor(
      uri: 'router://wan',
      name: 'WAN Status',
      description: 'Internet connection status and configuration.',
    ),
    // === New resources ===
    RouterResourceDescriptor(
      uri: 'router://lan',
      name: 'LAN Info',
      description: 'LAN IP address, subnet, DHCP settings, and DNS.',
    ),
    RouterResourceDescriptor(
      uri: 'router://dhcp',
      name: 'DHCP Info',
      description: 'DHCP reservations and active client leases.',
    ),
    RouterResourceDescriptor(
      uri: 'router://ethernet',
      name: 'Ethernet Ports',
      description: 'Physical ethernet port status and connections.',
    ),
    RouterResourceDescriptor(
      uri: 'router://firewall',
      name: 'Firewall Status',
      description: 'Firewall settings, rules, and DMZ configuration.',
    ),
    RouterResourceDescriptor(
      uri: 'router://port-forwarding',
      name: 'Port Forwarding',
      description: 'Port forwarding rules configuration.',
    ),
    RouterResourceDescriptor(
      uri: 'router://time',
      name: 'Time Settings',
      description: 'NTP status, timezone, and current router time.',
    ),
  ];

  @override
  Future<List<RouterCommand>> listCommands() async {
    return [..._readCommands, ..._writeCommands];
  }

  @override
  List<RouterResourceDescriptor> listResources() => _resources;

  @override
  Future<RouterCommandResult> execute(
    String commandName,
    Map<String, dynamic> params,
  ) async {
    switch (commandName) {
      case 'getSystemInfo':
        return _getSystemInfo();
      case 'getConnectedDevices':
        return _getConnectedDevices();
      case 'getWifiSettings':
        return _getWifiSettings();
      case 'getWanStatus':
        return _getWanStatus();
      case 'getNetworkOverview':
        return _getNetworkOverview();
      // === New commands ===
      case 'getLanInfo':
        return _getLanInfo();
      case 'getDhcpInfo':
        return _getDhcpInfo();
      case 'getEthernetPorts':
        return _getEthernetPorts();
      case 'getFirewallStatus':
        return _getFirewallStatus();
      case 'getPortForwarding':
        return _getPortForwarding();
      case 'getTimeSettings':
        return _getTimeSettings();
      case 'getTrafficStats':
        return _getTrafficStats();
      case 'getSystemMonitor':
        return _getSystemMonitor();
      case 'getDeviceAnalytics':
        return _getDeviceAnalytics();
      case 'getWifiStatus':
        return _getWifiStatus();
      default:
        throw UnauthorizedCommandException(commandName);
    }
  }

  @override
  Future<RouterResource> readResource(String resourceUri) async {
    switch (resourceUri) {
      case 'router://system':
        final result = await _getSystemInfo();
        return RouterResource(uri: resourceUri, content: result.data);
      case 'router://devices':
        final result = await _getConnectedDevices();
        return RouterResource(uri: resourceUri, content: result.data);
      case 'router://wifi':
        final result = await _getWifiSettings();
        return RouterResource(uri: resourceUri, content: result.data);
      case 'router://wan':
        final result = await _getWanStatus();
        return RouterResource(uri: resourceUri, content: result.data);
      // === New resources ===
      case 'router://lan':
        final result = await _getLanInfo();
        return RouterResource(uri: resourceUri, content: result.data);
      case 'router://dhcp':
        final result = await _getDhcpInfo();
        return RouterResource(uri: resourceUri, content: result.data);
      case 'router://ethernet':
        final result = await _getEthernetPorts();
        return RouterResource(uri: resourceUri, content: result.data);
      case 'router://firewall':
        final result = await _getFirewallStatus();
        return RouterResource(uri: resourceUri, content: result.data);
      case 'router://port-forwarding':
        final result = await _getPortForwarding();
        return RouterResource(uri: resourceUri, content: result.data);
      case 'router://time':
        final result = await _getTimeSettings();
        return RouterResource(uri: resourceUri, content: result.data);
      default:
        throw ResourceNotFoundException(resourceUri);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Read Commands
  // ═══════════════════════════════════════════════════════════════════════════

  Future<RouterCommandResult> _getSystemInfo() async {
    final data = _ref.read(systemInfoDataProvider).valueOrNull;
    _log('_getSystemInfo: data=${data != null ? "present" : "null"}');
    if (data == null) {
      return RouterCommandResult.failure('System info not available');
    }

    final model = data.model;
    final result = {
      'modelName': model.modelName,
      'manufacturer': model.manufacturer,
      'hardwareVersion': model.hardwareVersion,
      'softwareVersion': model.softwareVersion,
      'serialNumber': model.serialNumber,
      'uptime': model.uptime,
      'uptimeFormatted': model.formattedUptime,
      'gatewayName': model.gatewayName,
      'cpuUsage': model.cpuPercent,
      'memoryUsage': model.memoryPercent,
    };
    _log(
        '_getSystemInfo: modelName=${model.modelName}, cpu=${model.cpuPercent}%, mem=${model.memoryPercent}%');
    return RouterCommandResult.success(result);
  }

  Future<RouterCommandResult> _getConnectedDevices() async {
    final data = _ref.read(devicesDataProvider).valueOrNull;
    _log('_getConnectedDevices: data=${data != null ? "present" : "null"}');
    if (data == null) {
      return RouterCommandResult.failure('Device data not available');
    }

    final devices = data.clientDevices.map((device) {
      return {
        'name': device.displayName,
        'ip': device.ip,
        'mac': device.mac,
        'connectionType': device.connectionType.name,
        'isOnline': device.isActive,
        'signalStrength': device.signalStrength,
        'band': device.band,
        'parentNodeId': device.parentNodeId,
        'downlinkRate': device.downlinkRate,
        'uplinkRate': device.uplinkRate,
      };
    }).toList();

    _log(
        '_getConnectedDevices: total=${data.totalClientCount}, online=${data.onlineClientCount}');
    for (final d in devices) {
      _log(
          '  - ${d['name']} (${d['ip']}) ${d['connectionType']} signal=${d['signalStrength']}');
    }

    // Mesh extenders (non-master nodes)
    final extenders = data.nodeModels
        .where((n) => !n.isMaster)
        .map((node) => {
              'name': node.displayName,
              'mac': node.deviceId,
              'model': node.model,
              'backhaulMediaType': node.backhaulMediaType,
              'backhaulSignalStrength': node.backhaulSignalStrength,
              'backhaulUplinkRate': node.backhaulUplinkRate,
            })
        .toList();

    if (extenders.isNotEmpty) {
      _log('_getConnectedDevices: extenders=${extenders.length}');
      for (final e in extenders) {
        _log('  - extender: ${e['name']} (${e['mac']})');
      }
    }

    return RouterCommandResult.success({
      'totalCount': data.totalClientCount,
      'onlineCount': data.onlineClientCount,
      'devices': devices,
      'extenders': extenders,
    });
  }

  Future<RouterCommandResult> _getWifiSettings() async {
    final data = _ref.read(wifiDataProvider).valueOrNull;
    if (data == null) {
      return RouterCommandResult.failure('WiFi data not available');
    }

    final radios = data.radioModels.map((radio) {
      final primaryAp =
          radio.accessPoints.isNotEmpty ? radio.accessPoints.first : null;
      return {
        'band': radio.band,
        'isEnabled': radio.enable,
        'channel': radio.channel,
        'channelWidth': radio.channelBandwidth,
        'ssid': primaryAp?.ssidName ?? '',
        'securityMode': primaryAp?.securityMode ?? '',
        'maxBitRate': radio.maxBitRate,
      };
    }).toList();

    return RouterCommandResult.success({
      'radios': radios,
      'totalClients': data.wifiClientMap.length,
    });
  }

  Future<RouterCommandResult> _getWanStatus() async {
    final data = _ref.read(wanDataProvider).valueOrNull;
    if (data == null) {
      return RouterCommandResult.failure('WAN data not available');
    }

    final model = data.model;
    return RouterCommandResult.success({
      'isConnected': model.isUp,
      'connectionType': model.addressingType,
      'ipAddress': model.ipAddress,
      'subnetMask': model.subnetMask,
      'gateway': model.gateway,
      'ipv6Enabled': model.ipv6Enabled,
      'mtu': model.mtu,
    });
  }

  Future<RouterCommandResult> _getNetworkOverview() async {
    final sysInfo = _ref.read(systemInfoDataProvider).valueOrNull;
    final devices = _ref.read(devicesDataProvider).valueOrNull;
    final wan = _ref.read(wanDataProvider).valueOrNull;
    final wifi = _ref.read(wifiDataProvider).valueOrNull;

    return RouterCommandResult.success({
      'routerModel': sysInfo?.model.modelName ?? 'Unknown',
      'firmwareVersion': sysInfo?.model.softwareVersion ?? 'Unknown',
      'uptime': sysInfo?.model.formattedUptime ?? 'Unknown',
      'internetStatus': wan?.model.isUp == true ? 'Connected' : 'Disconnected',
      'wanIp': wan?.model.ipAddress ?? 'N/A',
      'totalDevices': devices?.totalClientCount ?? 0,
      'onlineDevices': devices?.onlineClientCount ?? 0,
      'wifiClientCount': wifi?.wifiClientMap.length ?? 0,
      'activeBands': wifi?.radioModels
              .where((r) => r.enable)
              .map((r) => r.band)
              .toList() ??
          [],
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // New Read Commands
  // ═══════════════════════════════════════════════════════════════════════════

  Future<RouterCommandResult> _getLanInfo() async {
    final data = _ref.read(lanDataProvider).valueOrNull;
    _log('_getLanInfo: data=${data != null ? "present" : "null"}');
    if (data == null) {
      return RouterCommandResult.failure('LAN info not available');
    }

    final model = data.model;
    return RouterCommandResult.success({
      'ipAddress': model.ipAddress,
      'subnetMask': model.subnetMask,
      'hostName': model.hostName,
      'dhcpEnabled': model.dhcpEnabled,
      'dhcpRange': model.dhcpRange,
      'leaseTimeMinutes': model.leaseTimeMinutes,
      'dnsServers': model.dnsServers,
      'ipv6Enabled': model.ipv6Enabled,
      'ipv6Addresses': model.ipv6Addresses,
    });
  }

  Future<RouterCommandResult> _getDhcpInfo() async {
    final data = _ref.read(dhcpDataProvider).valueOrNull;
    _log('_getDhcpInfo: data=${data != null ? "present" : "null"}');
    if (data == null) {
      return RouterCommandResult.failure('DHCP info not available');
    }

    final reservations = data.reservationModels
        .map((r) => {
              'mac': r.mac,
              'ip': r.ip,
              'enabled': r.enable,
            })
        .toList();

    final clients = data.clientModels
        .map((c) => {
              'mac': c.mac,
              'ip': c.ip,
              'hostName': c.hostName,
              'active': c.active,
              'leaseExpiry': c.leaseExpiryFormatted,
              'leaseRemaining': c.leaseTimeFormatted,
            })
        .toList();

    _log(
        '_getDhcpInfo: ${reservations.length} reservations, ${clients.length} clients');
    return RouterCommandResult.success({
      'reservationCount': reservations.length,
      'reservations': reservations,
      'clientCount': clients.length,
      'clients': clients,
    });
  }

  Future<RouterCommandResult> _getEthernetPorts() async {
    final data = _ref.read(ethernetDataProvider).valueOrNull;
    _log('_getEthernetPorts: data=${data != null ? "present" : "null"}');
    if (data == null) {
      return RouterCommandResult.failure('Ethernet port info not available');
    }

    final ports = data.ethernetPortModels
        .map((port) => {
              'label': port.label,
              'name': port.name,
              'isWan': port.isWan,
              'isUp': port.isUp,
              'speed': port.speedLabel,
              'connectedDevices': port.connectedDevices
                  .map((d) => {
                        'hostName': d.hostName,
                        'mac': d.macAddress,
                        'ip': d.ipAddress,
                      })
                  .toList(),
            })
        .toList();

    _log('_getEthernetPorts: ${ports.length} ports');
    return RouterCommandResult.success({
      'portCount': ports.length,
      'ports': ports,
    });
  }

  Future<RouterCommandResult> _getFirewallStatus() async {
    final fwData = _ref.read(firewallDataProvider).valueOrNull;
    _log('_getFirewallStatus: data=${fwData != null ? "present" : "null"}');
    if (fwData == null) {
      return RouterCommandResult.failure('Firewall info not available');
    }

    final model = fwData.firewallModel;
    final pfData = _ref.read(portForwardingDataProvider).valueOrNull;

    return RouterCommandResult.success({
      'ipv4FirewallEnabled': model.isIPv4FirewallEnabled,
      'ipv6FirewallEnabled': model.isIPv6FirewallEnabled,
      'passthroughSettings': {
        'ipsec': !model.blockIPSec,
        'pptp': !model.blockPPTP,
        'l2tp': !model.blockL2TP,
      },
      'blockSettings': {
        'anonymousRequests': model.blockAnonymousRequests,
        'multicast': model.blockMulticast,
        'ident': model.blockIDENT,
      },
      'ruleCount': fwData.ruleSummaries.length,
      'rules': fwData.ruleSummaries
          .map((r) => {
                'target': r.target,
                'enabled': r.enabled,
              })
          .toList(),
      'dmzEnabled': fwData.dmzSummaries.any((d) => d.enable),
      'dmzEntries': fwData.dmzSummaries
          .map((d) => {
                'enabled': d.enable,
                'destIp': d.destIp,
              })
          .toList(),
      'portForwardingRuleCount': pfData?.ruleModels.length ?? 0,
    });
  }

  Future<RouterCommandResult> _getPortForwarding() async {
    final data = _ref.read(portForwardingDataProvider).valueOrNull;
    _log('_getPortForwarding: data=${data != null ? "present" : "null"}');
    if (data == null) {
      return RouterCommandResult.failure('Port forwarding info not available');
    }

    final rules = data.ruleModels
        .map((r) => {
              'description': r.description,
              'externalPort': r.externalPort,
              'externalPortEnd': r.externalPortEndRange,
              'internalPort': r.internalPort,
              'internalClient': r.internalClient,
              'protocol': r.protocol,
              'enabled': r.enabled,
            })
        .toList();

    final enabledCount = data.ruleModels.where((r) => r.enabled).length;
    _log('_getPortForwarding: ${rules.length} rules, $enabledCount enabled');

    return RouterCommandResult.success({
      'ruleCount': rules.length,
      'enabledCount': enabledCount,
      'rules': rules,
    });
  }

  Future<RouterCommandResult> _getTimeSettings() async {
    final data = _ref.read(timeDataProvider).valueOrNull;
    _log('_getTimeSettings: data=${data != null ? "present" : "null"}');
    if (data == null) {
      return RouterCommandResult.failure('Time settings not available');
    }

    final model = data.model;
    return RouterCommandResult.success({
      'ntpEnabled': model.enable,
      'ntpStatus': model.status,
      'currentTime': model.currentLocalTime,
      'timezone': model.localTimeZone,
      'ntpServer1': model.ntpServer1,
      'ntpServer2': model.ntpServer2,
    });
  }

  Future<RouterCommandResult> _getTrafficStats() async {
    final data = _ref.read(uspTrafficAnalysisProvider);
    _log('_getTrafficStats: historyLength=${data.history.length}');

    if (data.history.isEmpty) {
      return RouterCommandResult.failure(
        'Traffic data not available. The router may not support historical traffic statistics.',
      );
    }

    // Get current (latest) snapshot
    final latest = data.history.last;
    final wanSnapshot = latest.interfaces[TrafficInterface.wan];

    // Build history arrays for charts (last 60 data points)
    const historyLimit = 60;
    final recentHistory = data.history.length > historyLimit
        ? data.history.sublist(data.history.length - historyLimit)
        : data.history;

    final uploadHistory = <double>[];
    final downloadHistory = <double>[];
    for (final snapshot in recentHistory) {
      final wan = snapshot.interfaces[TrafficInterface.wan];
      uploadHistory.add(wan?.uploadBytesPerSec ?? 0);
      downloadHistory.add(wan?.downloadBytesPerSec ?? 0);
    }

    _log('_getTrafficStats: upload=${wanSnapshot?.uploadBytesPerSec ?? 0} B/s, '
        'download=${wanSnapshot?.downloadBytesPerSec ?? 0} B/s');

    return RouterCommandResult.success({
      'current': {
        'uploadBytesPerSec': wanSnapshot?.uploadBytesPerSec ?? 0,
        'downloadBytesPerSec': wanSnapshot?.downloadBytesPerSec ?? 0,
        'totalBytesSent': wanSnapshot?.totalBytesSent ?? 0,
        'totalBytesReceived': wanSnapshot?.totalBytesReceived ?? 0,
      },
      'history': {
        'upload': uploadHistory,
        'download': downloadHistory,
        'pointCount': recentHistory.length,
      },
      'refreshIntervalSec': data.refreshInterval?.inSeconds ?? 5,
    });
  }

  Future<RouterCommandResult> _getSystemMonitor() async {
    final data = _ref.read(uspSystemMonitorProvider);
    _log('_getSystemMonitor: historyLength=${data.history.length}');

    if (data.history.isEmpty) {
      return RouterCommandResult.failure(
        'System monitor data not available yet.',
      );
    }

    // Get current (latest) snapshot
    final latest = data.latest;

    // Build history arrays for charts
    const historyLimit = 60;
    final recentHistory = data.history.length > historyLimit
        ? data.history.sublist(data.history.length - historyLimit)
        : data.history;

    final cpuHistory = <int>[];
    final memoryHistory = <int>[];
    for (final snapshot in recentHistory) {
      cpuHistory.add(snapshot.cpuPercent);
      memoryHistory.add(snapshot.memoryPercent);
    }

    _log(
        '_getSystemMonitor: cpu=${latest?.cpuPercent}%, memory=${latest?.memoryPercent}%');

    return RouterCommandResult.success({
      'current': {
        'cpuPercent': latest?.cpuPercent ?? 0,
        'memoryPercent': latest?.memoryPercent ?? 0,
        'totalMemoryKb': latest?.totalMemoryKb ?? 0,
        'freeMemoryKb': latest?.freeMemoryKb ?? 0,
        'usedMemoryKb': latest?.usedMemoryKb ?? 0,
      },
      'history': {
        'cpu': cpuHistory,
        'memory': memoryHistory,
        'pointCount': recentHistory.length,
      },
      'refreshIntervalSec': data.refreshInterval?.inSeconds ?? 30,
    });
  }

  Future<RouterCommandResult> _getDeviceAnalytics() async {
    final data = _ref.read(uspDeviceAnalyticsProvider);
    final distribution = data.current;
    _log(
        '_getDeviceAnalytics: wifi=${distribution?.wifiCount ?? 0}, wired=${distribution?.wiredCount ?? 0}');

    if (distribution == null) {
      return RouterCommandResult.failure(
        'Device analytics data not available yet.',
      );
    }

    return RouterCommandResult.success({
      'distribution': {
        'wifiCount': distribution.wifiCount,
        'wiredCount': distribution.wiredCount,
        'onlineCount': distribution.onlineCount,
        'offlineCount': distribution.offlineCount,
        'totalCount': distribution.totalCount,
      },
      'bandDistribution': distribution.bandDistribution,
      'signalLevelDistribution': distribution.signalLevelDistribution,
      'bandSignalQuality': distribution.bandSignalQuality,
      'hourlyHistoryCount': data.hourlyHistory.length,
    });
  }

  Future<RouterCommandResult> _getWifiStatus() async {
    final data = _ref.read(wifiDataProvider).valueOrNull;
    _log('_getWifiStatus: data=${data != null ? "present" : "null"}');
    if (data == null) {
      return RouterCommandResult.failure('WiFi data not available');
    }

    final radios = data.radioModels.map((radio) {
      final accessPoints = radio.accessPoints
          .map((ap) => {
                'ssidName': ap.ssidName,
                'enabled': ap.enable,
                'securityMode': ap.securityMode,
                'encryptionMode': ap.encryptionMode,
                'isGuest': ap.isGuest,
              })
          .toList();

      return {
        'band': radio.band,
        'enabled': radio.enable,
        'txPowerPercent': radio.txPowerPercent,
        'txPowerDisplay': radio.txPowerDisplay,
        'maxBitRate': radio.maxBitRate,
        'bitRateNormalized': radio.bitRateNormalized,
        'channel': radio.channel,
        'channelDisplay': radio.channelDisplay,
        'autoChannel': radio.autoChannelEnable,
        'channelBandwidth': radio.channelBandwidth,
        'supportedStandards': radio.supportedStandards,
        'accessPoints': accessPoints,
      };
    }).toList();

    final enabledCount = data.radioModels.where((r) => r.enable).length;
    _log('_getWifiStatus: radios=${radios.length}, enabled=$enabledCount');

    return RouterCommandResult.success({
      'totalRadios': radios.length,
      'enabledRadios': enabledCount,
      'radios': radios,
    });
  }
}

/// Function type for reading providers.
/// Both [WidgetRef] and [ProviderContainer] satisfy this signature.
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Builds the router context string for AI system prompt.
///
/// This provides current router state to the AI so it can make informed
/// decisions without needing to query.
///
/// Accepts a [ProviderReader] function. Use `ref.read` from WidgetRef/Ref,
/// or `container.read` from ProviderContainer (for tests).
String buildRouterContext(ProviderReader read) {
  _log('buildRouterContext: building context from providers...');
  final buffer = StringBuffer();
  buffer.writeln('# Current Router State\n');

  // Helper to safely get valueOrNull from AsyncValue
  T? getValue<T>(AsyncValue<T>? asyncValue) {
    if (asyncValue == null) return null;
    return asyncValue.valueOrNull;
  }

  // System Info
  final sysInfo = getValue<SystemInfoData>(read(systemInfoDataProvider));
  _log(
      'buildRouterContext: systemInfo=${sysInfo != null ? "present" : "null"}');
  if (sysInfo != null) {
    final model = sysInfo.model;
    _log(
        'buildRouterContext: model=${model.modelName}, fw=${model.softwareVersion}');
    buffer.writeln('## Router');
    buffer.writeln('- Model: ${model.modelName}');
    buffer.writeln('- Firmware: ${model.softwareVersion}');
    buffer.writeln('- Name: ${model.gatewayName}');
    buffer.writeln('- CPU Usage: ${model.cpuPercent}%');
    buffer.writeln('- Memory Usage: ${model.memoryPercent}%');
    buffer.writeln();
  }

  // WAN Status
  final wan = getValue<WanData>(read(wanDataProvider));
  _log('buildRouterContext: wan=${wan != null ? "present" : "null"}');
  if (wan != null) {
    final m = wan.model;
    _log('buildRouterContext: wan.isUp=${m.isUp}, ip=${m.ipAddress}');
    buffer.writeln('## Internet Connection');
    buffer.writeln('- Status: ${m.isUp ? "Connected" : "Disconnected"}');
    if (m.isUp) {
      buffer.writeln('- IP Address: ${m.ipAddress}');
      buffer.writeln('- Connection Type: ${m.addressingType}');
    }
    buffer.writeln();
  }

  // Devices
  final devices = getValue<DevicesData>(read(devicesDataProvider));
  _log('buildRouterContext: devices=${devices != null ? "present" : "null"}');
  if (devices != null) {
    _log(
        'buildRouterContext: total=${devices.totalClientCount}, online=${devices.onlineClientCount}');
    buffer.writeln('## Connected Devices');
    buffer.writeln('- Total connected devices: ${devices.totalClientCount}');
    buffer.writeln('- Currently online: ${devices.onlineClientCount}');
    buffer.writeln();

    // Mesh nodes (extenders)
    final nodeModels = devices.nodeModels;
    final extenders = nodeModels.where((n) => !n.isMaster).toList();
    if (extenders.isNotEmpty) {
      _log('buildRouterContext: extenders=${extenders.length}');
      buffer.writeln('## Mesh Extenders');
      for (final ext in extenders) {
        _log('buildRouterContext:   - ${ext.displayName} (${ext.deviceId})');
        buffer.writeln(
            '- ${ext.displayName}: ${ext.model}, backhaul=${ext.backhaulMediaType}, rssi=${ext.backhaulSignalStrength ?? "N/A"}');
      }
      buffer.writeln();
    }
  }

  // WiFi
  final wifi = getValue<WifiData>(read(wifiDataProvider));
  _log('buildRouterContext: wifi=${wifi != null ? "present" : "null"}');
  if (wifi != null) {
    buffer.writeln('## WiFi');
    for (final radio in wifi.radioModels) {
      final status = radio.enable ? 'Enabled' : 'Disabled';
      final ssid = radio.accessPoints.isNotEmpty
          ? radio.accessPoints.first.ssidName
          : 'N/A';
      _log('buildRouterContext: ${radio.band}: $status, SSID="$ssid"');
      buffer.writeln('- ${radio.band}: $status, SSID: "$ssid"');
    }
    buffer.writeln();
  }

  // LAN Configuration
  final lan = getValue<LanData>(read(lanDataProvider));
  _log('buildRouterContext: lan=${lan != null ? "present" : "null"}');
  if (lan != null) {
    final m = lan.model;
    buffer.writeln('## LAN Configuration');
    buffer.writeln('- IP Address: ${m.ipAddress}');
    buffer.writeln('- Subnet Mask: ${m.subnetMask}');
    buffer.writeln(
        '- DHCP: ${m.dhcpEnabled ? "Enabled (${m.dhcpRange})" : "Disabled"}');
    if (m.dnsServers.isNotEmpty) {
      buffer.writeln('- DNS Servers: ${m.dnsServers}');
    }
    buffer.writeln();
  }

  // Ethernet Ports
  final ethernet = getValue<EthernetData>(read(ethernetDataProvider));
  _log('buildRouterContext: ethernet=${ethernet != null ? "present" : "null"}');
  if (ethernet != null) {
    buffer.writeln('## Ethernet Ports');
    for (final port in ethernet.ethernetPortModels) {
      final status =
          port.isUp ? 'Connected (${port.speedLabel})' : 'Disconnected';
      buffer.writeln('- ${port.label}: $status');
    }
    buffer.writeln();
  }

  // Security / Firewall
  final firewall = getValue<FirewallData>(read(firewallDataProvider));
  _log('buildRouterContext: firewall=${firewall != null ? "present" : "null"}');
  if (firewall != null) {
    final m = firewall.firewallModel;
    buffer.writeln('## Security');
    buffer.writeln(
        '- IPv4 Firewall: ${m.isIPv4FirewallEnabled ? "Enabled" : "Disabled"}');
    buffer.writeln(
        '- IPv6 Firewall: ${m.isIPv6FirewallEnabled ? "Enabled" : "Disabled"}');
    buffer.writeln('- Firewall Rules: ${firewall.ruleSummaries.length}');
    buffer.writeln(
        '- DMZ: ${firewall.dmzSummaries.any((d) => d.enable) ? "Enabled" : "Disabled"}');
    buffer.writeln();
  }

  // Port Forwarding
  final portFwd =
      getValue<PortForwardingData>(read(portForwardingDataProvider));
  _log(
      'buildRouterContext: portForwarding=${portFwd != null ? "present" : "null"}');
  if (portFwd != null && portFwd.ruleModels.isNotEmpty) {
    final enabledCount = portFwd.ruleModels.where((r) => r.enabled).length;
    buffer.writeln('## Port Forwarding');
    buffer
        .writeln('- Active Rules: $enabledCount/${portFwd.ruleModels.length}');
    buffer.writeln();
  }

  _log('buildRouterContext: done');
  return buffer.toString();
}
