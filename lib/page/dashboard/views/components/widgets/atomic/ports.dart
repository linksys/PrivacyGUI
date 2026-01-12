import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/port_status_widget.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying port status (LAN + WAN).
///
/// For custom layout (Bento Grid) only.
/// - Compact: Minimal port icons in a row
/// - Normal: Standard port display (auto horizontal/vertical)
/// - Expanded: Detailed port info with labels
///
/// The widget automatically adapts layout (horizontal/vertical) based on:
/// 1. Device port configuration (hasLanPort, isHorizontalLayout)
/// 2. Available container space (aspect ratio)
class CustomPorts extends DisplayModeConsumerWidget {
  const CustomPorts({
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
    final state = ref.watch(dashboardHomeProvider);
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // LAN ports
          ...state.lanPortConnections.mapIndexed((index, e) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: _compactPortIcon(
                context,
                label: 'LAN${index + 1}',
                isConnected: e != 'None',
                isWan: false,
              ),
            );
          }),
          // WAN port
          if (hasLanPort) const SizedBox(width: AppSpacing.md),
          _compactPortIcon(
            context,
            label: loc(context).wan,
            isConnected: state.wanPortConnection != 'None',
            isWan: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    return _buildAdaptivePortLayout(context, ref);
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    return _buildAdaptivePortLayout(context, ref);
  }

  /// Builds adaptive port layout based on container aspect ratio
  Widget _buildAdaptivePortLayout(
    BuildContext context,
    WidgetRef ref, {
    bool showTitle = false,
  }) {
    final state = ref.watch(dashboardHomeProvider);
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final preferHorizontal = hasLanPort && state.isHorizontalLayout;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on aspect ratio and preference
        final aspectRatio = constraints.maxWidth / constraints.maxHeight;

        // Thresholds for layout decision
        // - If device prefers horizontal and has enough width, use horizontal
        // - Otherwise use vertical (which can scroll if needed)
        final useHorizontal = preferHorizontal && aspectRatio > 1.2;

        Widget portContent;
        if (!hasLanPort) {
          // No LAN port: horizontal compact layout
          portContent = _buildNoLanPortLayout(context, state);
        } else if (useHorizontal) {
          portContent = _buildHorizontalLayout(context, state);
        } else {
          portContent = _buildVerticalLayout(context, state);
        }

        if (showTitle) {
          // Use SingleChildScrollView to prevent overflow in expanded mode
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    top: AppSpacing.lg,
                    bottom: AppSpacing.md,
                  ),
                  child: AppText.titleSmall(loc(context).ports),
                ),
                portContent,
              ],
            ),
          );
        }

        return portContent;
      },
    );
  }

  Widget _buildNoLanPortLayout(BuildContext context, dynamic state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: PortStatusWidget(
          connection: state.wanPortConnection == 'None'
              ? null
              : state.wanPortConnection,
          label: loc(context).wan,
          isWan: true,
          hasLanPorts: false,
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, dynamic state) {
    final lanPorts = state.lanPortConnections.mapIndexed((index, e) {
      return Expanded(
        child: PortStatusWidget(
          connection: e == 'None' ? null : e,
          label: loc(context).indexedPort(index + 1),
          isWan: false,
          hasLanPorts: true,
        ),
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width * 0.3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...lanPorts,
            Expanded(
              child: PortStatusWidget(
                connection: state.wanPortConnection == 'None'
                    ? null
                    : state.wanPortConnection,
                label: loc(context).wan,
                isWan: true,
                hasLanPorts: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context, dynamic state) {
    final lanPorts = state.lanPortConnections.mapIndexed((index, e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: PortStatusWidget(
          connection: e == 'None' ? null : e,
          label: loc(context).indexedPort(index + 1),
          isWan: false,
          hasLanPorts: true,
        ),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...lanPorts,
          PortStatusWidget(
            connection: state.wanPortConnection == 'None'
                ? null
                : state.wanPortConnection,
            label: loc(context).wan,
            isWan: true,
            hasLanPorts: true,
          ),
        ],
      ),
    );
  }

  Widget _compactPortIcon(
    BuildContext context, {
    required String label,
    required bool isConnected,
    required bool isWan,
  }) {
    return Tooltip(
      message: '$label: ${isConnected ? "Connected" : "Disconnected"}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWan ? Icons.public : Icons.lan,
            size: 20,
            color: isConnected
                ? Theme.of(context)
                        .extension<AppDesignTheme>()
                        ?.colorScheme
                        .semanticSuccess ??
                    Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.xs(),
          AppText.labelSmall(
            label,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
