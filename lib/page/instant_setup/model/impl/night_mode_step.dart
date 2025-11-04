import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

/// A PnP (Plug and Play) step for configuring Night Mode settings.
///
/// This step allows the user to enable/disable the Night Mode feature,
/// which typically controls the LED lights on the router.
class NightModeStep extends PnpStep {
  NightModeStep({
    super.saveChanges,
  }) : super(stepId: PnpStepId.nightMode);

  @override
  Future<void> onInit(WidgetRef ref) async {
    super.onInit(ref);
    // Initial validation, assuming always valid if supported.
    // This sets the step status to data, indicating it's ready for user interaction.
    Future(() => pnp.setStepStatus(stepId, status: StepViewStatus.data));
    // Determine if the "Next" button should be enabled.
    // If saveChanges is null, it means this is not the last step, so "Next" is enabled.
    canGoNext(saveChanges == null);
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    // Return the current state of the Night Mode toggle.
    return {
      'isEnabled': pnp.getStepState(stepId).getData<bool>('isEnabled', false)
    };
  }

  @override
  void onDispose() {
    // No specific controllers or resources to dispose of in this step.
  }

  @override
  Map<String, dynamic> getValidationData() {
    // The only data to validate is the enabled state of Night Mode.
    return {
      'isEnabled': pnp.getStepState(stepId).getData<bool>('isEnabled', false),
    };
  }

  @override
  Map<String, List<ValidationRule>> getValidationRules() {
    // Night mode has no complex validation rules; it's always considered valid
    // if the capability is present on the device.
    return {};
  }

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    // Watch the step state for changes to the Night Mode toggle.
    final stepState =
        ref.watch(pnpProvider.select((s) => s.stepStateList[stepId])) ??
            const PnpStepState(status: StepViewStatus.data, data: {});
    final isEnabled = stepState.getData<bool>('isEnabled', false);

    // Determine the description text based on whether Night Mode is enabled.
    final desc = isEnabled
        ? loc(context).nightModeOnDesc
        : loc(context).nightModeOffDesc;

    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        explicitChildNodes: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle switch for Night Mode.
            AppSwitch(
              semanticLabel: 'node light',
              value: isEnabled,
              onChanged: (value) {
                // Update the step data and re-validate when the switch changes.
                pnp.setStepData(stepId, data: {'isEnabled': value});
                pnp.validateStep(this);
              },
            ),
            const AppGap.large3(),
            // Display the description text.
            AppText.bodyLarge(desc),
            const AppGap.medium(),
          ],
        ),
      ),
    );
  }

  @override
  String title(BuildContext context) => loc(context).nightMode;
}
