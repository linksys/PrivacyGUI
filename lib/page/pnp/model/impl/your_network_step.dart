import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_widgets/theme/custom_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/node_list_card.dart';

class YourNetworkStep extends PnpStep {
  late final TextEditingController _textEditController;

  YourNetworkStep({
    required super.index,
    super.saveChanges,
  });

  @override
  String nextLable(BuildContext context) => getAppLocalizations(context).done;

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);
    pnp.setStepStatus(index, status: StepViewStatus.loading);
    await pnp.fetchDevices();
    pnp.setStepStatus(index, status: StepViewStatus.data);
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {};
  }

  @override
  void onDispose() {
    _textEditController.dispose();
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
          const AppGap.regular(),
          Column(
            children: [
              ...state.childNodes
                      .map((e) => AppNodeListCard(
                          leading: CustomTheme.of(context)
                              .images
                              .devices
                              .getByName(routerIconTest(e.toMap())),
                          title: e.getDeviceLocation(),
                          trailing: null))
                      .toList() ??
                  []
            ],
          ),
          const AppGap.regular(),
          AppTextButton(
            loc(context).addNodes,
            icon: LinksysIcons.add,
            onTap: () async {
              final result =
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
