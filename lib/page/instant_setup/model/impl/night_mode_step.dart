import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class NightModeStep extends PnpStep {
  static int id = 2;
  bool _isEnabled = false;

  NightModeStep({
    super.saveChanges,
  }): super(index: id);

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);
    pnp.setStepStatus(index, status: StepViewStatus.data);
    canGoNext(saveChanges == null);
    // final state = ref.read(pnpProvider).stepStateList[index];
    // if (state?.data['isEnabled'] == null) {
    //   ref
    //       .read(pnpProvider.notifier)
    //       .setStepData(index, data: {'isEnabled': true});
    // }
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {'isEnabled': _isEnabled};
  }

  // @override
  // Future save(WidgetRef ref, Map<String, dynamic> data) async {
  //   super.save(ref, data);
  //   pnp.setStepStatus(index, status: StepViewStatus.loading);
  //   // Do saving
  //   await pnp.save();
  //   pnp.setStepStatus(index, status: StepViewStatus.data);
  // }

  @override
  void onDispose() {}

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    // final data = ref
    //         .watch(pnpProvider.select((value) => value.stepStateList))[index]
    //         ?.data ??
    //     {};
    // bool isEnabled = data['isEnabled'] ?? true;

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
                  // update(ref, key: 'isEnabled', value: value);
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

  // void update(WidgetRef ref, {required String key, dynamic value}) {
  //   if (value == null) {
  //     return;
  //   }
  //   final currentData = ref.read(pnpProvider).stepStateList[index]?.data ?? {};
  //   ref
  //       .read(pnpProvider.notifier)
  //       .setStepData(index, data: Map.from(currentData)..[key] = value);
  // }
}
