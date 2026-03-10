import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Card displaying a single WiFi network's status and key parameters.
class WifiNetworkCard extends StatelessWidget {
  final WifiNetworkUIModel network;
  final VoidCallback? onTap;

  const WifiNetworkCard({
    super.key,
    required this.network,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          AppGap.md(),
          _buildDetails(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        AppIcon.font(
          Icons.wifi,
          color: network.enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        AppGap.md(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelLarge(
                network.ssid.isNotEmpty ? network.ssid : '(No SSID)',
              ),
              AppGap.xs(),
              AppText.bodySmall(
                network.bandDisplayName,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        AppTag(
          label: network.enabled ? 'On' : 'Off',
          isSelected: network.enabled,
        ),
      ],
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        _DetailChip(
          icon: Icons.security,
          label: network.securityMode.isNotEmpty ? network.securityMode : 'None',
        ),
        _DetailChip(
          icon: Icons.router,
          label: 'Ch ${network.channelDisplay}',
        ),
        if (network.channelBandwidth.isNotEmpty)
          _DetailChip(
            icon: Icons.signal_cellular_alt,
            label: network.channelBandwidth,
          ),
        if (!network.ssidAdvertisementEnabled)
          _DetailChip(
            icon: Icons.visibility_off,
            label: 'Hidden',
            dimmed: true,
          ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dimmed;

  const _DetailChip({
    required this.icon,
    required this.label,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = dimmed
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon.font(icon, size: 14, color: color),
        AppGap.xs(),
        AppText.bodySmall(label, color: color),
      ],
    );
  }
}
