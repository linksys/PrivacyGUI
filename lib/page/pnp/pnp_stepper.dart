import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_widgets/widgets/stepper/app_stepper.dart';

class PnpStepper extends ConsumerStatefulWidget {
  final List<PnpStep> steps;
  final StepperType stepperType;
  final VoidCallback? onLastStep;

  const PnpStepper({
    super.key,
    required this.steps,
    this.stepperType = StepperType.horizontal,
    this.onLastStep,
  });

  @override
  ConsumerState<PnpStepper> createState() => _PnpStepperState();
}

class _PnpStepperState extends ConsumerState<PnpStepper> {
  int _index = 0;

  @override
  void initState() {
    super.initState();

    Future.doWhile(() => !mounted).then((value) {
      widget.steps[0].onInit(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppStepper(
        type: widget.stepperType,
        controlsBuilder: widget.steps[_index].controlBuilder(_index),
        currentStep: _index,
        onStepCancel: () {
          if (_index > 0) {
            setState(() {
              _index -= 1;
            });
          }
        },
        onStepContinue: () async {
          if (_index + 1 >= widget.steps.length) {
            // last step
            widget.onLastStep?.call();
          } else {
            setState(() {
              _index += 1;
            });
            await widget.steps[_index].onInit(ref);
          }
        },
        steps: widget.steps
            .map((e) => e.resolveStep(context: context, currentIndex: _index))
            .toList());
  }

  PnpStep get currentStep => widget.steps[_index];
}
