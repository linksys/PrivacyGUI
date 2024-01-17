import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/provider/wifi_setting/_wifi_setting.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class EditWifiNamePasswordView extends ArgumentsConsumerStatefulView {
  const EditWifiNamePasswordView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<EditWifiNamePasswordView> createState() =>
      _EditWifiNamePasswordViewState();
}

class _EditWifiNamePasswordViewState
    extends ConsumerState<EditWifiNamePasswordView> {
  bool isLoading = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordInvalid = false;
  late String _title;
  // late WifiType _wifiType;
  late bool isChanged = false;
  late String _oriSSID;
  late String _oriPassword;

  @override
  initState() {
    super.initState();

    final wifiItem = ref.read(wifiSettingProvider).selectedWifiItem;
    _title = wifiItem.ssid;
    _oriSSID = wifiItem.ssid;
    _oriPassword = wifiItem.password;
    // _wifiType = wifiItem.wifiType;
    nameController.text = wifiItem.ssid;
    passwordController.text = wifiItem.password;
  }

  void _onSSIDChanged(String text) {
    setState(() {
      isChanged = checkChanged();
    });
  }

  void _onPasswordChanged(String text) {
    setState(() {
      isPasswordInvalid = false;
      isChanged = checkChanged();
    });
  }

  void _checkInputData() {
    if (nameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      showOkCancelAlertDialog(
        context: context,
        title:
            "Changing your WiFi name or password will cause all devices to disconnect",
        message:
            'You will have to reconnect each device with the new information',
        okLabel: getAppLocalizations(context).text_continue,
        cancelLabel: getAppLocalizations(context).cancel,
      ).then((result) {
        // If users confirm the change, update the information. Otherwise, do nothing.
        if (result == OkCancelResult.ok) {
          // // Update the name and the password
          // setState(() => isLoading = true);
          // ref
          //     .read(wifiSettingProvider.notifier)
          //     .updateWifiNameAndPassword(
          //         nameController.text, passwordController.text, _wifiType)
          //     .then((value) {
          //   setState(() => isLoading = false);
          //   context.pop();
          // }).onError((error, stackTrace) {
          //   setState(() => isLoading = false);
          //   showOkCancelAlertDialog(
          //     context: context,
          //     title: "Saving error",
          //     message: '',
          //   );
          // });
        }
      });
    } else {
      setState(() => isPasswordInvalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? AppFullScreenSpinner(text: getAppLocalizations(context).processing)
        : StyledAppPageView(
            title: _title,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: Spacing.regular),
                child: AppTextButton.noPadding(
                  getAppLocalizations(context).save,
                  onTap: isChanged ? _checkInputData : null,
                ),
              ),
            ],
            child: AppBasicLayout(
              content: Column(
                children: [
                  AppTextField(
                    headerText: getAppLocalizations(context).wifi_name,
                    controller: nameController,
                    onChanged: _onSSIDChanged,
                  ),
                  const AppGap.semiBig(),
                  AppPasswordField(
                    headerText: getAppLocalizations(context).wifi_password,
                    controller: passwordController,
                    // isError: isPasswordInvalid,
                    // errorText:
                    //     'WiFi password must be between 2 - 32 characters, and not contain ?, ", \$, [, \\, ], or +.',
                    onChanged: _onPasswordChanged,
                  ),
                ],
              ),
            ),
          );
  }

  bool checkChanged() {
    return _oriSSID != nameController.text ||
        _oriPassword != passwordController.text;
  }
}
