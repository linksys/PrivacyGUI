import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class NightModeStep extends PnpStep {
  bool _isEnabled = false;

  NightModeStep({
    super.saveChanges,
  }) : super(stepId: PnpStepId.nightMode);

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);
    pnp.setStepStatus(stepId, status: StepViewStatus.data);
    canGoNext(saveChanges == null);
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {'isEnabled': _isEnabled};
  }

  @override
  void onDispose() {}

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    return StatefulBuilder(builder: (context, setState) {
      final desc = _isEnabled
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
              AppSwitch(
                semanticLabel: 'node light',
                value: _isEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                },
              ),
              const AppGap.large3(),
              AppText.bodyLarge(desc),
              const AppGap.medium(),
            ],
          ),
        ),
      );
    });
  }

  @override
  String title(BuildContext context) => loc(context).nightMode;
}