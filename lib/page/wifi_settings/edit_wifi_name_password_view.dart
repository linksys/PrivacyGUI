import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_settings_view.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class EditWifiNamePasswordView extends ArgumentsStatefulView {
  const EditWifiNamePasswordView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  _EditWifiNamePasswordViewState createState() => _EditWifiNamePasswordViewState();
}

class _EditWifiNamePasswordViewState extends State<EditWifiNamePasswordView> {
  late WifiListItem _wifiItem;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordInvalid = false;

  @override
  initState() {
    super.initState();
    if (widget.args.containsKey('info')) {
      _wifiItem = widget.args['info'];
    }
    nameController.text = _wifiItem.ssid;
    passwordController.text = _wifiItem.password;
  }

  void _onPasswordChanged(String text) {
    setState(() => isPasswordInvalid = false);
  }

  void _checkInputData() {
    if (nameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      //Update the name and the password
      _wifiItem.ssid = nameController.text;
      _wifiItem.password = passwordController.text;
      NavigationCubit.of(context).popWithResult(_wifiItem);
    } else {
      setState(() => isPasswordInvalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
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
              errorText: 'WiFi password must contain xyz (WIP)',
              onChanged: _onPasswordChanged,
            ),
          ],
        ),
        footer: PrimaryButton(
          text: getAppLocalizations(context).save,
          onPress: _checkInputData,
        ),
      ),
    );
  }

}