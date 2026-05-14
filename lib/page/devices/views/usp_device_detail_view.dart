import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/core/utils/device_classifier.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/devices/providers/device_detail_provider.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:privacy_gui/util/wifi_signal_utils.dart';
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
        // Only show WiFi details for active WiFi devices
        if (device.isWifi && device.isActive) ...[
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
        DetailGridRow(
          left: _buildDeviceIdentityCard(context, device),
          right: _buildConnectionStatusCard(context, device),
        ),
        AppGap.gutter(),
        DetailGridRow(
          // Only show WiFi details for active WiFi devices
          left: device.isWifi && device.isActive
              ? _buildWifiDetailsCard(context, device)
              : _buildNetworkAddressesCard(context, device),
          right: _buildDhcpCard(context, ref, device, detail, isLoading),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  classification.category.icon,
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
              DetailStatusBadge(isActive: device.isActive),
            ],
          ),
          AppGap.xl(),
          if (vendor != null) ...[
            DetailInfoTile(
              icon: Icons.business,
              label: 'Manufacturer',
              value: vendor,
            ),
            AppGap.md(),
          ],
          DetailCopyableTile(
            icon: Icons.memory,
            label: 'MAC Address',
            value: device.mac,
          ),
          AppGap.md(),
          if (device.hostName.isNotEmpty &&
              device.hostName != device.displayName) ...[
            DetailInfoTile(
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

  Widget _buildConnectionStatusCard(
      BuildContext context, DeviceUIModel device) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailCardHeader(
            icon: device.isWifi ? Icons.wifi : Icons.settings_ethernet,
            title: device.isWifi ? 'WiFi Connection' : 'Wired Connection',
          ),
          AppGap.xl(),
          DetailCopyableTile(
            icon: Icons.language,
            label: 'IP Address',
            value: device.ip,
          ),
          if (device.ipv6Addresses.isNotEmpty) ...[
            AppGap.md(),
            _buildIpv6Section(context, device.ipv6Addresses),
          ],
          if (device.parentNodeName != null) ...[
            AppGap.md(),
            DetailInfoTile(
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
    final hasSignalData = device.signalStrength != null;
    final hasSpeedData =
        device.downlinkRate != null || device.uplinkRate != null;
    final hasBandSsid = device.band != null || device.ssidName != null;
    final hasAnyData = hasSignalData || hasSpeedData || hasBandSsid;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailCardHeader(
            icon: Icons.signal_wifi_4_bar,
            title: 'Signal & Speed',
          ),
          AppGap.xl(),
          if (!hasAnyData)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  AppGap.sm(),
                  Expanded(
                    child: AppText.bodyMedium(
                      'Signal data not available for this device.',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          if (hasSignalData) ...[
            _buildSignalSection(context, device),
            AppGap.lg(),
          ],
          if (hasSpeedData) _buildSpeedCards(context, device),
          if (hasBandSsid) ...[
            AppGap.lg(),
            Row(
              children: [
                if (device.band != null)
                  Expanded(
                    child: DetailCompactInfoTile(
                      icon: Icons.wifi_channel,
                      label: 'Band',
                      value: device.band!,
                    ),
                  ),
                if (device.band != null && device.ssidName != null) AppGap.md(),
                if (device.ssidName != null)
                  Expanded(
                    child: DetailCompactInfoTile(
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
                  getWifiSignalLevel(device.signalStrength)
                      .resolveLabel(context),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (device.downlinkRate != null)
          Expanded(
            child: DetailSpeedCard(
              icon: Icons.arrow_downward,
              label: 'Download',
              speedBps: device.downlinkRate!,
              color: colorScheme.primary,
            ),
          ),
        if (device.downlinkRate != null && device.uplinkRate != null)
          AppGap.md(),
        if (device.uplinkRate != null)
          Expanded(
            child: DetailSpeedCard(
              icon: Icons.arrow_upward,
              label: 'Upload',
              speedBps: device.uplinkRate!,
              color: colorScheme.secondary,
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // Network Addresses Card (for non-active or wired devices on desktop)
  // ===========================================================================

  Widget _buildNetworkAddressesCard(
      BuildContext context, DeviceUIModel device) {
    final isWifi = device.isWifi;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailCardHeader(
            icon: isWifi ? Icons.wifi_off : Icons.cable,
            title: 'Network Details',
          ),
          AppGap.xl(),
          DetailInfoTile(
            icon: isWifi ? Icons.wifi : Icons.settings_ethernet,
            label: 'Connection Type',
            value: isWifi ? 'WiFi (Wireless)' : 'Ethernet (Wired)',
          ),
          if (device.parentNodeName != null) ...[
            AppGap.md(),
            DetailInfoTile(
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
    final hasValidIpv4 = NetworkUtils.isValidIpAddress(device.ip);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailCardHeader(
            icon: Icons.bookmark,
            title: 'DHCP Reservation',
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
                    hasValidIpv4 ? Icons.info_outline : Icons.warning_amber,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  AppGap.sm(),
                  Expanded(
                    child: AppText.bodyMedium(
                      hasValidIpv4
                          ? 'No reservation. IP may change on reconnect.'
                          : 'No IPv4 address. Cannot create reservation.',
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
              onTap: isLoading || !hasValidIpv4
                  ? null
                  : () => _reserveIp(context, ref, device),
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
                      onTap: () =>
                          setState(() => _ipv6Expanded = !_ipv6Expanded),
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
                      child: DetailCopyableText(text: addr),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
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
