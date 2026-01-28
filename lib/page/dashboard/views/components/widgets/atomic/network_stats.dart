import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying network stats (nodes/devices count).
///
/// For custom layout (Bento Grid) only.
/// - Compact: Simple row with icons and counts.
/// - Normal/Expanded: Two visual blocks for Nodes and Devices.
class CustomNetworkStats extends DisplayModeConsumerWidget {
  const CustomNetworkStats({
    super.key,
    super.displayMode,
  });

  @override
  double getLoadingHeight(DisplayMode mode) => switch (mode) {
        DisplayMode.compact => 80,
        DisplayMode.normal => 100,
        DisplayMode.expanded => 120,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    // Compact: Minimal row with icons and numbers
    final (nodesCount, hasOffline, externalDeviceCount) = _getStats(ref);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactItem(
            context,
            icon: hasOffline
                ? AppIcon.font(AppFontIcons.infoCircle,
                    color: Theme.of(context).colorScheme.error)
                : AppIcon.font(AppFontIcons.networkNode),
            count: nodesCount,
            label: loc(context).nodes,
            onTap: () {
              ref.read(topologySelectedIdProvider.notifier).state = '';
              context.pushNamed(RouteNamed.menuInstantTopology);
            },
          ),
          Container(
            width: 1,
            height: 24,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          _buildCompactItem(
            context,
            icon: AppIcon.font(AppFontIcons.devices),
            count: externalDeviceCount,
            label: loc(context).devices,
            onTap: () => context.pushNamed(RouteNamed.menuInstantDevices),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    return _buildBlockLayout(context, ref, isExpanded: false);
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    return _buildExpandedBlockLayout(context, ref);
  }

  Widget _buildBlockLayout(
    BuildContext context,
    WidgetRef ref, {
    required bool isExpanded,
  }) {
    final (nodesCount, hasOffline, externalDeviceCount) = _getStats(ref);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _infoBlock(
              context,
              icon: hasOffline
                  ? AppIcon.font(AppFontIcons.infoCircle,
                      color: Theme.of(context).colorScheme.error)
                  : AppIcon.font(AppFontIcons.networkNode),
              count: nodesCount,
              label: nodesCount == 1 ? loc(context).node : loc(context).nodes,
              onTap: () {
                ref.read(topologySelectedIdProvider.notifier).state = '';
                context.pushNamed(RouteNamed.menuInstantTopology);
              },
            ),
          ),
          AppGap.md(),
          Expanded(
            child: _infoBlock(
              context,
              icon: AppIcon.font(AppFontIcons.devices),
              count: externalDeviceCount,
              label: externalDeviceCount == 1
                  ? loc(context).device
                  : loc(context).devices,
              onTap: () => context.pushNamed(RouteNamed.menuInstantDevices),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedBlockLayout(BuildContext context, WidgetRef ref) {
    final stats = _getDetailedStats(ref);
    final colorScheme = Theme.of(context).colorScheme;
    final appColorScheme = Theme.of(context).extension<AppColorScheme>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Nodes Block
          Expanded(
            child: _chartInfoBlock(
              context,
              title: stats.totalNodes.toString(),
              subtitle: stats.totalNodes == 1
                  ? loc(context).node
                  : loc(context).nodes,
              chartData: [
                if (stats.onlineNodes > 0)
                  _ChartSegment(stats.onlineNodes.toDouble(),
                      appColorScheme?.semanticSuccess ?? colorScheme.primary),
                if (stats.offlineNodes > 0)
                  _ChartSegment(
                      stats.offlineNodes.toDouble(), colorScheme.error),
              ],
              onTap: () {
                ref.read(topologySelectedIdProvider.notifier).state = '';
                context.pushNamed(RouteNamed.menuInstantTopology);
              },
              legend: [
                if (stats.onlineNodes > 0)
                  _LegendItem(
                      loc(context).online,
                      appColorScheme?.semanticSuccess ?? colorScheme.primary,
                      stats.onlineNodes),
                if (stats.offlineNodes > 0)
                  _LegendItem('Offline', colorScheme.error, stats.offlineNodes),
              ],
            ),
          ),
          AppGap.md(),
          // Devices Block
          Expanded(
            child: _chartInfoBlock(
              context,
              title: stats.totalDevices.toString(),
              subtitle: stats.totalDevices == 1
                  ? loc(context).device
                  : loc(context).devices,
              chartData: [
                if (stats.wiredDevices > 0)
                  _ChartSegment(
                      stats.wiredDevices.toDouble(), colorScheme.primary),
                if (stats.wirelessDevices > 0)
                  _ChartSegment(
                      stats.wirelessDevices.toDouble(), colorScheme.tertiary),
              ],
              onTap: () => context.pushNamed(RouteNamed.menuInstantDevices),
              legend: [
                if (stats.wiredDevices > 0)
                  _LegendItem(loc(context).wired, colorScheme.primary,
                      stats.wiredDevices),
                if (stats.wirelessDevices > 0)
                  _LegendItem(loc(context).wireless, colorScheme.tertiary,
                      stats.wirelessDevices),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactItem(
    BuildContext context, {
    required Widget icon,
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          icon,
          AppGap.sm(),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.titleSmall('$count'),
              AppText.labelSmall(label,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(
    BuildContext context, {
    required Widget icon,
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.titleLarge('$count'),
                icon,
              ],
            ),
            AppGap.sm(),
            AppText.bodyMedium(label),
          ],
        ),
      ),
    );
  }

  Widget _chartInfoBlock(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<_ChartSegment> chartData,
    required List<_LegendItem> legend,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Chart
            SizedBox(
              width: 50,
              height: 50,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  segments: chartData,
                  width: 6,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: AppText.labelMedium(title),
                ),
              ),
            ),
            AppGap.md(),
            // Legend
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleSmall(subtitle),
                  AppGap.xs(),
                  ...legend.map((item) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            AppGap.xs(),
                            Expanded(
                              child: AppText.labelSmall(
                                '${item.label} (${item.count})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (int, bool, int) _getStats(WidgetRef ref) {
    final topologyState = ref.watch(instantTopologyProvider);
    final nodes = topologyState.root.children.firstOrNull?.toFlatList() ?? [];
    final hasOffline = nodes.any((element) => !element.data.isOnline);
    final externalDeviceCount = ref
        .watch(deviceManagerProvider)
        .externalDevices
        .where((e) => e.isOnline())
        .length;
    return (nodes.length, hasOffline, externalDeviceCount);
  }

  _DetailedStats _getDetailedStats(WidgetRef ref) {
    // Nodes
    final topologyState = ref.watch(instantTopologyProvider);
    final nodes = topologyState.root.children.firstOrNull?.toFlatList() ?? [];
    final totalNodes = nodes.length;
    final offlineNodes = nodes.where((e) => !e.data.isOnline).length;
    final onlineNodes = totalNodes - offlineNodes;

    // Devices
    final devices = ref
        .watch(deviceManagerProvider)
        .externalDevices
        .where((e) => e.isOnline());
    final totalDevices = devices.length;
    final wiredDevices = devices
        .where((d) => d.getConnectionType() == DeviceConnectionType.wired)
        .length;
    final wirelessDevices = devices
        .where((d) => d.getConnectionType() == DeviceConnectionType.wireless)
        .length;

    return _DetailedStats(
      totalNodes: totalNodes,
      onlineNodes: onlineNodes,
      offlineNodes: offlineNodes,
      totalDevices: totalDevices,
      wiredDevices: wiredDevices,
      wirelessDevices: wirelessDevices,
    );
  }
}

class _DetailedStats {
  final int totalNodes;
  final int onlineNodes;
  final int offlineNodes;
  final int totalDevices;
  final int wiredDevices;
  final int wirelessDevices;

  _DetailedStats({
    required this.totalNodes,
    required this.onlineNodes,
    required this.offlineNodes,
    required this.totalDevices,
    required this.wiredDevices,
    required this.wirelessDevices,
  });
}

class _ChartSegment {
  final double value;
  final Color color;

  _ChartSegment(this.value, this.color);
}

class _LegendItem {
  final String label;
  final Color color;
  final int count;

  _LegendItem(this.label, this.color, this.count);
}

class _DonutChartPainter extends CustomPainter {
  final List<_ChartSegment> segments;
  final double width;
  final Color backgroundColor;

  _DonutChartPainter({
    required this.segments,
    required this.width,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - width) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    canvas.drawCircle(center, radius, bgPaint);

    double total = segments.fold(0, (sum, item) => sum + item.value);
    if (total == 0) return;

    double startAngle = -math.pi / 2;

    for (var segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) =>
      segments != oldDelegate.segments;
}

// Keep old name as alias for backward compatibility
@Deprecated('Use CustomNetworkStats instead')
typedef DashboardNetworkStats = CustomNetworkStats;
