import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A WiFi network entry aggregated by SSID across all bands.
class _WifiNetworkEntry {
  final String ssidName;
  final List<String> bands;
  final bool isEnabled;
  final String securityMode;
  final bool isGuest;
  final int clientCount;

  const _WifiNetworkEntry({
    required this.ssidName,
    required this.bands,
    required this.isEnabled,
    required this.securityMode,
    required this.isGuest,
    required this.clientCount,
  });
}

/// Dashboard card displaying WiFi networks organized by SSID.
///
/// Design: B1 — SSID Cards with Band Badges
/// - Each SSID is shown as a row with band badges
/// - QR button for sharing credentials
/// - Toggle for enable/disable (future)
class UspWifiNetworksCard extends ConsumerWidget {
  final WifiData? wifiData;
  final void Function(String ssid)? onShareTap;

  const UspWifiNetworksCard({
    super.key,
    this.wifiData,
    this.onShareTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = wifiData ?? ref.watch(wifiDataProvider).valueOrNull;
    if (data == null) return const CardSkeleton.list(rows: 3);

    final isLoading = ref.watch(uspMutationLoadingProvider) == 'wifi_network';
    final networks = _aggregateBySSID(
      data.radioModels,
      data.connectionDetailMap,
    );
    // The main networks, guests excluded — see `popupValue` below.
    final primary = networks.where((n) => !n.isGuest).toList();

    return DashboardCardTemplate(
      title: loc(context).wifiNetworks,
      // The main network's name, which is what a user looks at this card to
      // check — a count of SSIDs says nothing about which network is which.
      // Falls back to the count when there is no main network to name, because
      // an empty tile is the one thing worse than a number.
      popupValue:
          primary.isEmpty ? '${networks.length}' : primary.first.ssidName,
      detailRoute: RouteNamed.uspWifiSettings,
      itemCount: networks.length,
      detailLabel: loc(context).viewAll,
      content: networks.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                for (var i = 0; i < networks.length; i++) ...[
                  _buildNetworkRow(context, ref, networks[i], isLoading),
                  if (i < networks.length - 1) AppGap.sm(),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AppText.bodyMedium(
          'No WiFi networks configured',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildNetworkRow(
    BuildContext context,
    WidgetRef ref,
    _WifiNetworkEntry network,
    bool isLoading,
  ) {
    return NetworkRow(
      ssidName: network.ssidName,
      bands: network.bands,
      isGuest: network.isGuest,
      isEnabled: network.isEnabled,
      clientCount: network.clientCount,
      isLoading: isLoading,
      onChanged: isLoading
          ? null
          : (value) => _confirmToggleNetwork(context, ref, network, value),
      onShareTap:
          onShareTap != null ? () => onShareTap!(network.ssidName) : null,
    );
  }

  Future<void> _confirmToggleNetwork(
    BuildContext context,
    WidgetRef ref,
    _WifiNetworkEntry network,
    bool enable,
  ) async {
    final action = enable ? 'Enable' : 'Disable';
    final confirmed = await showSimpleAppDialog<bool>(
      context,
      title: loc(context).editWifiNetworkAction(action),
      content: AppText.bodyMedium(
        '$action "${network.ssidName}" on all bands?',
      ),
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () => context.pop(),
        ),
        AppButton.primary(
          label: action,
          onTap: () => context.pop(true),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'wifi_network',
      mutation: () => ref
          .read(uspWifiSettingsProvider.notifier)
          .toggleSsidsByName(network.ssidName, enable),
    );
  }

  /// Aggregate access points by SSID across all radios.
  List<_WifiNetworkEntry> _aggregateBySSID(
    List<WifiRadioUIModel> radios,
    Map<String, ClientConnectionDetail> connectionDetailMap,
  ) {
    // Count clients per SSID
    final clientCountBySSID = <String, int>{};
    for (final detail in connectionDetailMap.values) {
      if (detail.ssidName.isNotEmpty) {
        clientCountBySSID[detail.ssidName] =
            (clientCountBySSID[detail.ssidName] ?? 0) + 1;
      }
    }

    final ssidMap = <String, _WifiNetworkEntry>{};

    for (final radio in radios) {
      // Include disabled radios — user can toggle them
      for (final ap in radio.accessPoints) {
        final ssid = ap.ssidName;
        if (ssid.isEmpty) continue;

        final existing = ssidMap[ssid];
        // Network is enabled based on SSID.enable (matches toggle mutation)
        final isEnabled = ap.enable;

        if (existing != null) {
          // Add band to existing entry (keep isGuest from first occurrence)
          ssidMap[ssid] = _WifiNetworkEntry(
            ssidName: ssid,
            bands: [...existing.bands, radio.band],
            isEnabled: existing.isEnabled || isEnabled,
            securityMode: ap.securityMode,
            isGuest: existing.isGuest,
            clientCount: existing.clientCount,
          );
        } else {
          // Create new entry — use ap.isGuest from the UI model
          ssidMap[ssid] = _WifiNetworkEntry(
            ssidName: ssid,
            bands: [radio.band],
            isEnabled: isEnabled,
            securityMode: ap.securityMode,
            isGuest: ap.isGuest,
            clientCount: clientCountBySSID[ssid] ?? 0,
          );
        }
      }
    }

    // Sort: non-guest first, then alphabetically
    final networks = ssidMap.values.toList();
    networks.sort((a, b) {
      if (a.isGuest != b.isGuest) return a.isGuest ? 1 : -1;
      return a.ssidName.compareTo(b.ssidName);
    });

    return networks;
  }
}
