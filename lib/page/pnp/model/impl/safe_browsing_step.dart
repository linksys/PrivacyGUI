import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/model/pnp_step.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

class SafeBrowsingStep extends PnpStep {
  SafeBrowsingStep({required super.index});

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);
    final state = ref.read(pnpProvider).stepStateList[index];
    if (state?.data['isEnabled'] == null) {
      ref
          .read(pnpProvider.notifier)
          .setStepData(index, data: {'isEnabled': true, 'meta': 'fortinet'});
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.bodyLarge(
              'Block malicious content such as phishing using DNS security. This will apply to all devices connected to your Wi-Fi.'),
          const AppGap.small2(),
          AppSwitch.withIcon(
            value: isEnabled,
            onChanged: (value) {
              update(ref, key: 'isEnabled', value: value);
            },
          ),
          ...isEnabled
              ? [
                  AppRadioList<String>(
                    items: [
                      AppRadioListItem<String>(
                          title: 'Secure DNS (Fortinet)', value: 'fortinet'),
                      AppRadioListItem<String>(
                          title: 'OpenDNS (Cisco)', value: 'cisco'),
                    ],
                    itemHeight: 56,
                    onChanged: (int index, String? value) {
                      ref
                          .read(pnpProvider.notifier)
                          .setStepData(this.index, data: {'meta': value});
                    },
                    initial: data['meta'],
                  )
                ]
              : []
        ],
      ),
    );
  }

  @override
  String title(BuildContext context) => 'Safe Browsing';

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
