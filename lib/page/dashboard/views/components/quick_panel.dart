import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/status_label.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_device_list_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

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

    final isLoading = ref.watch(deviceManagerProvider).deviceList.isEmpty;

    final master = isLoading
        ? null
        : ref.watch(instantTopologyProvider).root.children.first;
    bool isSupportNodeLight = serviceHelper.isSupportLedMode();
    bool isCognitive = isCognitiveMeshRouter(
        modelNumber: master?.data.model ?? '',
        hardwareVersion: master?.data.hardwareVersion ?? '1');
    final isBridge = ref.watch(dashboardHomeProvider).isBridgeMode;

    return AppCard(
      padding: EdgeInsets.all(Spacing.large2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          toggleTileWidget(
              title: loc(context).instantPrivacy,
              value: privacyState.mode == MacFilterMode.allow,
              leading: betaLabel(),
              onTap: isBridge
                  ? null
                  : () {
                      context.pushNamed(RouteNamed.menuInstantPrivacy);
                    },
              onChanged: isBridge
                  ? null
                  : (value) {
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
                        doSomethingWithSpinner(context, notifier.save());
                      });
                    },
              semantics: 'quick instant privacy switch'),
          if (isCognitive && isSupportNodeLight) ...[
            const Divider(
              height: 48,
              thickness: 1.0,
            ),
            toggleTileWidget(
                title: loc(context).nightMode,
                value: nodeLightState.isNightModeEnable,
                subTitle: NodeLightStatus.getStatus(nodeLightState) ==
                        NodeLightStatus.night
                    ? loc(context).nightModeTime
                    : NodeLightStatus.getStatus(nodeLightState) ==
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
    String? semantics,
  }) {
    return SizedBox(
      height: 60,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading,
              AppGap.small2(),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(title),
                  if (subTitle != null) AppText.bodySmall(subTitle),
                ],
              ),
            ),
            AppSwitch(
              value: value,
              onChanged: onChanged,
              semanticLabel: semantics,
            ),
          ],
        ),
      ),
    );
  }
}