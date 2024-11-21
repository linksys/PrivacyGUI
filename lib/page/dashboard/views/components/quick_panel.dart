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
import 'package:privacy_gui/page/dashboard/views/components/shimmer.dart';
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

    return ShimmerContainer(
      isLoading: isLoading,
      child: AppCard(
        padding: EdgeInsets.all(Spacing.large2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            toggleTileWidget(
              title: loc(context).instantPrivacy,
              value: privacyState.mode == MacFilterMode.allow,
              onTap: () {
                context.pushNamed(RouteNamed.menuInstantPrivacy);
              },
              onChanged: (value) {
                final notifier = ref.read(instantPrivacyProvider.notifier);
                if (value) {
                  final macAddressList = ref
                      .read(instantPrivacyDeviceListProvider)
                      .map((e) => e.macAddress.toUpperCase())
                      .toList();
                  notifier.setMacAddressList(macAddressList);
                }
                notifier.setEnable(value);
                doSomethingWithSpinner(context, notifier.save());
              },
            ),
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
        ),
      ),
    );
  }

  Widget toggleTileWidget({
    required String title,
    String? subTitle,
    VoidCallback? onTap,
    required bool value,
    required void Function(bool value) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(title),
            if (subTitle != null) AppText.bodySmall(subTitle),
          ],
        ),
        AppSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
