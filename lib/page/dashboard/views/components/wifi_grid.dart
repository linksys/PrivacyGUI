import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Grid displaying WiFi networks for the dashboard.
class DashboardWiFiGrid extends ConsumerStatefulWidget {
  const DashboardWiFiGrid({super.key});

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

    return SizedBox(
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
    );
  }

  Widget _buildWiFiCard(
    List items,
    int index,
    bool canBeDisabled,
  ) {
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
    );
  }
}
