import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class EditWifiNamePasswordView extends ArgumentsStatefulView {
  const EditWifiNamePasswordView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _EditWifiNamePasswordViewState createState() =>
      _EditWifiNamePasswordViewState();
}

class _EditWifiNamePasswordViewState extends State<EditWifiNamePasswordView> {
  bool isLoading = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordInvalid = false;

  @override
  initState() {
    super.initState();

    final wifiItem = context.read<WifiSettingCubit>().state.selectedWifiItem;
    nameController.text = wifiItem.ssid;
    passwordController.text = wifiItem.password;
  }

  void _onPasswordChanged(String text) {
    setState(() => isPasswordInvalid = false);
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
          // Update the name and the password
          setState(() => isLoading = true);
          final wifiType =
              context.read<WifiSettingCubit>().state.selectedWifiItem.wifiType;
          context
              .read<WifiSettingCubit>()
              .updateWifiNameAndPassword(
                  nameController.text, passwordController.text, wifiType)
              .then((value) {
            setState(() => isLoading = false);
            NavigationCubit.of(context).pop();
          }).onError((error, stackTrace) {
            setState(() => isLoading = false);
            showOkCancelAlertDialog(
              context: context,
              title: "Saving error",
              message: '',
            );
          });
        }
      });
    } else {
      setState(() => isPasswordInvalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? FullScreenSpinner(text: getAppLocalizations(context).processing)
        : BasePageView(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              iconTheme:
                  IconThemeData(color: Theme.of(context).colorScheme.primary),
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: SimpleTextButton(
                    text: getAppLocalizations(context).save,
                    onPressed: _checkInputData,
                  ),
                ),
              ],
            ),
            child: BasicLayout(
              content: Column(
                children: [
                  InputField(
                    titleText: getAppLocalizations(context).wifi_name,
                    controller: nameController,
                  ),
                  const SizedBox(
                    height: 26,
                  ),
                  PasswordInputField(
                    titleText: getAppLocalizations(context).wifi_password,
                    controller: passwordController,
                    isError: isPasswordInvalid,
                    errorText:
                        'WiFi password must be between 2 - 32 characters, and not contain ?, ", \$, [, \\, ], or +.',
                    onChanged: _onPasswordChanged,
                  ),
                ],
              ),
            ),
          );
  }
}
