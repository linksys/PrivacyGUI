import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/model/pnp_step.dart';
import 'package:privacy_gui/page/pnp/widgets/wifi_password_widget.dart';
import 'package:privacy_gui/page/pnp/widgets/wifi_ssid_widget.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class GuestWiFiStep extends PnpStep {
  TextEditingController? _ssidEditController;
  TextEditingController? _passwordEditController;
  bool isEnabled = false;

  GuestWiFiStep({required super.index});

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

    _ssidEditController = TextEditingController();
    _passwordEditController = TextEditingController();

    final guestWifi = pnp.getDefaultGuestWiFiNameAndPassPhrase();

    _ssidEditController?.text = guestWifi.name;
    _passwordEditController?.text = guestWifi.password;
    _check(ref);
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {
      'isEnabled': isEnabled,
      if (isEnabled) 'ssid': _ssidEditController?.text,
      if (isEnabled) 'password': _passwordEditController?.text,
    };
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
    // final data = ref
    //         .watch(pnpProvider.select((value) => value.stepStateList))[index]
    //         ?.data ??
    //     {};
    // bool isEnabled = data['isEnabled'] ?? false;
    return StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSwitch(
            value: isEnabled,
            onChanged: (value) {
              setState(() {
                isEnabled = value;
              });
              // update(ref, key: 'isEnabled', value: value);
            },
          ),
          const AppGap.large3(),
          AppText.bodyLarge(loc(context).pnpGuestWiFiDesc),
          const AppGap.large3(),
          ...isEnabled
              ? [
                  WiFiSSIDField(
                    controller: _ssidEditController!,
                    label: loc(context).guestWiFiName,
                    hint: loc(context).guestWiFiName,
                    onCheckInput: (isValid, input) {
                      // if (isValid) {
                      //   ref
                      //       .read(pnpProvider.notifier)
                      //       .setStepData(index, data: {'ssid': input});
                      // } else {
                      //   ref
                      //       .read(pnpProvider.notifier)
                      //       .setStepData(index, data: {'ssid': ''});
                      // }
                      _check(ref);
                    },
                  ),
                  const AppGap.medium(),
                  WiFiPasswordField(
                    controller: _passwordEditController!,
                    label: loc(context).guestWiFiPassword,
                    hint: loc(context).guestWiFiPassword,
                    onCheckInput: (isValid, input) {
                      // if (isValid) {
                      //   ref
                      //       .read(pnpProvider.notifier)
                      //       .setStepData(index, data: {'password': input});
                      // } else {
                      //   ref
                      //       .read(pnpProvider.notifier)
                      //       .setStepData(index, data: {'password': ''});
                      // }
                      _check(ref);
                    },
                  ),
                  const AppGap.medium(),
                ]
              : [],
        ],
      );
    });
  }

  @override
  String title(BuildContext context) => loc(context).guestNetwork;

  // void update(WidgetRef ref, {required String key, dynamic value}) {
  //   if (value == null) {
  //     return;
  //   }
  //   final currentData = ref.read(pnpProvider).stepStateList[index]?.data ?? {};
  //   ref
  //       .read(pnpProvider.notifier)
  //       .setStepData(index, data: Map.from(currentData)..[key] = value);
  //   _check(ref);
  // }

  void _check(WidgetRef ref) {
    final ssid = _ssidEditController?.text ?? '';
    final password = _passwordEditController?.text ?? '';
    if (!isEnabled || ssid.isNotEmpty && password.isNotEmpty) {
      pnp.setStepStatus(index, status: StepViewStatus.data);
    } else {
      pnp.setStepStatus(index, status: StepViewStatus.error);
    }
  }
}
