import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_app/page/pnp/widgets/wifi_password_widget.dart';
import 'package:linksys_app/page/pnp/widgets/wifi_ssid_widget.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class GuestWiFiStep extends PnpStep {
  TextEditingController? _ssidEditController;
  TextEditingController? _passwordEditController;

  GuestWiFiStep({required super.index});

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

    _ssidEditController = TextEditingController();
    _passwordEditController = TextEditingController();

    final data = ref.read(pnpProvider).stepStateList[index]?.data ?? {};
    final String ssid = data['ssid'] ?? '';
    final String password = data['password'] ?? '';

    _ssidEditController?.text = ssid;
    _passwordEditController?.text = password;
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {};
  }

  @override
  void onDispose() {
    _passwordEditController?.dispose();
    _ssidEditController?.dispose();
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
                      child: WiFiSSIDField(
                        controller: _ssidEditController!,
                        label: 'SSID',
                        hint: 'Guest WiFi SSID',
                        onCheckInput: (isValid, input) {
                          if (isValid) {
                            ref
                                .read(pnpProvider.notifier)
                                .setStepData(index, data: {'ssid': input});
                          } else {
                            ref
                                .read(pnpProvider.notifier)
                                .setStepData(index, data: {'ssid': ''});
                          }
                          _check(ref);
                        },
                      ),
                    ),
                    const AppGap.semiSmall(),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: WiFiPasswordField(
                        controller: _passwordEditController!,
                        label: 'Password',
                        hint: 'Guest WiFi Password',
                        onCheckInput: (isValid, input) {
                          if (isValid) {
                            ref
                                .read(pnpProvider.notifier)
                                .setStepData(index, data: {'password': input});
                          } else {
                            ref
                                .read(pnpProvider.notifier)
                                .setStepData(index, data: {'password': ''});
                          }
                          _check(ref);
                        },
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
    _check(ref);
  }

  void _check(WidgetRef ref) {
    final state = ref.read(pnpProvider).stepStateList[index];
    final isEnable = state?.data['isEnabled'] as bool? ?? false;
    final ssid = state?.data['ssid'] as String? ?? '';
    final password = state?.data['password'] as String? ?? '';
    if (!isEnable || ssid.isNotEmpty && password.isNotEmpty) {
      ref
          .read(pnpProvider.notifier)
          .setStepStatus(index, status: StepViewStatus.data);
    } else {
      ref
          .read(pnpProvider.notifier)
          .setStepStatus(index, status: StepViewStatus.error);
    }
  }
}
