import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying network stats (nodes/devices count).
///
/// Extracted from [DashboardNetworks] for Bento Grid atomic usage.
class DashboardNetworkStats extends ConsumerWidget {
  const DashboardNetworkStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: 100,
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final topologyState = ref.watch(instantTopologyProvider);
    final nodes = topologyState.root.children.firstOrNull?.toFlatList() ?? [];
    final hasOffline = nodes.any((element) => !element.data.isOnline);
    final externalDeviceCount = ref
        .watch(deviceManagerProvider)
        .externalDevices
        .where((e) => e.isOnline())
        .length;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Nodes section
          Expanded(
            child: _infoTile(
              context,
              icon: hasOffline
                  ? AppIcon.font(AppFontIcons.infoCircle,
                      color: Theme.of(context).colorScheme.error)
                  : AppIcon.font(AppFontIcons.networkNode),
              count: nodes.length,
              label: nodes.length == 1 ? loc(context).node : loc(context).nodes,
              onTap: () {
                ref.read(topologySelectedIdProvider.notifier).state = '';
                context.pushNamed(RouteNamed.menuInstantTopology);
              },
            ),
          ),
          AppGap.gutter(),
          // Devices section
          Expanded(
            child: _infoTile(
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

  Widget _infoTile(
    BuildContext context, {
    required Widget icon,
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(child: AppText.titleSmall('$count')),
                icon,
              ],
            ),
            AppGap.lg(),
            AppText.bodySmall(label),
          ],
        ),
      ),
    );
  }
}
