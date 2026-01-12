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
        DisplayMode.compact => 60,
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
    return _buildBlockLayout(context, ref, isExpanded: true);
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
              isExpanded: isExpanded,
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
              isExpanded: isExpanded,
              onTap: () => context.pushNamed(RouteNamed.menuInstantDevices),
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
    required bool isExpanded,
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
}

// Keep old name as alias for backward compatibility
@Deprecated('Use CustomNetworkStats instead')
typedef DashboardNetworkStats = CustomNetworkStats;
