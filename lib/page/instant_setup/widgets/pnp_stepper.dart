import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacygui_widgets/widgets/stepper/app_stepper.dart';

class PnpStepper extends ConsumerStatefulWidget {
  final List<PnpStep> steps;
  final StepperType stepperType;
  final VoidCallback? onLastStep;
  final void Function(
      int index,
      PnpStep step,
      ({void Function() stepCancel, void Function() stepContinue}) stepController)?
      onStepChanged;

  const PnpStepper({
    super.key,
    required this.steps,
    this.stepperType = StepperType.horizontal,
    this.onLastStep,
    this.onStepChanged,
  });

  @override
  ConsumerState<PnpStepper> createState() => _PnpStepperState();
}

class _PnpStepperState extends ConsumerState<PnpStepper> {
  int _index = 0;

  @override
  void initState() {
    super.initState();

    Future.doWhile(() => !mounted).then((value) async {
      if (widget.steps.isNotEmpty) {
        await widget.steps[0].onInit(ref);
        widget.onStepChanged?.call(_index, widget.steps[_index],
            (stepCancel: onStepCancel, stepContinue: onStepContinue));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppStepper(
        type: widget.stepperType,
        controlsBuilder: widget.steps.isNotEmpty
            ? widget.steps[_index].controlBuilder(_index, _index)
            : null,
        currentStep: _index,
        onStepCancel: onStepCancel,
        onStepContinue: onStepContinue,
        steps: widget.steps
            .map((e) => e.resolveStep(
                context: context, currentIndex: _index, stepIndex: widget.steps.indexOf(e)))
            .toList());
  }

  PnpStep get currentStep => widget.steps[_index];

  void onStepContinue() async {
    if (_index + 1 >= widget.steps.length) {
      // last step
      widget.onLastStep?.call();
    } else {
      setState(() {
        _index += 1;
      });
      widget.onStepChanged?.call(_index, widget.steps[_index],
          (stepCancel: onStepCancel, stepContinue: onStepContinue));
      await widget.steps[_index].onInit(ref);
    }
  }

  void onStepCancel() {
    if (_index > 0) {
      setState(() {
        _index -= 1;
      });
      widget.onStepChanged?.call(_index, widget.steps[_index],
          (stepCancel: onStepCancel, stepContinue: onStepContinue));
    }
  }
}