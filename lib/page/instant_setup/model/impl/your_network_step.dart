import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/page/components/composed/app_node_list_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A PnP (Plug and Play) step that displays the user's network information,
/// specifically a list of connected nodes (routers/extenders).
///
/// This step also provides an option to add more nodes to the network.
class YourNetworkStep extends PnpStep {
  YourNetworkStep({
    super.saveChanges,
  }) : super(stepId: PnpStepId.yourNetwork) {
    // Disable the back button for this step as it's typically the final informational step.
    canBack(false);
  }

  @override
  String nextLable(BuildContext context) => loc(context).done;

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);
    // Set step status to loading while fetching device information.
    pnp.setStepStatus(stepId, status: StepViewStatus.loading);
    try {
      // Fetch the list of connected devices (child nodes).
      await pnp.fetchDevices();
      // Set step status to data once devices are fetched successfully.
      pnp.setStepStatus(stepId, status: StepViewStatus.data);
    } catch (e) {
      // If fetching devices fails, set step status to error.
      pnp.setStepStatus(stepId, status: StepViewStatus.error);
    }
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    // This step doesn't collect user input, so it returns an empty map.
    return {};
  }

  @override
  Map<String, dynamic> getValidationData() {
    // This step doesn't have user input that needs validation, it's more about displaying info.
    // We can return an empty map or relevant data if any future validation is needed.
    return {};
  }

  @override
  Map<String, List<ValidationRule>> getValidationRules() {
    // This step is considered valid as long as it's displayed, as there's no user input to validate.
    return {};
  }

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    // Watch for changes in the list of child nodes from the PnP provider.
    final childNodes =
        ref.watch(pnpProvider.select((state) => state.childNodes));
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(loc(context).pnpYourNetworkDesc),
          AppGap.lg(),
          // Display each connected child node as an AppNodeListCard.
          Column(
            children: [
              ...childNodes
                  .map((e) => AppNodeListCard(
                      leading: DeviceImageHelper.getRouterImage(
                          routerIconTestByModel(modelNumber: e.modelNumber)),
                      title: e.location,
                      trailing: null))
                  .toList()
            ],
          ),
          AppGap.lg(),
          // Button to navigate to the "Add Nodes" screen.
          AppButton.text(
            label: loc(context).addNodes,
            icon: AppIcon.font(AppFontIcons.add),
            onTap: () async {
              // Navigate to the Add Nodes screen and wait for its result.
              await context.pushNamed<bool?>(RouteNamed.pnpAddNodes, extra: {
                'callback': () {
                  saveChanges?.call();
                }
              });
              // After returning from Add Nodes, re-fetch devices and re-validate.
              await pnp.fetchDevices();
              // Re-validate after fetching devices, in case validation depends on childNodes
              pnp.validateStep(this);
            },
          ),
        ],
      ),
    );
  }

  @override
  String title(BuildContext context) => loc(context).pnpYourNetworkTitle;
}
