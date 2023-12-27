import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_app/page/pnp/widgets/wifi_password_widget.dart';
import 'package:linksys_app/page/pnp/widgets/wifi_ssid_widget.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class PersonalWiFiStep extends PnpStep {
  TextEditingController? _ssidEditController;
  TextEditingController? _passwordEditController;

  PersonalWiFiStep({required super.index});

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

    _ssidEditController = TextEditingController();
    _passwordEditController = TextEditingController();

    _check(ref);
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
  }) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: WiFiSSIDField(
              controller: _ssidEditController!,
              label: 'Wi-Fi Name',
              hint: 'Wi-Fi Name',
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
              label: 'Wi-Fi Password',
              hint: 'Wi-Fi Password',
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
          ),
        ],
      );

  @override
  String title(BuildContext context) =>
      'Personalize your Wi-Fi name and password';

  void _check(WidgetRef ref) {
    final state = ref.read(pnpProvider).stepStateList[index];
    final ssid = state?.data['ssid'] as String? ?? '';
    final password = state?.data['password'] as String? ?? '';
    if (ssid.isNotEmpty && password.isNotEmpty) {
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
