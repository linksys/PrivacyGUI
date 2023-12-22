import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class GuestWiFiStep extends PnpStep {
  late final TextEditingController _ssidEditController;
  late final TextEditingController _passwordEditController;

  GuestWiFiStep({required super.index});

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

   _ssidEditController = TextEditingController();
   _passwordEditController = TextEditingController();

    final data = ref.read(pnpProvider).stepStateList[index]?.data ?? {};
    final String ssid = data['ssid'];
    final String password = data['password'];

    _ssidEditController.text = ssid;
    _passwordEditController.text = password;
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {};
  }

  @override
  void onDispose() {
    _passwordEditController.dispose();
    _ssidEditController.dispose();
  }

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
    bool isEnabled = data['isEnabled'] ?? false;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.bodyLarge(
            'Turn on guest network to create separate Wi-Fi network for guests and maintain the privacy of your main network'),
        const AppGap.semiSmall(),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSwitch(
              value: isEnabled,
              onChanged: (value) {
                update(ref, key: 'isEnabled', value: value);
              },
            ),
            ...isEnabled
                ? [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: AppTextField(
                        controller: _ssidEditController,
                        headerText: 'SSID',
                      ),
                    ),
                    const AppGap.semiSmall(),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: AppTextField(
                        controller: _passwordEditController,
                        headerText: 'Password',
                      ),
                    )
                  ]
                : [],
          ],
        ),
      ],
    );
  }

  @override
  String title(BuildContext context) => 'Guest Network';

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
