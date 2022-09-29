import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
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

class CustomizeWifiView extends StatelessWidget {
  const CustomizeWifiView({
    Key? key,
  }) : super(key: key);

  static const routeName = '/customize_wifi';

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: PageContent(),
      scrollable: true,
    );
  }
}

class PageContent extends StatefulWidget {
  const PageContent({
    Key? key,
  }) : super(key: key);

  @override
  _PageContentState createState() => _PageContentState();
}

class _PageContentState extends State<PageContent> {
  bool isValidWifiInfo = false;
  final TextEditingController nameController =
      TextEditingController(text: "namedefault");
  final TextEditingController passwordController =
      TextEditingController(text: "passworddefault");

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
        .add(const ResumePointChanged(status: SetupResumePoint.SETSSID));
  }

  @override
  Widget build(BuildContext context) {
    return BasicLayout(
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
                ssid: nameController.text, password: passwordController.text));
            if (context.read<AuthBloc>().state.status ==
                AuthStatus.cloudAuthorized) {
              NavigationCubit.of(context).push(SaveCloudSettingsPath());
            } else {
              NavigationCubit.of(context).push(CreateCloudAccountPath());
            }
          },
        ),
        child: PrimaryButton(
          text: getAppLocalizations(context).next,
          onPress: () {
            context.read<SetupBloc>().add(SetWIFISSIDAndPassword(
                ssid: nameController.text, password: passwordController.text));
            if (context.read<AuthBloc>().state.status ==
                AuthStatus.cloudAuthorized) {
              NavigationCubit.of(context).push(SaveCloudSettingsPath());
            } else {
              NavigationCubit.of(context).push(CreateCloudAccountPath());
            }
          },
        ),
      ),
    );
  }
}
