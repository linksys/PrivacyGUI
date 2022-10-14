import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/setup/bloc.dart';
import 'package:linksys_moab/bloc/setup/event.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/base_components/button/secondary_button.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/input_field.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/route/model/_model.dart';

import '../../../bloc/setup/state.dart';

class CustomizeWifiView extends StatefulWidget {
  const CustomizeWifiView({
    Key? key,
  }) : super(key: key);

  @override
  _CustomizeWifiViewState createState() => _CustomizeWifiViewState();
}

class _CustomizeWifiViewState extends State<CustomizeWifiView> {
  bool isValidWifiInfo = false;
  final TextEditingController nameController =
      TextEditingController(text: "");
  final TextEditingController passwordController =
      TextEditingController(text: "");

  void _checkFilledInfo(_) {
    setState(() {
      isValidWifiInfo =
          nameController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    context
        .read<SetupBloc>()
        .add(const ResumePointChanged(status: SetupResumePoint.setSSID));
    context.read<NetworkCubit>().getDeviceInfo().then(
        (value) => context.read<NetworkCubit>().getRadioInfo().then((value) {
              final ssid = value[0].settings.ssid;
              final password = value[0].settings.wpaPersonalSettings.passphrase;
              nameController.text = ssid;
              passwordController.text = password;
            }));
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).create_ssid_view_title,
          description:
              getAppLocalizations(context).create_ssid_view_header_description,
        ),
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 36, bottom: 24),
              child: InputField(
                titleText: getAppLocalizations(context).wifi_name,
                controller: nameController,
                onChanged: _checkFilledInfo,
              ),
            ),
            InputField(
              titleText: getAppLocalizations(context).password,
              controller: passwordController,
              onChanged: _checkFilledInfo,
            ),
          ],
        ),
        footer: Visibility(
          visible: isValidWifiInfo,
          replacement: SecondaryButton(
            text: getAppLocalizations(context).keep_defaults,
            onPress: () {
              context.read<SetupBloc>().add(SetWIFISSIDAndPassword(
                  ssid: nameController.text,
                  password: passwordController.text));
              if (context.read<AuthBloc>().state.status ==
                  AuthStatus.cloudAuthorized) {
                NavigationCubit.of(context).push(SaveSettingsPath());
              } else {
                NavigationCubit.of(context).push(CreateCloudAccountPath());
              }
            },
          ),
          child: PrimaryButton(
            text: getAppLocalizations(context).next,
            onPress: () {
              context.read<SetupBloc>().add(SetWIFISSIDAndPassword(
                  ssid: nameController.text,
                  password: passwordController.text));
              if (context.read<AuthBloc>().state.status ==
                  AuthStatus.cloudAuthorized) {
                NavigationCubit.of(context).push(SaveSettingsPath());
              } else {
                NavigationCubit.of(context).push(CreateCloudAccountPath());
              }
            },
          ),
        ),
      ),
    );
  }
}
