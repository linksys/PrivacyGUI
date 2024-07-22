import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/model/pnp_step.dart';
import 'package:privacy_gui/page/pnp/widgets/wifi_password_widget.dart';
import 'package:privacy_gui/page/pnp/widgets/wifi_ssid_widget.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class PersonalWiFiStep extends PnpStep {
  TextEditingController? _ssidEditController;
  TextEditingController? _passwordEditController;

  PersonalWiFiStep({
    required super.index,
    super.saveChanges,
  });

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);

    _ssidEditController = TextEditingController();
    _passwordEditController = TextEditingController();

    final wifi = pnp.getDefaultWiFiNameAndPassphrase();
    _ssidEditController?.text = wifi.name;
    _passwordEditController?.text = wifi.password;

    _check(ref);
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {
      'ssid': _ssidEditController?.text,
      'password': _passwordEditController?.text,
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
  }) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WiFiSSIDField(
            controller: _ssidEditController,
            label: loc(context).wifiName,
            hint: loc(context).wifiName,
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
            controller: _passwordEditController,
            label: loc(context).wifiPassword,
            hint: loc(context).wifiPassword,
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
          const AppGap.large5(),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: AppText.bodySmall(
                  loc(context).pnpPersonalizeInfo,
                  maxLines: 10,
                ),
              ),
              AppIconButton.noPadding(
                icon: LinksysIcons.infoCircle,
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  _showDefaultsInfoModal(context);
                },
              )
            ],
          ),
          const AppGap.large5(),
        ],
      );

  @override
  String title(BuildContext context) => loc(context).pnpPersonalizeWiFiTitle;

  void _check(WidgetRef ref) {
    // final state = ref.read(pnpProvider).stepStateList[index];
    // final ssid = state?.data['ssid'] as String? ?? '';
    // final password = state?.data['password'] as String? ?? '';
    final ssid = _ssidEditController?.text ?? '';
    final password = _passwordEditController?.text ?? '';
    if (ssid.isNotEmpty && password.isNotEmpty) {
      pnp.setStepStatus(index, status: StepViewStatus.data);
    } else {
      pnp.setStepStatus(index, status: StepViewStatus.error);
    }
  }

  _showDefaultsInfoModal(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: SizedBox(
              width: 400.0,
              child: AppText.titleLarge(
                  loc(context).modalPnpWiFiDefaultsInfoTitle)),
          actions: [
            AppTextButton(
              loc(context).close,
              onTap: () {
                context.pop();
              },
            ),
          ],
          content: SizedBox(
            child: Container(
              width: 400.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                      loc(context).modalPnpWiFiDefaultsInfoDesc1),
                  const AppGap.medium(),
                  AppText.bodyMedium(
                      loc(context).modalPnpWiFiDefaultsInfoDesc2),
                  const AppGap.medium(),
                  AppText.bodyMedium(
                      loc(context).modalPnpWiFiDefaultsInfoDesc3),
                  const AppGap.medium(),
                  AppText.bodyMedium(
                      loc(context).modalPnpWiFiDefaultsInfoDesc4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
