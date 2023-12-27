import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class NightModeStep extends PnpStep {
  NightModeStep({required super.index});

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

    final state = ref.read(pnpProvider).stepStateList[index];
    if (state?.data['isEnabled'] == null) {
      ref
          .read(pnpProvider.notifier)
          .setStepData(index, data: {'isEnabled': true});
    }
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {};
  }

  @override
  void onDispose() {}

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    final data = ref
            .watch(pnpProvider.select((value) => value.stepStateList))[index]
            ?.data ??
        {};
    bool isEnabled = data['isEnabled'] ?? true;
    final desc = isEnabled
        ? 'Enable Night Mode to turn off node lights automatically from 8PM - 8AM'
        : 'Node lights are always on';
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodyLarge(desc),
          const AppGap.semiSmall(),
          AppSwitch.withIcon(
            value: isEnabled,
            onChanged: (value) {
              update(ref, key: 'isEnabled', value: value);
            },
          ),
        ],
      ),
    );
  }

  @override
  String title(BuildContext context) => 'Night Mode';

  void update(WidgetRef ref, {required String key, dynamic value}) {
    if (value == null) {
      return;
    }
    final currentData = ref.read(pnpProvider).stepStateList[index]?.data ?? {};
    ref
        .read(pnpProvider.notifier)
        .setStepData(index, data: Map.from(currentData)..[key] = value);
  }
}
