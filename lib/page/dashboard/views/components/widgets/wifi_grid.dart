import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/wifi_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Grid displaying WiFi networks for the dashboard.
///
/// Supports three display modes:
/// - [DisplayMode.compact]: Horizontal scrollable cards
/// - [DisplayMode.normal]: 2-column grid
/// - [DisplayMode.expanded]: Larger cards with more details
class DashboardWiFiGrid extends ConsumerStatefulWidget {
  const DashboardWiFiGrid({
    super.key,
    this.displayMode = DisplayMode.normal,
  });

  /// The display mode for this widget
  final DisplayMode displayMode;

  @override
  ConsumerState<DashboardWiFiGrid> createState() => _DashboardWiFiGridState();
}

class _DashboardWiFiGridState extends ConsumerState<DashboardWiFiGrid> {
  Map<String, bool> toolTipVisible = {};

  @override
  Widget build(BuildContext context) {
    return DashboardLoadingWrapper(
      loadingHeight: _calculateLoadingHeight(context),
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  double _calculateLoadingHeight(BuildContext context) {
    const itemHeight = 176.0;
    final mainSpacing =
        AppLayoutConfig.gutter(MediaQuery.of(context).size.width);
    return itemHeight * 2 + mainSpacing * 1;
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return switch (widget.displayMode) {
      DisplayMode.compact => _buildCompactView(context, ref),
      DisplayMode.normal => _buildNormalView(context, ref),
      DisplayMode.expanded => _buildExpandedView(context, ref),
    };
  }

  /// Compact view: Horizontal scrollable small cards
  Widget _buildCompactView(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(dashboardHomeProvider.select((value) => value.wifis));
    final enabledWiFiCount =
        items.where((e) => !e.isGuest && e.isEnabled).length;
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;
    final canBeDisabled = enabledWiFiCount > 1 || hasLanPort;

    const compactHeight = 160.0;

    return SizedBox(
      height: compactHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => AppGap.md(),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 200,
            height: compactHeight,
            child: _buildWiFiCard(
              items,
              index,
              canBeDisabled,
              padding: const EdgeInsets.all(AppSpacing.lg),
            ),
          );
        },
      ),
    );
  }

  /// Normal view: 2-column grid (existing implementation)
  Widget _buildNormalView(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(dashboardHomeProvider.select((value) => value.wifis));
    final crossAxisCount =
        (context.isMobileLayout || context.isTabletLayout) ? 1 : 2;
    // Use layout gutter for horizontal spacing to match Dashboard Layout
    final mainSpacing =
        AppLayoutConfig.gutter(MediaQuery.of(context).size.width);
    const itemHeight = 176.0;
    final mainAxisCount = (items.length / crossAxisCount).ceil();

    final enabledWiFiCount =
        items.where((e) => !e.isGuest && e.isEnabled).length;
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;
    final canBeDisabled = enabledWiFiCount > 1 || hasLanPort;

    final gridHeight = mainAxisCount * itemHeight +
        ((mainAxisCount == 0 ? 1 : mainAxisCount) - 1) * AppSpacing.lg;

    // Use SingleChildScrollView to handle overflow when Bento Grid container
    // is smaller than the calculated gridHeight
    return SingleChildScrollView(
      child: SizedBox(
        height: gridHeight,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: mainSpacing,
            mainAxisExtent: itemHeight,
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            return SizedBox(
              height: itemHeight,
              child: _buildWiFiCard(items, index, canBeDisabled),
            );
          },
        ),
      ),
    );
  }

  /// Expanded view: Single column with larger cards
  Widget _buildExpandedView(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(dashboardHomeProvider.select((value) => value.wifis));
    const itemHeight = 200.0;

    final enabledWiFiCount =
        items.where((e) => !e.isGuest && e.isEnabled).length;
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;
    final canBeDisabled = enabledWiFiCount > 1 || hasLanPort;

    final gridHeight = items.length * itemHeight +
        (items.isEmpty ? 0 : (items.length - 1)) * AppSpacing.lg;

    return SizedBox(
      height: gridHeight,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, __) => AppGap.lg(),
        itemBuilder: (context, index) {
          return SizedBox(
            height: itemHeight,
            child: _buildWiFiCard(items, index, canBeDisabled),
          );
        },
      ),
    );
  }

  Widget _buildWiFiCard(
    List items,
    int index,
    bool canBeDisabled, {
    EdgeInsetsGeometry? padding,
  }) {
    final item = items[index];
    final visibilityKey = '${item.ssid}${item.radios.join()}${item.isGuest}';
    final isVisible = toolTipVisible[visibilityKey] ?? false;

    return WiFiCard(
      tooltipVisible: isVisible,
      item: item,
      index: index,
      canBeDisabled: canBeDisabled,
      onTooltipVisibilityChanged: (visible) {
        setState(() {
          // Hide all other tooltips when showing one
          if (visible) {
            for (var key in toolTipVisible.keys) {
              toolTipVisible[key] = false;
            }
          }
          toolTipVisible[visibilityKey] = visible;
        });
      },
      padding: padding,
    );
  }
}
