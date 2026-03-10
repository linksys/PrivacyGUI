import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/usp_page/wifi_settings/views/components/wifi_network_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 1 — WiFi networks list.
///
/// Displays one [WifiNetworkCard] per SSID instance, showing band,
/// SSID name, security mode, channel, and enable status.
class UspWifiListTab extends ConsumerWidget {
  const UspWifiListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networks = ref.watch(
      uspWifiSettingsProvider.select((s) => s.value?.networks ?? []),
    );

    if (networks.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No WiFi networks found',
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
          AppText.bodySmall(
            'Your router is broadcasting on ${networks.where((n) => n.enabled).length} active network(s).',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.lg(),
          ...networks.map(
            (network) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: WifiNetworkCard(network: network),
            ),
          ),
        ],
      ),
    );
  }
}
