import 'package:flutter/material.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
  }
}

/// Widget to display a list of connected devices.
class _DeviceListView extends StatelessWidget {
  final List<Map<String, dynamic>> devices;
  final GenUiActionCallback? onAction;

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
              if (uploadSpeed != null)
                _buildInfoRow('Upload Speed', uploadSpeed!),
              if (downloadSpeed != null)
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
  final GenUiActionCallback? onAction;

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
