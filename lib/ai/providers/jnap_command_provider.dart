import 'package:privacy_gui/ai/abstraction/_abstraction.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

/// Metadata for allowed JNAP actions.
class _ActionMeta {
  final String description;
  final AccessLevel accessLevel;
  final bool requiresConfirmation;

  const _ActionMeta({
    required this.description,
    this.accessLevel = AccessLevel.read,
    this.requiresConfirmation = false,
  });
}

/// JNAP-based implementation of [IRouterCommandProvider].
///
/// This provider exposes a whitelist of JNAP actions to the AI agent.
/// Only actions in [_allowedActions] can be executed.
class JnapCommandProvider implements IRouterCommandProvider {
  final RouterRepository _router;

  JnapCommandProvider(this._router);

  /// Whitelist of JNAP actions exposed to AI.
  ///
  /// Actions not in this map will be rejected.
  static const _allowedActions = <JNAPAction, _ActionMeta>{
    // === Read-only operations ===

    // Device management
    JNAPAction.getDevices: _ActionMeta(
      description:
          'Get all connected devices with their details (name, IP, MAC, connection type)',
      accessLevel: AccessLevel.read,
    ),
    JNAPAction.getDeviceInfo: _ActionMeta(
      description:
          'Get router device information (model, firmware version, serial number)',
      accessLevel: AccessLevel.read,
    ),

    // WiFi settings
    JNAPAction.getRadioInfo: _ActionMeta(
      description:
          'Get WiFi radio settings (SSID, security mode, channel, band)',
      accessLevel: AccessLevel.read,
    ),
    JNAPAction.getSimpleWiFiSettings: _ActionMeta(
      description: 'Get simplified WiFi settings (SSID, password)',
      accessLevel: AccessLevel.read,
    ),

    // Network status
    JNAPAction.getWANStatus: _ActionMeta(
      description:
          'Get WAN connection status (IP address, connection type, uptime)',
      accessLevel: AccessLevel.read,
    ),
    JNAPAction.getNetworkConnections: _ActionMeta(
      description: 'Get all network connections with bandwidth usage',
      accessLevel: AccessLevel.read,
    ),
    JNAPAction.getSystemStats: _ActionMeta(
      description: 'Get system statistics (CPU, memory, uplink/downlink speed)',
      accessLevel: AccessLevel.read,
    ),

    // Guest network
    JNAPAction.getGuestNetworkSettings: _ActionMeta(
      description: 'Get guest network settings (enabled, SSID, password)',
      accessLevel: AccessLevel.read,
    ),
    JNAPAction.getGuestNetworkClients: _ActionMeta(
      description: 'Get clients connected to guest network',
      accessLevel: AccessLevel.read,
    ),

    // Mesh/Nodes
    JNAPAction.getBackhaulInfo: _ActionMeta(
      description:
          'Get mesh backhaul information (connection quality between nodes)',
      accessLevel: AccessLevel.read,
    ),
    JNAPAction.getNodesWirelessNetworkConnections: _ActionMeta(
      description: 'Get wireless connections for all mesh nodes',
      accessLevel: AccessLevel.read,
    ),

    // Security
    JNAPAction.getFirewallSettings: _ActionMeta(
      description: 'Get firewall settings',
      accessLevel: AccessLevel.read,
    ),
    JNAPAction.getMACFilterSettings: _ActionMeta(
      description: 'Get MAC address filter settings (blocked/allowed devices)',
      accessLevel: AccessLevel.read,
    ),

    // QoS
    JNAPAction.getQoSSettings: _ActionMeta(
      description: 'Get Quality of Service settings (bandwidth prioritization)',
      accessLevel: AccessLevel.read,
    ),

    // Firmware
    JNAPAction.getFirmwareUpdateStatus: _ActionMeta(
      description:
          'Get firmware update status (current version, available updates)',
      accessLevel: AccessLevel.read,
    ),

    // Health check
    JNAPAction.getHealthCheckResults: _ActionMeta(
      description: 'Get network health check results',
      accessLevel: AccessLevel.read,
    ),

    // === Write operations (require confirmation) ===

    // WiFi settings
    JNAPAction.setRadioSettings: _ActionMeta(
      description: 'Change WiFi settings (SSID, password, channel)',
      accessLevel: AccessLevel.write,
      requiresConfirmation: true,
    ),
    JNAPAction.setSimpleWiFiSettings: _ActionMeta(
      description: 'Change WiFi SSID and password',
      accessLevel: AccessLevel.write,
      requiresConfirmation: true,
    ),

    // Guest network
    JNAPAction.setGuestNetworkSettings: _ActionMeta(
      description: 'Enable/disable or configure guest network',
      accessLevel: AccessLevel.write,
      requiresConfirmation: true,
    ),

    // Device management
    JNAPAction.setDeviceProperties: _ActionMeta(
      description: 'Set device properties (name, icon)',
      accessLevel: AccessLevel.write,
      requiresConfirmation: true,
    ),

    // MAC filter
    JNAPAction.setMACFilterSettings: _ActionMeta(
      description: 'Block or allow devices by MAC address',
      accessLevel: AccessLevel.write,
      requiresConfirmation: true,
    ),

    // === Admin operations (require double confirmation) ===

    JNAPAction.reboot: _ActionMeta(
      description:
          'Restart the router (will disconnect all devices temporarily)',
      accessLevel: AccessLevel.admin,
      requiresConfirmation: true,
    ),
  };

  /// Resource definitions for MCP resources/list.
  static const _resources = <RouterResourceDescriptor>[
    RouterResourceDescriptor(
      uri: 'router://devices',
      name: 'Connected Devices',
      description: 'List of all devices connected to the router',
    ),
    RouterResourceDescriptor(
      uri: 'router://wifi',
      name: 'WiFi Settings',
      description: 'Current WiFi configuration',
    ),
    RouterResourceDescriptor(
      uri: 'router://topology',
      name: 'Network Topology  ',
      description: 'Mesh network topology and node information',
    ),
    RouterResourceDescriptor(
      uri: 'router://status',
      name: 'System Status',
      description: 'Router system status and statistics',
    ),
  ];

  @override
  Future<List<RouterCommand>> listCommands() async {
    return _allowedActions.entries.map((entry) {
      return RouterCommand(
        name: entry.key.name,
        description: entry.value.description,
        inputSchema: _generateSchema(entry.key),
        requiresConfirmation: entry.value.requiresConfirmation,
        accessLevel: entry.value.accessLevel,
      );
    }).toList();
  }

  @override
  Future<RouterCommandResult> execute(
    String commandName,
    Map<String, dynamic> params,
  ) async {
    // Find the action by name
    final action = JNAPAction.values.cast<JNAPAction?>().firstWhere(
          (a) => a?.name == commandName,
          orElse: () => null,
        );

    if (action == null) {
      throw UnauthorizedCommandException(commandName);
    }

    if (!_allowedActions.containsKey(action)) {
      throw UnauthorizedCommandException(commandName);
    }

    try {
      final result = await _router.send(action, data: params);
      return RouterCommandResult.success(result.output);
    } catch (e) {
      return RouterCommandResult.failure(e.toString());
    }
  }

  @override
  List<RouterResourceDescriptor> listResources() => _resources;

  @override
  Future<RouterResource> readResource(String resourceUri) async {
    switch (resourceUri) {
      case 'router://devices':
        final result = await _router.send(JNAPAction.getDevices);
        return RouterResource(
          uri: resourceUri,
          content: result.output,
        );

      case 'router://wifi':
        final result = await _router.send(JNAPAction.getRadioInfo);
        return RouterResource(
          uri: resourceUri,
          content: result.output,
        );

      case 'router://topology':
        final result = await _router.send(JNAPAction.getBackhaulInfo);
        return RouterResource(
          uri: resourceUri,
          content: result.output,
        );

      case 'router://status':
        final result = await _router.send(JNAPAction.getSystemStats);
        return RouterResource(
          uri: resourceUri,
          content: result.output,
        );

      default:
        throw ResourceNotFoundException(resourceUri);
    }
  }

  /// Generates a JSON Schema for the given action.
  ///
  /// TODO: This could be enhanced to read from JNAP spec files
  /// or use reflection to generate accurate schemas.
  Map<String, dynamic> _generateSchema(JNAPAction action) {
    // For now, return a basic object schema
    // This can be enhanced with action-specific schemas
    return {
      'type': 'object',
      'properties': {},
    };
  }
}
