import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 3 — MAC Filtering.
///
/// Shows the standard TR-181 [MACAddressControlEnabled] toggle per AccessPoint.
/// This enables the allow-list mode (only listed MAC addresses may connect).
///
/// Note: Linksys-specific deny-list mode requires vendor extensions and is
/// not available in this initial version.
class UspWifiMacFilteringTab extends ConsumerWidget {
  const UspWifiMacFilteringTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networks = ref.watch(
      uspWifiSettingsProvider.select((s) => s.value?.networks ?? []),
    );

    // Only show networks that have an AccessPoint instance path
    final networksWithAp =
        networks.where((n) => n.accessPointInstancePath != null).toList();

    if (networksWithAp.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No WiFi networks available',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon.font(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                AppGap.md(),
                Expanded(
                  child: AppText.bodySmall(
                    'MAC Address Control restricts network access to approved '
                    'devices only (allow-list mode). Deny-list management '
                    'requires additional configuration.',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppGap.lg(),
          ...networksWithAp.map(
            (network) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _MacFilterToggleCard(network: network),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacFilterToggleCard extends ConsumerWidget {
  final WifiNetworkUIModel network;

  const _MacFilterToggleCard({required this.network});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(uspWifiSettingsProvider.notifier);

    return AppCard(
      child: Row(
        children: [
          AppIcon.font(
            Icons.filter_list,
            color: Theme.of(context).colorScheme.primary,
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
          AppSwitch(
            value: network.macAddressControlEnabled,
            onChanged: network.accessPointInstancePath != null
                ? (value) => notifier.toggleMacAddressControl(
                      network.accessPointInstancePath!,
                      value,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}
