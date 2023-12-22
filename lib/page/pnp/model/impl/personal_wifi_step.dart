import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class PersonalWiFiStep extends PnpStep {
  late final TextEditingController _ssidEditController;
  late final TextEditingController _passwordEditController;

  PersonalWiFiStep({required super.index});

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

    _ssidEditController = TextEditingController();
    _passwordEditController = TextEditingController();

    if (_ssidEditController.text.isEmpty ||
        _passwordEditController.text.isEmpty) {
      ref
          .read(pnpProvider.notifier)
          .setStepStatus(index, status: StepViewStatus.error);
    }
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
  }) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppTextField(
              headerText: 'Wi-Fi Name',
              hintText: 'Wi-Fi Name',
              controller: _ssidEditController,
              onChanged: (value) {
                if (value.isEmpty) {
                  ref
                      .read(pnpProvider.notifier)
                      .setStepStatus(index, status: StepViewStatus.error);
                } else {
                  ref
                      .read(pnpProvider.notifier)
                      .setStepStatus(index, status: StepViewStatus.data);
                }
              },
            ),
          ),
          const AppGap.semiSmall(),
          Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppTextField(
              headerText: 'Wi-Fi Password',
              hintText: 'Wi-Fi Password',
              controller: _passwordEditController,
              onChanged: (value) {
                if (value.isEmpty) {
                  ref
                      .read(pnpProvider.notifier)
                      .setStepStatus(index, status: StepViewStatus.error);
                } else {
                  ref
                      .read(pnpProvider.notifier)
                      .setStepStatus(index, status: StepViewStatus.data);
                }
              },
            ),
          ),
        ],
      );

  @override
  String title(BuildContext context) =>
      'Personalize your Wi-Fi name and password';
}
