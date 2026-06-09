import 'package:flutter/material.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../components/_components.dart';

/// Component registry with Router-specific components registered.
///
/// This combines UI Kit standard components with router-specific ones.
class RouterComponentRegistry {
  RouterComponentRegistry._();

  /// Creates a new [ComponentRegistry] with all router components registered.
  static ComponentRegistry create() {
    final registry = ComponentRegistry();

    // Register UI Kit standard components
    UiKitCatalog.standardBuilders.forEach((name, builder) {
      registry.register(name, builder);
    });

    // Override AppCard to provide default spacing in Chat UI
    registry.register('AppCard', (context, props, {onAction, children}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: AppCard(
          onTap: props['onTap'] != null
              ? () => onAction?.call({'action': props['onTap']})
              : null,
          child: _buildFlexibleChild(children),
        ),
      );
    });

    // Register Router-specific components
    _registerRouterComponents(registry);

    return registry;
  }

  static Widget _buildFlexibleChild(List<Widget>? children) {
    if (children == null || children.isEmpty) {
      return const SizedBox();
    }
    // If there's only one child, return it directly to allow flexible layout (Row, etc.)
    if (children.length == 1) {
      return children.first;
    }
    // If multiple children, stack them vertically by default
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  static void _registerRouterComponents(ComponentRegistry registry) {
    // DeviceListView - Display connected devices
    registry.register('DeviceListView', (context, props, {onAction, children}) {
      final devices = props['devices'] as List? ?? [];
      return _DeviceListView(
        devices: devices.cast<Map<String, dynamic>>(),
        onAction: onAction,
      );
    });

    // NetworkStatusCard - Show network status summary
    registry.register('NetworkStatusCard', (context, props,
        {onAction, children}) {
      return _NetworkStatusCard(
        wanStatus: props['wanStatus'] as String? ?? 'Unknown',
        connectedDevices: props['connectedDevices'] as int? ?? 0,
        uploadSpeed: props['uploadSpeed'] as String?,
        downloadSpeed: props['downloadSpeed'] as String?,
      );
    });

    // WifiSettingsCard - Display WiFi information
    registry.register('WifiSettingsCard', (context, props,
        {onAction, children}) {
      return _WifiSettingsCard(
        ssid: props['ssid'] as String? ?? '',
        password: props['password'] as String?,
        securityMode: props['securityMode'] as String?,
        band: props['band'] as String?,
      );
    });

    // EthernetPortsCard - Display ethernet port status
    registry.register('EthernetPortsCard', (context, props,
        {onAction, children}) {
      final ports = props['ports'] as List? ?? [];
      return _EthernetPortsCard(
        ports: ports.cast<Map<String, dynamic>>(),
      );
    });

    // ConfirmationSheet - Confirmation dialog for dangerous operations
    registry.register('ConfirmationSheet', (context, props,
        {onAction, children}) {
      return _ConfirmationSheet(
        title: props['title'] as String? ?? 'Confirmation',
        message: props['message'] as String? ?? '',
        confirmLabel: props['confirmLabel'] as String? ?? 'Confirm',
        cancelLabel: props['cancelLabel'] as String? ?? 'Cancel',
        confirmAction: props['confirmAction'] as String?,
        onAction: onAction,
      );
    });

    // === New High-Level Components ===

    // LanInfoCard - Display LAN configuration
    registry.register('LanInfoCard', (context, props, {onAction, children}) {
      return _LanInfoCard(
        ipAddress: props['ipAddress'] as String? ?? '',
        subnetMask: props['subnetMask'] as String? ?? '',
        dhcpEnabled: props['dhcpEnabled'] as bool? ?? false,
        dhcpRange: props['dhcpRange'] as String?,
        dnsServers: props['dnsServers'] as String?,
        ipv6Enabled: props['ipv6Enabled'] as bool? ?? false,
        ipv6Addresses:
            (props['ipv6Addresses'] as List?)?.cast<String>() ?? const [],
      );
    });

    // DhcpCard - Display DHCP reservations and clients
    registry.register('DhcpCard', (context, props, {onAction, children}) {
      return _DhcpCard(
        reservations:
            (props['reservations'] as List?)?.cast<Map<String, dynamic>>() ??
                const [],
        clients: (props['clients'] as List?)?.cast<Map<String, dynamic>>() ??
            const [],
      );
    });

    // FirewallCard - Display firewall status
    registry.register('FirewallCard', (context, props, {onAction, children}) {
      return _FirewallCard(
        ipv4Enabled: props['ipv4Enabled'] as bool? ?? false,
        ipv6Enabled: props['ipv6Enabled'] as bool? ?? false,
        ruleCount: props['ruleCount'] as int? ?? 0,
        dmzEnabled: props['dmzEnabled'] as bool? ?? false,
        portForwardingCount: props['portForwardingCount'] as int? ?? 0,
      );
    });

    // PortForwardingCard - Display port forwarding rules
    registry.register('PortForwardingCard', (context, props,
        {onAction, children}) {
      return _PortForwardingCard(
        rules:
            (props['rules'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
      );
    });

    // SystemResourceCard - Display CPU, Memory, Uptime
    registry.register('SystemResourceCard', (context, props,
        {onAction, children}) {
      return _SystemResourceCard(
        cpuPercent: props['cpuPercent'] as int? ?? 0,
        memoryPercent: props['memoryPercent'] as int? ?? 0,
        uptime: props['uptime'] as String? ?? '',
      );
    });

    // =========================================================================
    // DATA SECTIONS — Composable data blocks
    // =========================================================================

    // SectionHeader - Section title with optional badge
    registry.register('SectionHeader', (context, props, {onAction, children}) {
      return SectionHeader(
        title: props['title'] as String? ?? '',
        badge: props['badge'] != null
            ? AppBadge(label: props['badge'] as String)
            : null,
      );
    });

    // AiInfoRow - Label-value row
    registry.register('AiInfoRow', (context, props, {onAction, children}) {
      return AiInfoRow(
        label: props['label'] as String? ?? '',
        value: props['value'] as String? ?? '',
      );
    });

    // WanSection - WAN status
    registry.register('WanSection', (context, props, {onAction, children}) {
      return WanSection(
        wanStatus: props['wanStatus'] as String? ?? 'Unknown',
        connectedDevices: props['connectedDevices'] as int?,
        wanIp: props['wanIp'] as String?,
        connectionType: props['connectionType'] as String?,
      );
    });

    // LanSection - LAN configuration
    registry.register('LanSection', (context, props, {onAction, children}) {
      return LanSection(
        ipAddress: props['ipAddress'] as String? ?? '',
        subnetMask: props['subnetMask'] as String? ?? '',
        dhcpEnabled: props['dhcpEnabled'] as bool?,
        dhcpRange: props['dhcpRange'] as String?,
        dnsServers: props['dnsServers'] as String?,
        ipv6Enabled: props['ipv6Enabled'] as bool?,
        ipv6Addresses: (props['ipv6Addresses'] as List?)?.cast<String>(),
      );
    });

    // WifiSection - WiFi settings
    registry.register('WifiSection', (context, props, {onAction, children}) {
      return WifiSection(
        ssid: props['ssid'] as String? ?? '',
        password: props['password'] as String?,
        securityMode: props['securityMode'] as String?,
        band: props['band'] as String?,
      );
    });

    // DevicesSection - Connected devices list
    registry.register('DevicesSection', (context, props, {onAction, children}) {
      return DevicesSection(
        devices:
            (props['devices'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        maxCount: props['maxCount'] as int?,
      );
    });

    // SystemSection - CPU, Memory, Uptime
    registry.register('SystemSection', (context, props, {onAction, children}) {
      return SystemSection(
        cpuPercent: props['cpuPercent'] as int? ?? 0,
        memoryPercent: props['memoryPercent'] as int? ?? 0,
        uptime: props['uptime'] as String?,
      );
    });

    // FirewallSection - Firewall status
    registry.register('FirewallSection', (context, props,
        {onAction, children}) {
      return FirewallSection(
        enabled: props['enabled'] as bool? ?? false,
        ipv4Enabled: props['ipv4Enabled'] as bool?,
        ipv6Enabled: props['ipv6Enabled'] as bool?,
        ruleCount: props['ruleCount'] as int?,
        dmzEnabled: props['dmzEnabled'] as bool?,
      );
    });

    // EthernetSection - Ethernet ports
    registry.register('EthernetSection', (context, props,
        {onAction, children}) {
      return EthernetSection(
        ports: (props['ports'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      );
    });

    // DhcpSection - DHCP data
    registry.register('DhcpSection', (context, props, {onAction, children}) {
      return DhcpSection(
        reservations:
            (props['reservations'] as List?)?.cast<Map<String, dynamic>>(),
        clients: (props['clients'] as List?)?.cast<Map<String, dynamic>>(),
      );
    });

    // PortForwardingSection - Port forwarding rules
    registry.register('PortForwardingSection', (context, props,
        {onAction, children}) {
      return PortForwardingSection(
        rules: (props['rules'] as List?)?.cast<Map<String, dynamic>>(),
      );
    });

    // =========================================================================
    // ADVANCED SECTIONS
    // =========================================================================

    // TopologySection - Network topology visualization
    registry.register('TopologySection', (context, props,
        {onAction, children}) {
      return TopologySection(
        gatewayName: props['gatewayName'] as String? ?? 'Router',
        gatewayModel: props['gatewayModel'] as String?,
        extenders: (props['extenders'] as List?)?.cast<Map<String, dynamic>>(),
        clients: (props['clients'] as List?)?.cast<Map<String, dynamic>>(),
        maxClients: props['maxClients'] as int? ?? 8,
      );
    });

    // DiagnosticsSection - Ping/Traceroute/DNS results
    registry.register('DiagnosticsSection', (context, props,
        {onAction, children}) {
      return DiagnosticsSection(
        pingResult: props['pingResult'] as Map<String, dynamic>?,
        tracerouteResult: props['tracerouteResult'] as Map<String, dynamic>?,
        dnsResult: props['dnsResult'] as Map<String, dynamic>?,
      );
    });

    // =========================================================================
    // CHART SECTIONS
    // =========================================================================

    // LineChartSection - Time-series data
    registry.register('LineChartSection', (context, props,
        {onAction, children}) {
      return LineChartSection(
        series: (props['series'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        height: (props['height'] as num?)?.toDouble() ?? 200,
        showGrid: props['showGrid'] as bool? ?? true,
        showDots: props['showDots'] as bool? ?? true,
        filled: props['filled'] as bool? ?? false,
        yMin: (props['yMin'] as num?)?.toDouble(),
        yMax: (props['yMax'] as num?)?.toDouble(),
        yUnit: props['yUnit'] as String?,
      );
    });

    // BarChartSection - Categorical data
    registry.register('BarChartSection', (context, props,
        {onAction, children}) {
      return BarChartSection(
        series: (props['series'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        xLabels: (props['xLabels'] as List?)?.cast<String>(),
        height: (props['height'] as num?)?.toDouble() ?? 200,
        stacked: props['stacked'] as bool? ?? false,
        horizontal: props['horizontal'] as bool? ?? false,
      );
    });

    // PieChartSection - Proportional data
    registry.register('PieChartSection', (context, props,
        {onAction, children}) {
      return PieChartSection(
        sections:
            (props['sections'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        height: (props['height'] as num?)?.toDouble() ?? 200,
        donut: props['donut'] as bool? ?? false,
        showLabels: props['showLabels'] as bool? ?? true,
      );
    });
  }
}

/// Widget to display a list of connected devices.
class _DeviceListView extends StatelessWidget {
  final List<Map<String, dynamic>> devices;
  final ComponentActionCallback? onAction;

  const _DeviceListView({
    required this.devices,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return AppSurface(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: AppText.body('No connected devices found'),
          ),
        ),
      );
    }

    return AppSurface(
      child: Column(
        children: devices.map((device) {
          final name = device['name'] as String? ?? 'Unknown Device';
          final ip = device['ip'] as String? ?? '';
          final mac = device['mac'] as String? ?? '';
          final connectionType = device['connectionType'] as String? ?? '';

          return AppListTile(
            leading: Icon(_getDeviceIcon(name)),
            title: AppText.body(name),
            subtitle: AppText.caption(ip.isNotEmpty ? ip : mac),
            trailing: connectionType.isNotEmpty
                ? AppBadge(label: connectionType)
                : null,
            onTap: () {
              onAction?.call({
                'action': 'deviceSelected',
                'device': device,
              });
            },
          );
        }).toList(),
      ),
    );
  }

  IconData _getDeviceIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('iphone') || lowerName.contains('android')) {
      return Icons.phone_android;
    } else if (lowerName.contains('mac') ||
        lowerName.contains('pc') ||
        lowerName.contains('laptop')) {
      return Icons.laptop;
    } else if (lowerName.contains('tv') || lowerName.contains('television')) {
      return Icons.tv;
    } else if (lowerName.contains('tablet') || lowerName.contains('ipad')) {
      return Icons.tablet;
    }
    return Icons.devices;
  }
}

/// Widget to display network status summary.
class _NetworkStatusCard extends StatelessWidget {
  final String wanStatus;
  final int connectedDevices;
  final String? uploadSpeed;
  final String? downloadSpeed;

  const _NetworkStatusCard({
    required this.wanStatus,
    required this.connectedDevices,
    this.uploadSpeed,
    this.downloadSpeed,
  });

  bool _isConnected(String status) {
    final lower = status.toLowerCase();
    return lower == 'connected' ||
        lower == 'online' ||
        lower == 'connected' ||
        lower.contains('connect');
  }

  bool _hasValidSpeed(String? speed) {
    if (speed == null || speed.isEmpty) return false;
    final lower = speed.toLowerCase();
    return lower != 'n/a' && lower != 'unknown' && lower != '-';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Add padding at the bottom to ensure spacing between cards in the list
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isConnected(wanStatus) ? Icons.check_circle : Icons.error,
                    color: _isConnected(wanStatus)
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  AppText.headline('Network Status'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('WAN Status', wanStatus),
              _buildInfoRow('Connected Devices', '$connectedDevices'),
              if (_hasValidSpeed(uploadSpeed))
                _buildInfoRow('Upload Speed', uploadSpeed!),
              if (_hasValidSpeed(downloadSpeed))
                _buildInfoRow('Download Speed', downloadSpeed!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(label),
          AppText.body(value),
        ],
      ),
    );
  }
}

/// Widget to display WiFi settings.
class _WifiSettingsCard extends StatelessWidget {
  final String ssid;
  final String? password;
  final String? securityMode;
  final String? band;

  const _WifiSettingsCard({
    required this.ssid,
    this.password,
    this.securityMode,
    this.band,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wifi),
                  const SizedBox(width: 8),
                  AppText.headline('WiFi Settings'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Network Name (SSID)', ssid),
              if (password != null) _buildInfoRow('Password', password!),
              if (securityMode != null)
                _buildInfoRow('Security Mode', securityMode!),
              if (band != null) _buildInfoRow('Band', band!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(label),
          AppText.body(value),
        ],
      ),
    );
  }
}

/// Widget to display ethernet port status.
class _EthernetPortsCard extends StatelessWidget {
  final List<Map<String, dynamic>> ports;

  const _EthernetPortsCard({required this.ports});

  @override
  Widget build(BuildContext context) {
    // Note: AppCard override automatically adds padding and internal Column/SizedBox logic.
    // However, since we are returning the content for the wrapper to use,
    // we should use AppCard here and let the wrapper wrap it?
    // Wait, the wrapper logic in registry wraps the *result* of this function?
    // Reference registry logic:
    // registry.register('AppCard', ... return Padding(child: AppCard(...)))
    // Here we are returning `_EthernetPortsCard`, which is a Widget.
    // The registry for 'EthernetPortsCard' was:
    // returning _EthernetPortsCard(...)
    // So _EthernetPortsCard itself should return an AppCard.
    // And since our AppCard override is only for 'AppCard' key, using AppCard class
    // directly here will NOT get the wrapper (Padding) automatically unless we replicate it
    // or if the component system uses the registry recursively.
    // Actually, calling `AppCard(...)` directly creates the widget. The registry override only affects when A2UI asks for "AppCard".
    // So we should manually add Padding if we want consistency, OR rely on the fact that
    // this component produces a Card.
    // Let's manually add the Padding here to match the global style we established.

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings_ethernet),
                  const SizedBox(width: 8),
                  AppText.headline('Ethernet Ports'),
                ],
              ),
              const SizedBox(height: 16),
              if (ports.isEmpty)
                AppText.body('No port information available')
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children:
                      ports.map((port) => _buildPortItem(theme, port)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortItem(ThemeData theme, Map<String, dynamic> port) {
    final label = port['label'] as String? ?? '?';
    final status = port['status'] as String? ?? 'Disconnected';
    final speed = port['speed'] as String?;

    // Check connection status loosely
    final isConnected = status.toLowerCase() == 'connected' ||
        status.toLowerCase() == 'online' ||
        status.toLowerCase() == 'up' ||
        status.toLowerCase() == 'connected';

    final color = isConnected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.2);

    return Column(
      children: [
        Container(
          width: 48,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isConnected ? 0.1 : 0.05),
            border: Border.all(
              color: color,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              Icons.lan,
              color: color,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppText.body(label), // e.g. WAN, 1, 2
        if (speed != null && isConnected) ...[
          const SizedBox(height: 4),
          AppText.caption(speed,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ],
      ],
    );
  }
}

/// Confirmation dialog for dangerous operations.
class _ConfirmationSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final String? confirmAction;
  final ComponentActionCallback? onAction;

  const _ConfirmationSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.confirmAction,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            AppText.headline(title),
            const SizedBox(height: 8),
            AppText.body(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    variant: SurfaceVariant.base,
                    onTap: () {
                      onAction?.call({
                        'action': 'cancelled',
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: SurfaceVariant.highlight,
                    onTap: () {
                      onAction?.call({
                        'action': confirmAction ?? 'confirmed',
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// LanInfoCard — LAN configuration display
// =============================================================================

class _LanInfoCard extends StatelessWidget {
  final String ipAddress;
  final String subnetMask;
  final bool dhcpEnabled;
  final String? dhcpRange;
  final String? dnsServers;
  final bool ipv6Enabled;
  final List<String> ipv6Addresses;

  const _LanInfoCard({
    required this.ipAddress,
    required this.subnetMask,
    required this.dhcpEnabled,
    this.dhcpRange,
    this.dnsServers,
    this.ipv6Enabled = false,
    this.ipv6Addresses = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lan_outlined, size: 24),
                const SizedBox(width: 8),
                AppText.headline('LAN Settings'),
              ],
            ),
            AppGap.md(),
            _buildInfoRow('IP Address', ipAddress),
            _buildInfoRow('Subnet Mask', subnetMask),
            _buildInfoRow('DHCP Server', dhcpEnabled ? 'Enabled' : 'Disabled'),
            if (dhcpRange != null) _buildInfoRow('DHCP Range', dhcpRange!),
            if (dnsServers != null) _buildInfoRow('DNS Servers', dnsServers!),
            if (ipv6Enabled) ...[
              AppGap.sm(),
              _buildInfoRow('IPv6', 'Enabled'),
              ...ipv6Addresses
                  .map((addr) => _buildInfoRow('IPv6 Address', addr)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(label),
          AppText.body(value),
        ],
      ),
    );
  }
}

// =============================================================================
// DhcpCard — DHCP reservations and clients display
// =============================================================================

class _DhcpCard extends StatelessWidget {
  final List<Map<String, dynamic>> reservations;
  final List<Map<String, dynamic>> clients;

  const _DhcpCard({
    required this.reservations,
    required this.clients,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.device_hub, size: 24),
                const SizedBox(width: 8),
                AppText.headline('DHCP'),
              ],
            ),
            AppGap.md(),
            if (reservations.isNotEmpty) ...[
              AppText.body('Reservations (${reservations.length})'),
              AppGap.sm(),
              ...reservations.map(_buildReservationTile),
            ],
            if (reservations.isNotEmpty && clients.isNotEmpty) AppGap.md(),
            if (clients.isNotEmpty) ...[
              AppText.body('Active Clients (${clients.length})'),
              AppGap.sm(),
              ...clients.map(_buildClientTile),
            ],
            if (reservations.isEmpty && clients.isEmpty)
              AppText.body('No DHCP data available'),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationTile(Map<String, dynamic> reservation) {
    return AppListTile(
      title: AppText.body(reservation['hostname'] as String? ?? 'Unknown'),
      subtitle: AppText.caption(
        '${reservation['mac'] ?? ''} → ${reservation['ip'] ?? ''}',
      ),
      leading: const Icon(Icons.bookmark, size: 20),
    );
  }

  Widget _buildClientTile(Map<String, dynamic> client) {
    return AppListTile(
      title: AppText.body(client['hostname'] as String? ?? 'Unknown'),
      subtitle: AppText.caption(
        '${client['mac'] ?? ''} → ${client['ip'] ?? ''}',
      ),
      leading: const Icon(Icons.devices, size: 20),
    );
  }
}

// =============================================================================
// FirewallCard — Firewall status display
// =============================================================================

class _FirewallCard extends StatelessWidget {
  final bool ipv4Enabled;
  final bool ipv6Enabled;
  final int ruleCount;
  final bool dmzEnabled;
  final int portForwardingCount;

  const _FirewallCard({
    required this.ipv4Enabled,
    required this.ipv6Enabled,
    required this.ruleCount,
    required this.dmzEnabled,
    required this.portForwardingCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overallEnabled = ipv4Enabled || ipv6Enabled;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 24,
                  color: overallEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                AppText.headline('Firewall'),
                const Spacer(),
                AppBadge(label: overallEnabled ? 'Active' : 'Disabled'),
              ],
            ),
            AppGap.md(),
            _buildStatusRow('IPv4 Firewall', ipv4Enabled),
            _buildStatusRow('IPv6 Firewall', ipv6Enabled),
            _buildInfoRow('Active Rules', '$ruleCount'),
            _buildStatusRow('DMZ', dmzEnabled),
            _buildInfoRow('Port Forwarding Rules', '$portForwardingCount'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(label),
          AppBadge(label: enabled ? 'On' : 'Off'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(label),
          AppText.body(value),
        ],
      ),
    );
  }
}

// =============================================================================
// PortForwardingCard — Port forwarding rules display
// =============================================================================

class _PortForwardingCard extends StatelessWidget {
  final List<Map<String, dynamic>> rules;

  const _PortForwardingCard({
    required this.rules,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, size: 24),
                const SizedBox(width: 8),
                AppText.headline('Port Forwarding'),
                const Spacer(),
                AppBadge(label: '${rules.length} rules'),
              ],
            ),
            AppGap.md(),
            if (rules.isEmpty)
              AppText.body('No port forwarding rules configured')
            else
              ...rules.map(_buildRuleTile),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleTile(Map<String, dynamic> rule) {
    final enabled = rule['enabled'] as bool? ?? false;
    final description = rule['description'] as String? ?? 'Unnamed rule';
    final port = rule['port'] ?? rule['externalPort'] ?? '';
    final protocol = rule['protocol'] as String? ?? 'TCP';
    final internalIp = rule['internalIp'] as String? ?? '';

    return AppListTile(
      title: AppText.body(description),
      subtitle: AppText.caption(
        'Port $port ($protocol) → $internalIp',
      ),
      leading: Icon(
        enabled ? Icons.check_circle : Icons.cancel,
        size: 20,
        color: enabled ? Colors.green : Colors.grey,
      ),
    );
  }
}

// =============================================================================
// SystemResourceCard — CPU, Memory, Uptime display
// =============================================================================

class _SystemResourceCard extends StatelessWidget {
  final int cpuPercent;
  final int memoryPercent;
  final String uptime;

  const _SystemResourceCard({
    required this.cpuPercent,
    required this.memoryPercent,
    required this.uptime,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory, size: 24),
                const SizedBox(width: 8),
                AppText.headline('System Resources'),
              ],
            ),
            AppGap.md(),
            Row(
              children: [
                Expanded(
                  child: _buildGauge('CPU', cpuPercent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGauge('Memory', memoryPercent),
                ),
              ],
            ),
            AppGap.md(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.body('Uptime'),
                AppText.body(uptime),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGauge(String label, int percent) {
    return Column(
      children: [
        AppGauge(
          value: percent / 100.0,
          size: 80,
          centerBuilder: (context, value) => AppText.headline('$percent%'),
        ),
        const SizedBox(height: 8),
        AppText.body(label),
      ],
    );
  }
}
