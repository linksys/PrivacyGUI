import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/wifi_card.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_enums.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
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
  @override
  double getLoadingHeight(DisplayMode mode) {
    const itemHeight = 176.0;
    final mainSpacing =
        AppLayoutConfig.gutter(MediaQuery.of(context).size.width);
    return switch (mode) {
      DisplayMode.compact => 80,
      DisplayMode.normal => itemHeight * 2 + mainSpacing,
      DisplayMode.expanded => itemHeight * 3 + mainSpacing * 2,
    };
  }

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(dashboardHomeProvider.select((value) => value.wifis));
    if (items.isEmpty) return const SizedBox();

    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.md),
            child: AppInkWell(
              customColor: Colors.transparent,
              customBorderWidth: 0,
              onTap: () => _handleWifiToggled(item),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AppSurface(
                variant: SurfaceVariant.base,
                borderRadius: AppRadius.md,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.isGuest ? Icons.wifi_lock : Icons.wifi,
                          size: 16,
                          color: item.isEnabled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.38),
                        ),
                        if (!item.isGuest && item.radios.isNotEmpty) ...[
                          AppGap.sm(),
                          Expanded(
                            child: AppText.labelSmall(
                              item.radios
                                  .map((e) => e.replaceAll('RADIO_', ''))
                                  .join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        if (item.numOfConnectedDevices > 0) ...[
                          AppGap.xs(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.numOfConnectedDevices}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    AppGap.xs(),
                    AppText.labelMedium(
                      item.ssid,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleWifiToggled(DashboardWiFiUIModel item) async {
    final result = await _showSwitchWifiDialog(item);
    if (result) {
      if (!mounted) return;
      showSpinnerDialog(context);
      final wifiProvider = ref.read(wifiBundleProvider.notifier);
      await wifiProvider.fetch();

      if (item.isGuest) {
        await _saveGuestWifi(wifiProvider, !item.isEnabled);
      } else {
        await _saveMainWifi(wifiProvider, item.radios, !item.isEnabled);
      }
    }
  }

  Future<void> _saveGuestWifi(
      WifiBundleNotifier wifiProvider, bool value) async {
    wifiProvider.setWiFiEnabled(value);
    await wifiProvider.save().then((_) {
      if (mounted) context.pop();
    }).catchError((error, stackTrace) {
      if (!mounted) return;
      showRouterNotFoundAlert(context, ref, onComplete: () => context.pop());
    }, test: (error) => error is ServiceSideEffectError).onError((error, _) {
      if (mounted) context.pop();
    });
  }

  Future<void> _saveMainWifi(
      WifiBundleNotifier wifiProvider, List<String> radios, bool value) async {
    await wifiProvider
        .saveToggleEnabled(radios: radios, enabled: value)
        .then((_) {
      if (mounted) context.pop();
    }).catchError((error, stackTrace) {
      if (!mounted) return;
      showRouterNotFoundAlert(context, ref, onComplete: () => context.pop());
    }, test: (error) => error is ServiceSideEffectError).onError((error, _) {
      if (mounted) context.pop();
    });
  }

  Future<bool> _showSwitchWifiDialog(DashboardWiFiUIModel item) async {
    return await showSimpleAppDialog(
      context,
      title: loc(context).wifiListSaveModalTitle,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(loc(context).wifiListSaveModalDesc),
          if (!item.isGuest && item.isEnabled)
            ..._disableGuestBandWarning(item),
          AppGap.lg(),
          AppText.bodyMedium(loc(context).doYouWantToContinue),
        ],
      ),
      actions: [
        AppButton.text(label: loc(context).cancel, onTap: () => context.pop()),
        AppButton.text(label: loc(context).ok, onTap: () => context.pop(true)),
      ],
    );
  }

  List<Widget> _disableGuestBandWarning(DashboardWiFiUIModel item) {
    final guestWifiItem =
        ref.read(dashboardHomeProvider).wifis.firstWhere((e) => e.isGuest);
    final currentRadio = item.radios.first;
    return guestWifiItem.isEnabled
        ? [
            AppGap.sm(),
            AppText.labelMedium(
              loc(context).disableBandWarning(
                  WifiRadioBand.getByValue(currentRadio).bandName),
            )
          ]
        : [];
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
