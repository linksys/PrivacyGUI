import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';

import 'package:privacy_gui/page/nodes/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_device_list_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic Quick Panel widget for custom layout (Bento Grid).
///
/// - Compact: Icon-only toggles in a row
/// - Normal: Standard toggle list
/// - Expanded: Toggles with full descriptions
class CustomQuickPanel extends DisplayModeConsumerStatefulWidget {
  const CustomQuickPanel({
    super.key,
    super.displayMode,
  });

  @override
  ConsumerState<CustomQuickPanel> createState() => _CustomQuickPanelState();
}

class _CustomQuickPanelState extends ConsumerState<CustomQuickPanel>
    with DisplayModeStateMixin<CustomQuickPanel> {
  @override
  double getLoadingHeight(DisplayMode mode) => switch (mode) {
        DisplayMode.compact => 80,
        DisplayMode.normal => 150,
        DisplayMode.expanded => 200,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    final privacyState = ref.watch(instantPrivacyProvider);
    final nodeLightState = ref.watch(nodeLightSettingsProvider);
    final (isCognitive, isSupportNodeLight) = _getNodeLightSupport(ref);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm, // Reduced from lg
        vertical: AppSpacing.xs, // Reduced from md
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _compactToggle(
            context,
            ref,
            icon: Icons.shield,
            isActive: privacyState.status.mode == MacFilterMode.allow,
            label: loc(context).instantPrivacy,
            onTap: () => context.pushNamed(RouteNamed.menuInstantPrivacy),
            onToggle: (value) => _handlePrivacyToggle(context, ref, value),
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<AppColorScheme>()!
                    .semanticWarning
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'BETA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .extension<AppColorScheme>()!
                          .semanticWarning,
                    ),
              ),
            ),
          ),
          if (isCognitive && isSupportNodeLight)
            _compactToggle(
              context,
              ref,
              icon: AppFontIcons.darkMode,
              isActive: nodeLightState.isNightModeEnabled,
              label: loc(context).nightMode,
              onToggle: (value) => _handleNightModeToggle(context, ref, value),
            ),
        ],
      ),
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    final privacyState = ref.watch(instantPrivacyProvider);
    final nodeLightState = ref.watch(nodeLightSettingsProvider);
    final (isCognitive, isSupportNodeLight) = _getNodeLightSupport(ref);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleTile(
            context,
            ref,
            title: loc(context).instantPrivacy,
            value: privacyState.status.mode == MacFilterMode.allow,
            tips: loc(context).instantPrivacyInfo,
            leading: AppBadge(
              label: 'BETA',
              color: Theme.of(context)
                  .extension<AppColorScheme>()!
                  .semanticWarning,
            ),
            onTap: () => context.pushNamed(RouteNamed.menuInstantPrivacy),
            onChanged: (value) => _handlePrivacyToggle(context, ref, value),
          ),
          if (isCognitive && isSupportNodeLight) ...[
            const Divider(height: 48, thickness: 1.0),
            _toggleTile(
              context,
              ref,
              title: loc(context).nightMode,
              value: nodeLightState.isNightModeEnabled,
              subTitle: _getNightModeSubtitle(context, ref),
              tips: loc(context).nightModeTips,
              onChanged: (value) => _handleNightModeToggle(context, ref, value),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    final privacyState = ref.watch(instantPrivacyProvider);
    final nodeLightState = ref.watch(nodeLightSettingsProvider);
    final (isCognitive, isSupportNodeLight) = _getNodeLightSupport(ref);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _expandedToggleTile(
            context,
            title: loc(context).instantPrivacy,
            description: loc(context).instantPrivacyInfo,
            value: privacyState.status.mode == MacFilterMode.allow,
            onTap: () => context.pushNamed(RouteNamed.menuInstantPrivacy),
            onChanged: (value) => _handlePrivacyToggle(context, ref, value),
            badge: AppBadge(
              label: 'BETA',
              color: Theme.of(context)
                  .extension<AppColorScheme>()!
                  .semanticWarning,
            ),
          ),
          if (isCognitive && isSupportNodeLight) ...[
            const Divider(height: 32),
            _expandedToggleTile(
              context,
              title: loc(context).nightMode,
              description: loc(context).nightModeTips,
              value: nodeLightState.isNightModeEnabled,
              onChanged: (value) => _handleNightModeToggle(context, ref, value),
            ),
          ]
        ],
      ),
    );
  }

  // Helper methods
  (bool, bool) _getNodeLightSupport(WidgetRef ref) {
    final master = ref.watch(instantTopologyProvider).root.children.first;
    final isSupportNodeLight = serviceHelper.isSupportLedMode();
    final isCognitive = isCognitiveMeshRouter(
      modelNumber: master.data.model,
      hardwareVersion: master.data.hardwareVersion,
    );
    return (isCognitive, isSupportNodeLight);
  }

  String? _getNightModeSubtitle(BuildContext context, WidgetRef ref) {
    final status = ref.read(nodeLightSettingsProvider.notifier).currentStatus;
    return switch (status) {
      NodeLightStatus.night => loc(context).nightModeTime,
      NodeLightStatus.off => loc(context).allDayOff,
      _ => null,
    };
  }

  void _handlePrivacyToggle(BuildContext context, WidgetRef ref, bool value) {
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
  }

  void _handleNightModeToggle(BuildContext context, WidgetRef ref, bool value) {
    final notifier = ref.read(nodeLightSettingsProvider.notifier);
    final state = ref.read(nodeLightSettingsProvider);
    if (value) {
      notifier.setSettings(
          state.copyWith(isNightModeEnabled: true, allDayOff: false));
    } else {
      notifier.setSettings(
          state.copyWith(isNightModeEnabled: false, allDayOff: false));
    }
    doSomethingWithSpinner(context, notifier.save());
  }

  // UI Components
  Widget _compactToggle(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required bool isActive,
    required String label,
    VoidCallback? onTap,
    required void Function(bool) onToggle,
    Widget? badge,
  }) {
    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AppIcon.font(
                  icon,
                  size: 20,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                if (badge != null)
                  Positioned(
                    top: -8,
                    right: -8, // Align to top right corner
                    child: badge,
                  ),
              ],
            ),
          ),
          AppGap.sm(),
          SizedBox(
            width: 36,
            height: 24,
            child: FittedBox(
              child: AppSwitch(value: isActive, onChanged: onToggle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required bool value,
    Widget? leading,
    String? subTitle,
    String? tips,
    VoidCallback? onTap,
    required void Function(bool) onChanged,
  }) {
    return SizedBox(
      height: 60,
      child: InkWell(
        focusColor: Colors.transparent,
        splashColor: Theme.of(context).colorScheme.primary,
        onTap: onTap,
        child: Row(
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
                    const SizedBox(width: AppSpacing.xs),
                    leading,
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  if (tips != null)
                    Tooltip(
                      message: tips,
                      child: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            AppSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _expandedToggleTile(
    BuildContext context, {
    required String title,
    required String description,
    required bool value,
    VoidCallback? onTap,
    required void Function(bool) onChanged,
    Widget? badge,
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
                Row(
                  children: [
                    AppText.labelLarge(title),
                    if (badge != null) ...[
                      AppGap.sm(),
                      badge,
                    ],
                  ],
                ),
                AppGap.sm(),
                AppText.bodySmall(
                  description,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  maxLines: 4,
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
}
