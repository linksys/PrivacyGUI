import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
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

    final networks = _aggregateBySSID(
      data.radioModels,
      data.connectionDetailMap,
    );

    return DashboardCardTemplate(
      title: 'WiFi Networks',
      detailRoute: RouteNamed.uspWifiSettings,
      itemCount: networks.length,
      detailLabel: 'View all',
      content: networks.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                for (var i = 0; i < networks.length; i++) ...[
                  _buildNetworkRow(context, ref, networks[i]),
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
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'wifi_network';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(
          color: network.isGuest
              ? scheme.secondary.withValues(alpha: 0.3)
              : scheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Network info
          Expanded(
            child: Opacity(
              opacity: network.isEnabled ? 1.0 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SSID name with guest indicator
                  Row(
                    children: [
                      Flexible(
                        child: AppText.bodyLarge(
                          network.ssidName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (network.isGuest) ...[
                        AppGap.sm(),
                        _buildGuestBadge(context),
                      ],
                    ],
                  ),
                  AppGap.xs(),
                  // Band badges and client count
                  Row(
                    children: [
                      ...network.bands.map((band) => Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.xs),
                            child: _buildBandBadge(context, band),
                          )),
                      AppGap.sm(),
                      Icon(
                        Icons.devices,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      AppGap.xxs(),
                      AppText.labelSmall(
                        '${network.clientCount}',
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // QR / Share button
          if (network.isEnabled && onShareTap != null) ...[
            _buildShareButton(context, network.ssidName),
            AppGap.sm(),
          ],
          // Enable/Disable toggle
          AppSwitch(
            value: network.isEnabled,
            onChanged: isLoading
                ? null
                : (value) =>
                    _confirmToggleNetwork(context, ref, network, value),
          ),
        ],
      ),
    );
  }

  Widget _buildBandBadge(BuildContext context, String band) {
    final scheme = Theme.of(context).colorScheme;

    final (color, label) = switch (band.toLowerCase()) {
      String b when b.contains('2.4') => (const Color(0xFF4A9EFF), '2.4G'),
      String b when b.contains('5') && !b.contains('6') => (
          const Color(0xFF4ADE80),
          '5G'
        ),
      String b when b.contains('6') => (const Color(0xFFA78BFA), '6G'),
      _ => (scheme.outline, band),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: AppText.labelSmall(
        label,
        color: color,
      ),
    );
  }

  Widget _buildGuestBadge(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: AppText.labelSmall(
        'Guest',
        color: scheme.secondary,
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, String ssid) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onShareTap?.call(ssid),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
          ),
          child: Icon(
            Icons.qr_code_2,
            size: 24,
            color: scheme.onSurface,
          ),
        ),
      ),
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
      title: '$action WiFi Network',
      content: AppText.bodyMedium(
        '$action "${network.ssidName}" on all bands?',
      ),
      actions: [
        AppButton.text(
          label: 'Cancel',
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
