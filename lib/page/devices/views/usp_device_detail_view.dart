import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/core/utils/device_classifier.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/devices/providers/device_detail_provider.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspDeviceDetailView extends ConsumerStatefulWidget {
  final String mac;

  const UspDeviceDetailView({super.key, required this.mac});

  @override
  ConsumerState<UspDeviceDetailView> createState() =>
      _UspDeviceDetailViewState();
}

class _UspDeviceDetailViewState extends ConsumerState<UspDeviceDetailView> {
  bool _ipv6Expanded = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(uspDeviceDetailProvider(widget.mac));
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'dhcp';

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'Device Detail',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspDeviceList,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (detail.device == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.titleMedium('Device not found'),
                AppGap.lg(),
                AppButton.text(
                  label: 'Back to Devices',
                  onTap: () =>
                      context.navigateBack(fallback: RouteNamed.uspDeviceList),
                ),
              ],
            ),
          );
        }

        final device = detail.device!;
        return AppResponsiveLayout(
          mobile: (_) =>
              _buildMobileLayout(context, ref, device, detail, isLoading),
          tablet: (_) =>
              _buildMobileLayout(context, ref, device, detail, isLoading),
          desktop: (_) =>
              _buildDesktopLayout(context, ref, device, detail, isLoading),
        );
      },
    );
  }

  // ===========================================================================
  // Layouts
  // ===========================================================================

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref,
      DeviceUIModel device, DeviceDetailState detail, bool isLoading) {
    return Column(
      children: [
        _buildDeviceIdentityCard(context, device),
        AppGap.lg(),
        _buildConnectionStatusCard(context, device),
        AppGap.lg(),
        if (device.isWifi) ...[
          _buildWifiDetailsCard(context, device),
          AppGap.lg(),
        ],
        _buildDhcpCard(context, ref, device, detail, isLoading),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref,
      DeviceUIModel device, DeviceDetailState detail, bool isLoading) {
    return Column(
      children: [
        // Row 1: Identity + Connection Status
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: context.colWidth(6),
                child: _buildDeviceIdentityCard(context, device),
              ),
              AppGap.gutter(),
              SizedBox(
                width: context.colWidth(6),
                child: _buildConnectionStatusCard(context, device),
              ),
            ],
          ),
        ),
        AppGap.gutter(),
        // Row 2: WiFi Details + DHCP
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: context.colWidth(6),
                child: device.isWifi
                    ? _buildWifiDetailsCard(context, device)
                    : _buildNetworkAddressesCard(context, device),
              ),
              AppGap.gutter(),
              SizedBox(
                width: context.colWidth(6),
                child: _buildDhcpCard(context, ref, device, detail, isLoading),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Device Identity Card
  // ===========================================================================

  Widget _buildDeviceIdentityCard(BuildContext context, DeviceUIModel device) {
    final classification = DeviceClassifier.classifyWithConfidence(
      hostname: device.hostName,
      mac: device.mac,
    );
    final vendor = OuiLookup.getVendorOrPrivate(device.mac);
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category icon and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  _getCategoryIcon(classification.category),
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              AppGap.md(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleLarge(device.displayName),
                    AppGap.xxs(),
                    AppText.labelMedium(
                      classification.category.displayName,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context, device.isActive),
            ],
          ),
          AppGap.xl(),
          // Vendor info
          if (vendor != null) ...[
            _buildInfoTile(
              context,
              icon: Icons.business,
              label: 'Manufacturer',
              value: vendor,
            ),
            AppGap.md(),
          ],
          // MAC Address with copy
          _buildCopyableTile(
            context,
            icon: Icons.memory,
            label: 'MAC Address',
            value: device.mac,
          ),
          AppGap.md(),
          // Hostname if different from display name
          if (device.hostName.isNotEmpty &&
              device.hostName != device.displayName) ...[
            _buildInfoTile(
              context,
              icon: Icons.dns,
              label: 'Hostname',
              value: device.hostName,
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Connection Status Card
  // ===========================================================================

  Widget _buildConnectionStatusCard(BuildContext context, DeviceUIModel device) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                device.isWifi ? Icons.wifi : Icons.settings_ethernet,
                size: 20,
                color: colorScheme.primary,
              ),
              AppGap.sm(),
              AppText.titleMedium(
                device.isWifi ? 'WiFi Connection' : 'Wired Connection',
              ),
            ],
          ),
          AppGap.xl(),
          // IP Address
          _buildCopyableTile(
            context,
            icon: Icons.language,
            label: 'IP Address',
            value: device.ip,
          ),
          // IPv6 Addresses
          if (device.ipv6Addresses.isNotEmpty) ...[
            AppGap.md(),
            _buildIpv6Section(context, device.ipv6Addresses),
          ],
          // Connected Node
          if (device.parentNodeName != null) ...[
            AppGap.md(),
            _buildInfoTile(
              context,
              icon: Icons.router,
              label: 'Connected to',
              value: device.parentNodeName!,
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // WiFi Details Card
  // ===========================================================================

  Widget _buildWifiDetailsCard(BuildContext context, DeviceUIModel device) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.signal_wifi_4_bar, size: 20, color: colorScheme.primary),
              AppGap.sm(),
              AppText.titleMedium('Signal & Speed'),
            ],
          ),
          AppGap.xl(),
          // Signal Strength
          if (device.signalStrength != null) ...[
            _buildSignalSection(context, device),
            AppGap.lg(),
          ],
          // Speed Cards Row
          if (device.downlinkRate != null || device.uplinkRate != null)
            _buildSpeedCards(context, device),
          // Band and SSID
          if (device.band != null || device.ssidName != null) ...[
            AppGap.lg(),
            Row(
              children: [
                if (device.band != null)
                  Expanded(
                    child: _buildCompactInfoTile(
                      context,
                      icon: Icons.wifi_channel,
                      label: 'Band',
                      value: device.band!,
                    ),
                  ),
                if (device.band != null && device.ssidName != null)
                  AppGap.md(),
                if (device.ssidName != null)
                  Expanded(
                    child: _buildCompactInfoTile(
                      context,
                      icon: Icons.wifi,
                      label: 'Network',
                      value: device.ssidName!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignalSection(BuildContext context, DeviceUIModel device) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          UspSignalStrengthIndicator(
            rssi: device.signalStrength!,
            maxBarHeight: 24,
            barWidth: 6,
            barSpacing: 3,
            showLabel: false,
          ),
          AppGap.lg(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium('${device.signalStrength} dBm'),
                AppText.labelSmall(
                  _getSignalQualityText(device.signalLevel),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedCards(BuildContext context, DeviceUIModel device) {
    return Row(
      children: [
        if (device.downlinkRate != null)
          Expanded(
            child: _SpeedCard(
              icon: Icons.arrow_downward,
              label: 'Download',
              speedBps: device.downlinkRate!,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        if (device.downlinkRate != null && device.uplinkRate != null)
          AppGap.md(),
        if (device.uplinkRate != null)
          Expanded(
            child: _SpeedCard(
              icon: Icons.arrow_upward,
              label: 'Upload',
              speedBps: device.uplinkRate!,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // Network Addresses Card (for Ethernet devices on desktop)
  // ===========================================================================

  Widget _buildNetworkAddressesCard(BuildContext context, DeviceUIModel device) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cable,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              AppGap.sm(),
              AppText.titleMedium('Network Details'),
            ],
          ),
          AppGap.xl(),
          _buildInfoTile(
            context,
            icon: Icons.settings_ethernet,
            label: 'Connection Type',
            value: 'Ethernet (Wired)',
          ),
          if (device.parentNodeName != null) ...[
            AppGap.md(),
            _buildInfoTile(
              context,
              icon: Icons.router,
              label: 'Connected to',
              value: device.parentNodeName!,
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // DHCP Reservation Card
  // ===========================================================================

  Widget _buildDhcpCard(BuildContext context, WidgetRef ref,
      DeviceUIModel device, DeviceDetailState detail, bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark, size: 20, color: colorScheme.primary),
              AppGap.sm(),
              AppText.titleMedium('DHCP Reservation'),
            ],
          ),
          AppGap.xl(),
          if (detail.hasReservation) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  AppGap.sm(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelMedium('Reserved'),
                        AppText.bodyMedium(detail.reservation!.ip),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppGap.lg(),
            AppButton.primaryOutline(
              label: 'Release Reservation',
              isLoading: isLoading,
              onTap: isLoading
                  ? null
                  : () => _releaseReservation(context, ref, detail),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  AppGap.sm(),
                  Expanded(
                    child: AppText.bodyMedium(
                      'No reservation. IP may change on reconnect.',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppGap.lg(),
            AppButton.primary(
              label: 'Reserve IP Address',
              isLoading: isLoading,
              onTap: isLoading ? null : () => _reserveIp(context, ref, device),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // IPv6 Section
  // ===========================================================================

  Widget _buildIpv6Section(BuildContext context, List<String> addresses) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayCount = _ipv6Expanded ? addresses.length : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.language, size: 16, color: colorScheme.onSurfaceVariant),
        AppGap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppText.labelSmall(
                    'IPv6 Address${addresses.length > 1 ? 'es' : ''}',
                    color: colorScheme.onSurfaceVariant,
                  ),
                  if (addresses.length > 1) ...[
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() => _ipv6Expanded = !_ipv6Expanded),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText.labelSmall(
                              _ipv6Expanded
                                  ? 'Show less'
                                  : '+${addresses.length - 1} more',
                              color: colorScheme.primary,
                            ),
                            Icon(
                              _ipv6Expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              ...addresses.take(displayCount).map(
                    (addr) => Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: _buildCopyableText(context, addr),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Helper Widgets
  // ===========================================================================

  Widget _buildStatusBadge(BuildContext context, bool isActive) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UspStatusDot(isActive: isActive, size: 8),
          AppGap.xs(),
          AppText.labelMedium(
            isActive ? 'Online' : 'Offline',
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        AppGap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
              AppText.bodyMedium(value),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
                AppText.bodyMedium(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        AppGap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelSmall(label, color: colorScheme.onSurfaceVariant),
              _buildCopyableText(context, value),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableText(BuildContext context, String text) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: $text'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: AppText.bodyMedium(text)),
          AppGap.xs(),
          Icon(
            Icons.copy,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(DeviceCategory category) {
    return switch (category) {
      DeviceCategory.phone => Icons.smartphone,
      DeviceCategory.tablet => Icons.tablet,
      DeviceCategory.computer => Icons.computer,
      DeviceCategory.tv => Icons.tv,
      DeviceCategory.gameConsole => Icons.sports_esports,
      DeviceCategory.mediaPlayer => Icons.cast,
      DeviceCategory.smartSpeaker => Icons.speaker,
      DeviceCategory.camera => Icons.videocam,
      DeviceCategory.printer => Icons.print,
      DeviceCategory.networkDevice => Icons.router,
      DeviceCategory.iot => Icons.lightbulb,
      DeviceCategory.wearable => Icons.watch,
      DeviceCategory.unknown => Icons.devices_other,
    };
  }

  String _getSignalQualityText(int level) {
    return switch (level) {
      3 => 'Excellent',
      2 => 'Good',
      1 => 'Fair',
      _ => 'Poor',
    };
  }

  // ===========================================================================
  // DHCP Actions
  // ===========================================================================

  Future<void> _reserveIp(
      BuildContext context, WidgetRef ref, DeviceUIModel device) async {
    await performUspMutation(
      context,
      ref,
      loadingKey: 'dhcp',
      mutation: () => ref
          .read(uspDhcpReservationsProvider.notifier)
          .immediateAdd(mac: device.mac, ip: device.ip),
      successMessage: 'IP address reserved',
    );
  }

  Future<void> _releaseReservation(
      BuildContext context, WidgetRef ref, DeviceDetailState detail) async {
    await performUspMutation(
      context,
      ref,
      loadingKey: 'dhcp',
      mutation: () => ref
          .read(uspDhcpReservationsProvider.notifier)
          .immediateDelete(detail.reservation!.instancePath!),
      successMessage: 'Reservation released',
    );
  }
}

// =============================================================================
// Speed Card Widget
// =============================================================================

class _SpeedCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int speedBps;
  final Color color;

  const _SpeedCard({
    required this.icon,
    required this.label,
    required this.speedBps,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final (:value, :unit) = NetworkUtils.formatBitsWithUnit(speedBps);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              AppGap.xs(),
              AppText.labelSmall(label, color: color),
            ],
          ),
          AppGap.xs(),
          AppText.titleLarge(value),
          AppText.labelSmall(
            unit,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
