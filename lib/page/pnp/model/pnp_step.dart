import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/progress_bar/spinner.dart';

enum StepViewStatus {
  data,
  error,
  loading;
}

abstract class PnpStep {
  final int index;

  PnpStep({required this.index});

  // Title for displaying on the stepper
  String title(BuildContext context);
  // Override to custom the next copy
  String nextLable(BuildContext context) => getAppLocalizations(context).next;
  // Override to custom the back copy
  String previousLable(BuildContext context) => 'back';

  /// Save the data to [PnpProvider] when the next button been clicked.
  /// The [data] is coming from [onNext].
  @protected
  void save(WidgetRef ref, Map<String, dynamic> data) {
    ref.read(pnpProvider.notifier).setStepData(index, data: data);
  }

  bool Function() canGoNext = () => true;

  /// Init this step, override it if there has pre-process data.
  Future<void> onInit(WidgetRef ref) async {
    logger.d('$runtimeType: onInit');
    ref
        .read(pnpProvider.notifier)
        .setStepStatus(index, status: StepViewStatus.loading);

    await Future.delayed(const Duration(seconds: 1));
    ref
        .read(pnpProvider.notifier)
        .setStepStatus(index, status: StepViewStatus.data);
  }

  /// Post-process data after clicked next button.
  /// For example, data validation check, to throw an exception to jump error state
  /// Return data will be stored in [PnpState]
  Future<Map<String, dynamic>> onNext(WidgetRef ref);

  /// Triggered when an error occurs during the next flow. (onNext, save)
  void onError(WidgetRef ref, Object? error, StackTrace stackTrace) {
    logger.d('PNP:: $runtimeType: error $error \n$stackTrace');
    ref.read(pnpProvider.notifier).setStepError(index, error: error);
  }

  /// the dispose hook when the whole page is disposing.
  void onDispose() {}

  ControlsWidgetBuilder controlBuilder(int currentIndex) =>
      (BuildContext context, ControlsDetails details) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Consumer(builder: (context, ref, child) {
            final status = ref
                    .watch(pnpProvider.select((value) => value.stepStateList))[
                        index]
                    ?.status ??
                StepViewStatus.loading;
            return Row(
              children: [
                AppTextButton(
                  previousLable(context),
                  onTap: (currentIndex == 0 || status == StepViewStatus.loading)
                      ? null
                      : details.onStepCancel,
                ),
                const AppGap.regular(),
                AppFilledButton(
                  nextLable(context),
                  onTap: status != StepViewStatus.data
                      ? null
                      : () {
                          onNext(ref)
                              .then((data) => save(ref, data))
                              .then((_) => details.onStepContinue?.call())
                              .onError((error, stackTrace) =>
                                  onError(ref, error, stackTrace));
                        },
                ),
              ],
            );
          }),
        );
      };

  Widget content(
      {required BuildContext context, required WidgetRef ref, Widget? child});
  Widget _contentWrapping() => Consumer(builder: (context, ref, child) {
        final status = ref
                .watch(
                    pnpProvider.select((value) => value.stepStateList))[index]
                ?.status ??
            StepViewStatus.loading;

        bool isLoading = status == StepViewStatus.loading;
        return isLoading
            ? const SizedBox(
                height: 240,
                child: Center(
                  child: AppSpinner(),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    children: [
                      AppText.titleLarge(title(context)),
                    ],
                  ),
                  const AppGap.big(),
                  content(context: context, ref: ref, child: child),
                ],
              );
      });
  Step resolveStep({
    required BuildContext context,
    required int currentIndex,
  }) =>
      Step(
        title: AppText.labelMedium(title(context)),
        content: _contentWrapping(),
        isActive: currentIndex == index,
        state: checkState(currentIndex),
      );

  StepState checkState(int currentIndex) {
    if (currentIndex == index) {
      return StepState.editing;
    } else if (currentIndex > index) {
      return StepState.complete;
    } else {
      return StepState.indexed;
    }
  }
}
