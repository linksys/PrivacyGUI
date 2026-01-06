import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/page/nodes/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_device_list_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';
import 'package:ui_kit_library/ui_kit.dart';

class DashboardQuickPanel extends ConsumerStatefulWidget {
  const DashboardQuickPanel({super.key});

  @override
  ConsumerState<DashboardQuickPanel> createState() =>
      _DashboardQuickPanelState();
}

class _DashboardQuickPanelState extends ConsumerState<DashboardQuickPanel> {
  @override
  Widget build(BuildContext context) {
    final privacyState = ref.watch(instantPrivacyProvider);
    final nodeLightState = ref.watch(nodeLightSettingsProvider);

    final isLoading =
        (ref.watch(pollingProvider).value?.isReady ?? false) == false;
    final master = isLoading
        ? null
        : ref.watch(instantTopologyProvider).root.children.first;
    bool isSupportNodeLight = serviceHelper.isSupportLedMode();
    bool isCognitive = isCognitiveMeshRouter(
        modelNumber: master?.data.model ?? '',
        hardwareVersion: master?.data.hardwareVersion ?? '1');

    return isLoading
        ? AppCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
                width: double.infinity,
                height: 150,
                child: const LoadingTile()))
        : AppCard(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Column(
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
                      showInstantPrivacyConfirmDialog(context, value)
                          .then((isOk) {
                        if (isOk != true) {
                          return;
                        }
                        final notifier =
                            ref.read(instantPrivacyProvider.notifier);
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
                      subTitle: ref
                                  .read(nodeLightSettingsProvider.notifier)
                                  .currentStatus ==
                              NodeLightStatus.night
                          ? loc(context).nightModeTime
                          : ref
                                      .read(nodeLightSettingsProvider.notifier)
                                      .currentStatus ==
                                  NodeLightStatus.off
                              ? loc(context).allDayOff
                              : null,
                      onChanged: (value) {
                        final notifier =
                            ref.read(nodeLightSettingsProvider.notifier);
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
