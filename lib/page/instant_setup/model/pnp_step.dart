import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

enum StepViewStatus {
  data,
  error,
  loading;
}

abstract class PnpStep {
  final int index;
  final Future Function()? saveChanges;
  late final BasePnpNotifier pnp;
  bool _canGoNext = true;
  bool _canBack = true;
  bool _init = false;
  bool get isInit => _init;

  PnpStep({required this.index, this.saveChanges});

  // Title for displaying on the stepper
  String title(BuildContext context);
  // Override to custom the next copy
  String nextLable(BuildContext context) => loc(context).next;
  // Override to custom the back copy
  String previousLable(BuildContext context) => loc(context).back;

  /// Save the data to [PnpProvider] when the next button been clicked.
  /// The [data] is coming from [onNext].
  @protected
  Future save(WidgetRef ref, Map<String, dynamic> data) async {
    pnp.setStepData(index, data: data);
    await saveChanges?.call();
  }

  void canGoNext(bool value) {
    _canGoNext = value;
  }

  void canBack(bool value) {
    _canBack = value;
  }

  /// Init this step, override it if there has pre-process data.
  /// assign pnp
  @mustCallSuper
  Future<void> onInit(WidgetRef ref) async {
    logger.d('$runtimeType: onInit');
    pnp = ref.read(pnpProvider.notifier);
    _init = true;
  }

  /// Post-process data after clicked next button.
  /// For example, data validation check, to throw an exception to jump error state
  /// Return data will be stored in [PnpState]
  Future<Map<String, dynamic>> onNext(WidgetRef ref);

  /// Triggered when an error occurs during the next flow. (onNext, save)
  void onError(WidgetRef ref, Object? error, StackTrace stackTrace) {
    logger.e('[PnP]: $runtimeType', error: error, stackTrace: stackTrace);
    pnp.setStepError(index, error: error);
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
                  nextLable(context),
                  onTap: status != StepViewStatus.data
                      ? null
                      : () {
                          onNext(ref)
                              .then((data) async => await save(ref, data))
                              .then((_) {
                            if (_canGoNext) {
                              return details.onStepContinue?.call();
                            } else {
                              return;
                            }
                          }).onError((error, stackTrace) =>
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

  Widget loadingView() {
    return const SizedBox(
      height: 240,
      child: Center(
        child: AppSpinner(),
      ),
    );
  }

  Widget _contentWrapping() => Consumer(builder: (context, ref, child) {
        final status = ref
                .watch(
                    pnpProvider.select((value) => value.stepStateList))[index]
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
