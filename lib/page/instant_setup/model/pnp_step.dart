import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

/// Enum representing the UI status of a PnP step.
enum StepViewStatus {
  data, // The step is ready for user input.
  error, // The step has a validation error.
  loading; // The step is processing.
}

/// A type-safe identifier for each step in the PnP wizard.
enum PnpStepId {
  personalWifi,
  guestWifi,
  nightMode,
  yourNetwork,
}

/// An abstract class defining the contract for a single step in the PnP wizard.
/// This follows the Strategy Pattern, where each concrete step implements this interface.
abstract class PnpStep {
  /// The unique identifier for this PnP step.
  final PnpStepId stepId;

  /// An optional callback function to save changes, typically used for the final step.
  final Future Function()? saveChanges;

  /// A reference to the [BasePnpNotifier] for interacting with the PnP state.
  late final BasePnpNotifier pnp;

  /// Internal flag to control the "Next" button's enabled state.
  bool _canGoNext = true;

  /// Internal flag to control the "Back" button's enabled state.
  bool _canBack = true;

  /// Internal flag to track if the [onInit] method has been called.
  bool _init = false;

  /// Returns true if the `onInit` method has been called.
  bool get isInit => _init;

  PnpStep({required this.stepId, this.saveChanges});

  /// The title of the step, displayed in the stepper UI.
  String title(BuildContext context);

  /// The label for the "Next" button. Can be overridden for custom text (e.g., "Finish").
  String nextLable(BuildContext context) => loc(context).next;

  /// The label for the "Back" button.
  String previousLable(BuildContext context) => loc(context).back;

  /// Saves the data collected in this step to the central [PnpState].
  /// This is called internally when the user proceeds to the next step.
  @protected
  Future<void> save(WidgetRef ref, Map<String, dynamic> data) async {
    logger.d('[PnP]: $runtimeType - Saving data: $data');
    pnp.setStepData(stepId, data: data);
    // If a global save function is provided (for last step), call it.
    await saveChanges?.call();
  }

  /// Allows a step to dynamically enable/disable the "Next" button.
  void canGoNext(bool value) {
    _canGoNext = value;
  }

  /// Allows a step to dynamically enable/disable the "Back" button.
  void canBack(bool value) {
    _canBack = value;
  }

  /// Initializes the step. This is called when the step becomes active.
  /// It's used for pre-fetching data or initializing controllers.
  @mustCallSuper
  Future<void> onInit(WidgetRef ref) async {
    if (_init) return;
    logger.d('[PnP]: $runtimeType - onInit');
    pnp = ref.read(pnpProvider.notifier);
    _init = true;
  }

  /// Called when the user clicks the "Next" button.
  /// Implementations should perform final validation and return the data to be saved.
  /// Throwing an exception here will trigger the [onError] callback.
  Future<Map<String, dynamic>> onNext(WidgetRef ref);

  /// Triggered when an error occurs during the `onNext` or `save` flow.
  void onError(WidgetRef ref, Object? error, StackTrace stackTrace) {
    logger.e('[PnP]: $runtimeType - Error occurred.', error: error, stackTrace: stackTrace);
    pnp.setStepError(stepId, error: error);
  }

  /// Called when the entire PnP wizard page is disposed.
  /// Used for cleaning up resources like TextEditingControllers.
  void onDispose() {}

  /// Returns a map of data to be validated.
  Map<String, dynamic> getValidationData() {
    return {};
  }

  /// Returns a map of validation rules for the data.
  Map<String, List<ValidationRule>> getValidationRules() {
    return {};
  }

  /// Builds the UI for the step's controls (e.g., Next/Back buttons).
  ControlsWidgetBuilder controlBuilder(int currentIndex, int stepIndex) =>
      (BuildContext context, ControlsDetails details) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Consumer(builder: (context, ref, child) {
            final status = ref
                    .watch(pnpProvider.select((value) => value.stepStateList))[
                        stepId]
                    ?.status ??
                StepViewStatus.loading;
            return Row(
              children: [
                if (_canBack) ...[
                  AppTextButton(
                    previousLable(context),
                    onTap: (currentIndex == 0 ||
                            status == StepViewStatus.loading ||
                            !_canBack)
                        ? null
                        : details.onStepCancel,
                  ),
                  const AppGap.medium(),
                ],
                AppFilledButton(
                  key: const Key('pnp_stepper_next_button'),
                  nextLable(context),
                  onTap: status != StepViewStatus.data
                      ? null
                      : () {
                          logger.d('[PnP]: $runtimeType - Next button tapped.');
                          onNext(ref)
                              .then((data) async => await save(ref, data))
                              .then((_) {
                            if (_canGoNext) {
                              logger.d(
                                  '[PnP]: $runtimeType - Proceeding to next step.');
                              details.onStepContinue?.call();
                            }
                          }).onError((error, stackTrace) {
                            onError(ref, error, stackTrace);
                            return null;
                          });
                        },
                ),
              ],
            );
          }),
        );
      };

  /// The main UI content for this step.
  Widget content(
      {required BuildContext context, required WidgetRef ref, Widget? child});

  /// A default loading view shown while the step is initializing.
  Widget loadingView() {
    return const SizedBox(
      height: 240,
      child: Center(
        child: AppSpinner(),
      ),
    );
  }

  /// A wrapper for the step's content that handles showing the loading view.
  Widget _contentWrapping() => Consumer(builder: (context, ref, child) {
        final status = ref
                .watch(
                    pnpProvider.select((value) => value.stepStateList))[stepId]
                ?.status ??
            StepViewStatus.data;

        bool isLoading = status == StepViewStatus.loading || !_init;
        return isLoading
            ? loadingView()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    children: [
                      AppText.titleLarge(title(context)),
                    ],
                  ),
                  const AppGap.large3(),
                  content(context: context, ref: ref, child: child),
                ],
              );
      });

  /// Resolves this step object into a [Step] widget for the Flutter Stepper.
  Step resolveStep({
    required BuildContext context,
    required int currentIndex,
    required int stepIndex,
  }) =>
      Step(
        title: AppText.labelMedium(title(context)),
        content: _contentWrapping(),
        isActive: currentIndex == stepIndex,
        state: checkState(currentIndex, stepIndex),
      );

  /// Determines the visual state of the step icon in the stepper.
  StepState checkState(int currentIndex, int stepIndex) {
    if (currentIndex == stepIndex) {
      return StepState.editing;
    } else if (currentIndex > stepIndex) {
      return StepState.complete;
    } else {
      return StepState.indexed;
    }
  }
}