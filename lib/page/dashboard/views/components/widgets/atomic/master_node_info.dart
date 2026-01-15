import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying master router information.
///
/// For custom layout (Bento Grid) only.
/// - Compact: Router image + Location name
/// - Normal: Standard list of details (Model, SN, FW)
/// - Expanded: Detailed view with larger typography/spacing
class CustomMasterNodeInfo extends DisplayModeConsumerWidget {
  const CustomMasterNodeInfo({
    super.key,
    super.displayMode,
  });

  @override
  double getLoadingHeight(DisplayMode mode) => switch (mode) {
        DisplayMode.compact => 80,
        DisplayMode.normal => 150,
        DisplayMode.expanded => 200,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    // Compact: Just image and location/name centered
    final master = ref.watch(instantTopologyProvider).root.children.first;
    final masterIcon = ref.watch(dashboardHomeProvider).masterIcon;

    return AppInkWell(
      customColor: Colors.transparent,
      customBorderWidth: 0,
      onTap: () => _navigateToNodeDetail(context, ref, master.data.deviceId),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 48,
                child: SharedWidgets.resolveRouterImage(
                  context,
                  masterIcon,
                  size: 48,
                ),
              ),
              AppGap.md(),
              Flexible(
                child: AppText.labelMedium(
                  master.data.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    return _buildDetailView(context, ref, isExpanded: false);
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    return _buildDetailView(context, ref, isExpanded: true);
  }

  Widget _buildDetailView(
    BuildContext context,
    WidgetRef ref, {
    required bool isExpanded,
  }) {
    final master = ref.watch(instantTopologyProvider).root.children.first;
    final dashboardState = ref.watch(dashboardHomeProvider);
    final masterIcon = dashboardState.masterIcon;
    final wanPortConnection = dashboardState.wanPortConnection;
    final isMasterOffline =
        master.data.isOnline == false || wanPortConnection == 'None';

    // Expanded mode: Unified layout with larger image
    if (isExpanded) {
      return _buildExpandedLayout(
        context,
        ref,
        master: master,
        dashboardState: dashboardState,
        masterIcon: masterIcon,
        isMasterOffline: isMasterOffline,
      );
    }

    // Normal mode: Standard horizontal layout
    return _buildNormalLayout(
      context,
      ref,
      master: master,
      masterIcon: masterIcon,
      isMasterOffline: isMasterOffline,
    );
  }

  /// Expanded layout: Larger image with unified info sections
  Widget _buildExpandedLayout(
    BuildContext context,
    WidgetRef ref, {
    required dynamic master,
    required DashboardHomeState dashboardState,
    required String masterIcon,
    required bool isMasterOffline,
  }) {
    return AppInkWell(
      customColor: Colors.transparent,
      customBorderWidth: 0,
      onTap: () => _navigateToNodeDetail(context, ref, master.data.deviceId),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Large Router Image + Location + Uptime
            SizedBox(
              width: 160,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Router Image - Larger size
                  SharedWidgets.resolveRouterImage(
                    context,
                    masterIcon,
                    size: 140,
                  ),
                  AppGap.md(),
                  // Location Name
                  AppText.titleMedium(
                    master.data.location,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Uptime under image
                  if (dashboardState.uptime != null) ...[
                    AppGap.md(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon.font(Icons.access_time, size: 14),
                        AppGap.xs(),
                        AppText.labelSmall(
                          _formatUptime(context, dashboardState.uptime!),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AppGap.xl(),
            // Right: Device Info + System Stats
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Device Info Section
                  _buildInfoSection(
                    context,
                    items: [
                      (
                        loc(context).connection,
                        isMasterOffline
                            ? '--'
                            : (master.data.isWiredConnection == true)
                                ? loc(context).wired
                                : loc(context).wireless
                      ),
                      (loc(context).model, master.data.model),
                      (loc(context).serialNo, master.data.serialNumber),
                      if (master.data.ipAddress.isNotEmpty)
                        ('IP', master.data.ipAddress),
                      if (master.data.macAddress.isNotEmpty)
                        ('MAC', master.data.macAddress),
                      ('FW', master.data.fwVersion),
                    ],
                  ),
                  AppGap.lg(),
                  // System Stats Section
                  _buildSystemStatsSection(context, dashboardState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Info section with label-value pairs in a unified style
  Widget _buildInfoSection(
    BuildContext context, {
    required List<(String, String)> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: AppText.labelSmall(
                    '${item.$1}:',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: AppText.bodySmall(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// System stats section with CPU and Memory bars
  Widget _buildSystemStatsSection(
      BuildContext context, DashboardHomeState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColorScheme = Theme.of(context).extension<AppColorScheme>();

    // Don't show if no data available
    if (state.cpuLoad == null && state.memoryLoad == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // CPU Utilization
          if (state.cpuLoad != null) ...[
            _buildUtilizationBar(
              context,
              label: loc(context).cpuUtilization,
              value: _parseLoadPercentage(state.cpuLoad!),
              color: colorScheme.primary,
            ),
          ],
          // Memory Utilization
          if (state.memoryLoad != null) ...[
            if (state.cpuLoad != null) AppGap.md(),
            _buildUtilizationBar(
              context,
              label: loc(context).memoryUtilization,
              value: _parseLoadPercentage(state.memoryLoad!),
              color: appColorScheme?.semanticSuccess ?? colorScheme.tertiary,
            ),
          ],
        ],
      ),
    );
  }

  /// Normal layout: Standard horizontal layout (unchanged)
  Widget _buildNormalLayout(
    BuildContext context,
    WidgetRef ref, {
    required dynamic master,
    required String masterIcon,
    required bool isMasterOffline,
  }) {
    return AppInkWell(
      customColor: Colors.transparent,
      customBorderWidth: 0,
      onTap: () => _navigateToNodeDetail(context, ref, master.data.deviceId),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Row(
        children: [
          // Router Image
          SizedBox(
            width: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SharedWidgets.resolveRouterImage(
                  context,
                  masterIcon,
                  size: 80,
                ),
              ],
            ),
          ),
          // Details Table
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleSmall(master.data.location),
                  AppGap.md(),
                  Table(
                    border: const TableBorder(),
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _buildRow(
                        context,
                        loc(context).connection,
                        isMasterOffline
                            ? '--'
                            : (master.data.isWiredConnection == true)
                                ? loc(context).wired
                                : loc(context).wireless,
                      ),
                      _buildRow(
                        context,
                        loc(context).model,
                        master.data.model,
                      ),
                      _buildRow(
                        context,
                        loc(context).serialNo,
                        master.data.serialNumber,
                      ),
                      if (master.data.ipAddress.isNotEmpty)
                        _buildRow(
                          context,
                          'IP Address',
                          master.data.ipAddress,
                        ),
                      if (master.data.macAddress.isNotEmpty)
                        _buildRow(
                          context,
                          'MAC Address',
                          master.data.macAddress,
                        ),
                      _buildFirmwareRow(
                        context,
                        master.data.fwVersion,
                        !isMasterOffline && master.data.fwUpToDate == false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a utilization bar with label and percentage
  Widget _buildUtilizationBar(
    BuildContext context, {
    required String label,
    required double value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = (value * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.labelSmall(label),
            AppText.labelSmall('$percentage%'),
          ],
        ),
        AppGap.xs(),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  /// Parse JNAP load string to percentage (0.0 - 1.0)
  /// JNAP returns values like "0.23" representing 23%
  double _parseLoadPercentage(String loadString) {
    final parsed = double.tryParse(loadString) ?? 0.0;
    // JNAP returns as decimal (0.23 = 23%), so we use it directly
    return parsed.clamp(0.0, 1.0);
  }

  /// Format uptime seconds to human readable string
  String _formatUptime(BuildContext context, int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  TableRow _buildRow(BuildContext context, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md, bottom: 4),
          child: AppText.labelMedium('$label:'),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AppText.bodyMedium(value),
        ),
      ],
    );
  }

  TableRow _buildFirmwareRow(
      BuildContext context, String version, bool hasUpdate) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md, bottom: 4),
          child: AppText.labelMedium('${loc(context).fwVersion}:'),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          children: [
            AppText.bodyMedium(version),
            if (hasUpdate)
              SharedWidgets.nodeFirmwareStatusWidget(
                context,
                true,
                () {
                  context.pushNamed(RouteNamed.firmwareUpdateDetail);
                },
              ),
          ],
        ),
      ],
    );
  }

  void _navigateToNodeDetail(
      BuildContext context, WidgetRef ref, String deviceId) {
    ref.read(nodeDetailIdProvider.notifier).state = deviceId;
    context.pushNamed(RouteNamed.nodeDetails);
  }
}

// Keep old name as alias for backward compatibility
@Deprecated('Use CustomMasterNodeInfo instead')
typedef DashboardMasterNodeInfo = CustomMasterNodeInfo;
