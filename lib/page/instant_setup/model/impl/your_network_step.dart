import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/node_list_card.dart';

class YourNetworkStep extends PnpStep {
  YourNetworkStep({
    super.saveChanges,
  }) : super(stepId: PnpStepId.yourNetwork) {
    canBack(false);
  }

  @override
  String nextLable(BuildContext context) => loc(context).done;

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);
    pnp.setStepStatus(stepId, status: StepViewStatus.loading);
    await pnp.fetchDevices();
    pnp.setStepStatus(stepId, status: StepViewStatus.data);
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {};
  }

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    final state = ref.watch(pnpProvider);
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(loc(context).pnpYourNetworkDesc),
          const AppGap.medium(),
          Column(
            children: [
              ...state.childNodes
                  .map((e) => AppNodeListCard(
                      leading: CustomTheme.of(context).getRouterImage(
                          routerIconTestByModel(modelNumber: e.modelNumber ?? ''), false),
                      title: e.getDeviceLocation(),
                      trailing: null))
                  .toList()
            ],
          ),
          const AppGap.medium(),
          AppTextButton(
            loc(context).addNodes,
            icon: LinksysIcons.add,
            onTap: () async {
              await context.pushNamed<bool?>(RouteNamed.addNodes, extra: {
                'callback': () {
                  saveChanges?.call();
                }
              });
              await pnp.fetchDevices();
            },
          ),
        ],
      ),
    );
  }

  @override
  String title(BuildContext context) => loc(context).pnpYourNetworkTitle;
}