import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/page/nodes/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_device_list_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Quick actions panel for the dashboard.
///
/// Supports three display modes:
/// - [DisplayMode.compact]: Minimal toggles only
/// - [DisplayMode.normal]: Standard toggle list
/// - [DisplayMode.expanded]: Expanded toggles with descriptions
class DashboardQuickPanel extends ConsumerStatefulWidget {
  const DashboardQuickPanel({
    super.key,
    this.displayMode = DisplayMode.normal,
    this.useAppCard = true,
  });

  /// The display mode for this widget
  final DisplayMode displayMode;

  /// Whether to wrap the content in an AppCard (default true).
  final bool useAppCard;

  @override
  ConsumerState<DashboardQuickPanel> createState() =>
      _DashboardQuickPanelState();
}

class _DashboardQuickPanelState extends ConsumerState<DashboardQuickPanel> {
  @override
  Widget build(BuildContext context) {
    return DashboardLoadingWrapper(
      loadingHeight: _getLoadingHeight(),
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  double _getLoadingHeight() {
    return switch (widget.displayMode) {
      DisplayMode.compact => 100,
      DisplayMode.normal => 150,
      DisplayMode.expanded => 200,
    };
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return switch (widget.displayMode) {
      DisplayMode.compact => _buildCompactView(context, ref),
      DisplayMode.normal => _buildNormalView(context, ref),
      DisplayMode.expanded => _buildExpandedView(context, ref),
    };
  }

  /// Compact view: Icon-only toggles in a row
  Widget _buildCompactView(BuildContext context, WidgetRef ref) {
    final privacyState = ref.watch(instantPrivacyProvider);
    final nodeLightState = ref.watch(nodeLightSettingsProvider);
    final master = ref.watch(instantTopologyProvider).root.children.first;
    bool isSupportNodeLight = serviceHelper.isSupportLedMode();
    bool isCognitive = isCognitiveMeshRouter(
        modelNumber: master.data.model,
        hardwareVersion: master.data.hardwareVersion);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Privacy toggle
        _compactToggle(
          context,
          icon: Icons.shield,
          isActive: privacyState.status.mode == MacFilterMode.allow,
          label: loc(context).instantPrivacy,
          onTap: () => context.pushNamed(RouteNamed.menuInstantPrivacy),
          onToggle: (value) {
            showInstantPrivacyConfirmDialog(context, value).then((isOk) {
              if (isOk != true) return;
              final notifier = ref.read(instantPrivacyProvider.notifier);
              if (value) {
                final macAddressList = ref
                    .read(instantPrivacyDeviceListProvider)
                    .map((e) => e.macAddress.toUpperCase())
                    .toList();
                notifier.setMacAddressList(macAddressList);
              }
              notifier.setEnable(value);
              if (context.mounted) {
                doSomethingWithSpinner(context, notifier.save());
              }
            });
          },
        ),
        // Night mode toggle
        if (isCognitive && isSupportNodeLight)
          _compactToggle(
            context,
            icon: AppFontIcons.darkMode,
            isActive: nodeLightState.isNightModeEnable,
            label: loc(context).nightMode,
            onToggle: (value) {
              final notifier = ref.read(nodeLightSettingsProvider.notifier);
              if (value) {
                notifier.setSettings(NodeLightSettings.night());
              } else {
                notifier.setSettings(NodeLightSettings.on());
              }
              doSomethingWithSpinner(context, notifier.save());
            },
          ),
      ],
    );

    if (widget.useAppCard) {
      return AppCard(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: content,
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: content,
    );
  }

  Widget _compactToggle(
    BuildContext context, {
    required IconData icon,
    required bool isActive,
    required String label,
    VoidCallback? onTap,
    required void Function(bool) onToggle,
  }) {
    return Tooltip(
      message: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: AppIcon.font(
              icon,
              size: 24,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppGap.xs(),
          SizedBox(
            width: 48,
            height: 28,
            child: FittedBox(
              child: AppSwitch(
                value: isActive,
                onChanged: onToggle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Normal view: Standard toggle list (existing implementation)
  Widget _buildNormalView(BuildContext context, WidgetRef ref) {
    final privacyState = ref.watch(instantPrivacyProvider);
    final nodeLightState = ref.watch(nodeLightSettingsProvider);
    final master = ref.watch(instantTopologyProvider).root.children.first;
    bool isSupportNodeLight = serviceHelper.isSupportLedMode();
    bool isCognitive = isCognitiveMeshRouter(
        modelNumber: master.data.model,
        hardwareVersion: master.data.hardwareVersion);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        toggleTileWidget(
            title: loc(context).instantPrivacy,
            value: privacyState.status.mode == MacFilterMode.allow,
            leading: AppBadge(
              label: 'BETA',
              color: Theme.of(context)
                  .extension<AppColorScheme>()!
                  .semanticWarning,
            ),
            onTap: () {
              context.pushNamed(RouteNamed.menuInstantPrivacy);
            },
            onChanged: (value) {
              showInstantPrivacyConfirmDialog(context, value).then((isOk) {
                if (isOk != true) {
                  return;
                }
                final notifier = ref.read(instantPrivacyProvider.notifier);
                if (value) {
                  final macAddressList = ref
                      .read(instantPrivacyDeviceListProvider)
                      .map((e) => e.macAddress.toUpperCase())
                      .toList();
                  notifier.setMacAddressList(macAddressList);
                }
                notifier.setEnable(value);
                if (context.mounted) {
                  doSomethingWithSpinner(context, notifier.save());
                }
              });
            },
            tips: loc(context).instantPrivacyInfo,
            semantics: 'quick instant privacy switch'),
        if (isCognitive && isSupportNodeLight) ...[
          const Divider(
            height: 48,
            thickness: 1.0,
          ),
          toggleTileWidget(
              title: loc(context).nightMode,
              value: nodeLightState.isNightModeEnable,
              subTitle:
                  ref.read(nodeLightSettingsProvider.notifier).currentStatus ==
                          NodeLightStatus.night
                      ? loc(context).nightModeTime
                      : ref
                                  .read(nodeLightSettingsProvider.notifier)
                                  .currentStatus ==
                              NodeLightStatus.off
                          ? loc(context).allDayOff
                          : null,
              onChanged: (value) {
                final notifier = ref.read(nodeLightSettingsProvider.notifier);
                if (value) {
                  notifier.setSettings(NodeLightSettings.night());
                } else {
                  notifier.setSettings(NodeLightSettings.on());
                }
                doSomethingWithSpinner(context, notifier.save());
              },
              tips: loc(context).nightModeTips,
              semantics: 'quick night mode switch'),
        ]
      ],
    );

    if (widget.useAppCard) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: content,
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: content,
    );
  }

  /// Expanded view: Toggles with full descriptions
  Widget _buildExpandedView(BuildContext context, WidgetRef ref) {
    final privacyState = ref.watch(instantPrivacyProvider);
    final nodeLightState = ref.watch(nodeLightSettingsProvider);
    final master = ref.watch(instantTopologyProvider).root.children.first;
    bool isSupportNodeLight = serviceHelper.isSupportLedMode();
    bool isCognitive = isCognitiveMeshRouter(
        modelNumber: master.data.model,
        hardwareVersion: master.data.hardwareVersion);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _expandedToggleTile(
          context,
          title: loc(context).instantPrivacy,
          description: loc(context).instantPrivacyInfo,
          value: privacyState.status.mode == MacFilterMode.allow,
          onTap: () => context.pushNamed(RouteNamed.menuInstantPrivacy),
          onChanged: (value) {
            showInstantPrivacyConfirmDialog(context, value).then((isOk) {
              if (isOk != true) return;
              final notifier = ref.read(instantPrivacyProvider.notifier);
              if (value) {
                final macAddressList = ref
                    .read(instantPrivacyDeviceListProvider)
                    .map((e) => e.macAddress.toUpperCase())
                    .toList();
                notifier.setMacAddressList(macAddressList);
              }
              notifier.setEnable(value);
              if (context.mounted) {
                doSomethingWithSpinner(context, notifier.save());
              }
            });
          },
        ),
        if (isCognitive && isSupportNodeLight) ...[
          const Divider(height: 32),
          _expandedToggleTile(
            context,
            title: loc(context).nightMode,
            description: loc(context).nightModeTips,
            value: nodeLightState.isNightModeEnable,
            onChanged: (value) {
              final notifier = ref.read(nodeLightSettingsProvider.notifier);
              if (value) {
                notifier.setSettings(NodeLightSettings.night());
              } else {
                notifier.setSettings(NodeLightSettings.on());
              }
              doSomethingWithSpinner(context, notifier.save());
            },
          ),
        ]
      ],
    );

    if (widget.useAppCard) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: content,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: content,
    );
  }

  Widget _expandedToggleTile(
    BuildContext context, {
    required String title,
    required String description,
    required bool value,
    VoidCallback? onTap,
    required void Function(bool) onChanged,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(title),
                AppGap.sm(),
                AppText.bodySmall(
                  description,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppGap.lg(),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget toggleTileWidget({
    required String title,
    Widget? leading,
    String? subTitle,
    VoidCallback? onTap,
    required bool value,
    required void Function(bool value)? onChanged,
    String? tips,
    String? semantics,
  }) {
    return SizedBox(
      height: 60,
      child: InkWell(
        focusColor: Colors.transparent,
        splashColor: Theme.of(context).colorScheme.primary,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppText.labelLarge(title),
                      if (subTitle != null) AppText.bodySmall(subTitle),
                    ],
                  ),
                  if (leading != null) ...[
                    SizedBox(
                      width: AppSpacing.xs,
                    ),
                    leading,
                  ],
                  SizedBox(
                    width: AppSpacing.sm,
                  ),
                  if (tips != null)
                    Tooltip(
                      message: tips,
                      child: Icon(
                        Icons.info_outline,
                        semanticLabel: '{$semantics} icon',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                ],
              ),
            ),
            AppSwitch(
              key: ValueKey(semantics),
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
