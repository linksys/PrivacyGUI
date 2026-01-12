import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/wifi_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic WiFi Grid widget for custom layout (Bento Grid).
///
/// - Compact: Wrapped cards in minimal size
/// - Normal: 2-column grid
/// - Expanded: Single column with larger cards
class CustomWiFiGrid extends DisplayModeConsumerStatefulWidget {
  const CustomWiFiGrid({
    super.key,
    super.displayMode,
  });

  @override
  ConsumerState<CustomWiFiGrid> createState() => _CustomWiFiGridState();
}

class _CustomWiFiGridState extends ConsumerState<CustomWiFiGrid>
    with DisplayModeStateMixin<CustomWiFiGrid> {
  Map<String, bool> toolTipVisible = {};

  @override
  double getLoadingHeight(DisplayMode mode) {
    const itemHeight = 176.0;
    final mainSpacing =
        AppLayoutConfig.gutter(MediaQuery.of(context).size.width);
    return switch (mode) {
      DisplayMode.compact => itemHeight,
      DisplayMode.normal => itemHeight * 2 + mainSpacing,
      DisplayMode.expanded => itemHeight * 3 + mainSpacing * 2,
    };
  }

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(dashboardHomeProvider.select((value) => value.wifis));
    final canBeDisabled = _canDisableWiFi(ref, items);

    return SingleChildScrollView(
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: items.asMap().entries.map((entry) {
          return SizedBox(
            width: 180,
            child: _buildWiFiCard(items, entry.key, canBeDisabled,
                isCompact: true),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(dashboardHomeProvider.select((value) => value.wifis));
    final crossAxisCount =
        (context.isMobileLayout || context.isTabletLayout) ? 1 : 2;
    final mainSpacing =
        AppLayoutConfig.gutter(MediaQuery.of(context).size.width);
    const itemHeight = 176.0;
    final mainAxisCount = (items.length / crossAxisCount).ceil();
    final canBeDisabled = _canDisableWiFi(ref, items);

    final gridHeight = mainAxisCount * itemHeight +
        ((mainAxisCount == 0 ? 1 : mainAxisCount) - 1) * AppSpacing.lg;

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
          itemBuilder: (context, index) => SizedBox(
            height: itemHeight,
            child: _buildWiFiCard(items, index, canBeDisabled),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(dashboardHomeProvider.select((value) => value.wifis));
    const itemHeight = 200.0;
    final canBeDisabled = _canDisableWiFi(ref, items);

    final gridHeight = items.length * itemHeight +
        (items.isEmpty ? 0 : (items.length - 1)) * AppSpacing.lg;

    return SizedBox(
      height: gridHeight,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, __) => AppGap.lg(),
        itemBuilder: (context, index) => SizedBox(
          height: itemHeight,
          child: _buildWiFiCard(items, index, canBeDisabled),
        ),
      ),
    );
  }

  bool _canDisableWiFi(WidgetRef ref, List items) {
    final enabledWiFiCount =
        items.where((e) => !e.isGuest && e.isEnabled).length;
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;
    return enabledWiFiCount > 1 || hasLanPort;
  }

  Widget _buildWiFiCard(
    List items,
    int index,
    bool canBeDisabled, {
    bool isCompact = false,
  }) {
    final item = items[index];
    final visibilityKey = '${item.ssid}${item.radios.join()}${item.isGuest}';
    final isVisible = toolTipVisible[visibilityKey] ?? false;

    return WiFiCard(
      tooltipVisible: isVisible,
      item: item,
      index: index,
      canBeDisabled: canBeDisabled,
      isCompact: isCompact,
      onTooltipVisibilityChanged: (visible) {
        setState(() {
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
