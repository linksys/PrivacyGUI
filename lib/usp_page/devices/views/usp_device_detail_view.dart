import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_mutation_helper.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_status_dot.dart';
import 'package:privacy_gui/usp_page/devices/providers/device_detail_provider.dart';
import 'package:privacy_gui/usp_page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspDeviceDetailView extends ConsumerWidget {
  final String mac;

  const UspDeviceDetailView({super.key, required this.mac});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(uspDeviceDetailProvider(mac));
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'dhcp';

    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      padding:
          const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
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
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.goNamed(RouteNamed.uspDeviceList),
                ),
              ],
            ),
          );
        }

        final device = detail.device!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            AppGap.xl(),
            AppResponsiveLayout(
              mobile: (_) =>
                  _buildSingleColumn(context, ref, device, detail, isLoading),
              desktop: (_) =>
                  _buildTwoColumn(context, ref, device, detail, isLoading),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        AppIconButton(
          icon: AppIcon.font(Icons.arrow_back),
          onTap: () => context.canPop()
              ? context.pop()
              : context.goNamed(RouteNamed.uspDeviceList),
        ),
        AppGap.md(),
        AppText.headlineSmall('Device Detail'),
      ],
    );
  }

  Widget _buildSingleColumn(BuildContext context, WidgetRef ref,
      DeviceUIModel device, DeviceDetailState detail, bool isLoading) {
    return Column(
      children: [
        _buildDeviceInfoCard(context, device),
        AppGap.xl(),
        _buildConnectionCard(context, device),
        AppGap.xl(),
        _buildDhcpCard(context, ref, device, detail, isLoading),
      ],
    );
  }

  Widget _buildTwoColumn(BuildContext context, WidgetRef ref,
      DeviceUIModel device, DeviceDetailState detail, bool isLoading) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildDeviceInfoCard(context, device),
              AppGap.xl(),
              _buildConnectionCard(context, device),
            ],
          ),
        ),
        AppGap.gutter(),
        Expanded(
          child: _buildDhcpCard(context, ref, device, detail, isLoading),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Device Info Card
  // ---------------------------------------------------------------------------

  Widget _buildDeviceInfoCard(BuildContext context, DeviceUIModel device) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                device.isWifi ? Icons.wifi : Icons.settings_ethernet,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              AppGap.md(),
              Expanded(
                child: AppText.titleLarge(device.displayName),
              ),
              UspStatusDot(isActive: device.isActive, size: 12),
              AppGap.sm(),
              AppText.labelLarge(device.isActive ? 'Online' : 'Offline'),
            ],
          ),
          AppGap.xl(),
          _infoRow(context, 'MAC Address', device.mac),
          _infoRow(context, 'IP Address', device.ip),
          if (device.hostName.isNotEmpty &&
              device.hostName != device.displayName)
            _infoRow(context, 'Hostname', device.hostName),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Connection Card
  // ---------------------------------------------------------------------------

  Widget _buildConnectionCard(BuildContext context, DeviceUIModel device) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Connection'),
          AppGap.xl(),
          _infoRow(context, 'Type', device.isWifi ? 'WiFi' : 'Ethernet'),
          if (device.isWifi) ...[
            if (device.band != null) _infoRow(context, 'Band', device.band!),
            if (device.ssidName != null)
              _infoRow(context, 'SSID', device.ssidName!),
            if (device.signalStrength != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: AppText.labelLarge('Signal'),
                    ),
                    UspSignalStrengthIndicator(
                      rssi: device.signalStrength!,
                      maxBarHeight: 18,
                    ),
                  ],
                ),
              ),
            ],
            if (device.downlinkRate != null)
              _infoRow(context, 'Downlink',
                  '${(device.downlinkRate! / 1000000).toStringAsFixed(0)} Mbps'),
            if (device.uplinkRate != null)
              _infoRow(context, 'Uplink',
                  '${(device.uplinkRate! / 1000000).toStringAsFixed(0)} Mbps'),
          ],
          if (device.parentNodeName != null)
            _infoRow(context, 'Connected to', device.parentNodeName!),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DHCP Reservation Card
  // ---------------------------------------------------------------------------

  Widget _buildDhcpCard(BuildContext context, WidgetRef ref,
      DeviceUIModel device, DeviceDetailState detail, bool isLoading) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('DHCP Reservation'),
          AppGap.xl(),
          if (detail.hasReservation) ...[
            _infoRow(context, 'Status', 'Reserved'),
            _infoRow(context, 'Reserved IP', detail.reservation!.ip),
            AppGap.lg(),
            AppButton.primaryOutline(
              label: 'Release Reservation',
              isLoading: isLoading,
              onTap: isLoading
                  ? null
                  : () => _releaseReservation(context, ref, detail),
            ),
          ] else ...[
            _infoRow(context, 'Status', 'Not Reserved'),
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

  // ---------------------------------------------------------------------------
  // DHCP Actions
  // ---------------------------------------------------------------------------

  Future<void> _reserveIp(
      BuildContext context, WidgetRef ref, DeviceUIModel device) async {
    await performUspMutation(
      context,
      ref,
      loadingKey: 'dhcp',
      mutation: () => ref
          .read(uspDashboardProvider.notifier)
          .addDhcpReservation(mac: device.mac, ip: device.ip),
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
          .read(uspDashboardProvider.notifier)
          .deleteDhcpReservation(detail.reservation!.instancePath),
      successMessage: 'Reservation released',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: AppText.labelLarge(label),
          ),
          Expanded(
            child: AppText.bodyMedium(value),
          ),
        ],
      ),
    );
  }
}
