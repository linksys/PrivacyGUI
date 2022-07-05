import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/route/route.dart';

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
  final TextEditingController nameController = TextEditingController(text: "namedefault");
  final TextEditingController passwordController = TextEditingController(text: "passworddefault");

  void _checkFilledInfo(_) {
    setState(() {
      isValidWifiInfo = nameController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasicLayout(
      header: BasicHeader(
        title: AppLocalizations.of(context)!.create_ssid_view_title,
        description: AppLocalizations.of(context)!.create_ssid_view_header_description,
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 36, bottom: 24),
            child: InputField(
              titleText: AppLocalizations.of(context)!.wifi_name,
              controller: nameController,
              onChanged: _checkFilledInfo,
            ),
          ),
          InputField(
            titleText: AppLocalizations.of(context)!.password,
            controller: passwordController,
            onChanged: _checkFilledInfo,
          ),
        ],
      ),
      footer: Visibility(
        visible: isValidWifiInfo,
        replacement: SecondaryButton(
          text: AppLocalizations.of(context)!.keep_defaults,
          onPress: () => NavigationCubit.of(context).push(CreateCloudAccountPath()),
        ),
        child: PrimaryButton(
          text: AppLocalizations.of(context)!.next,
          onPress: () => NavigationCubit.of(context).push(CreateCloudAccountPath()),
        ),
      ),
    );
  }
}