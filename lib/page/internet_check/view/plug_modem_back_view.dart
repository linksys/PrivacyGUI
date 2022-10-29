import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/internet_check_path.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class PlugModemBackView extends StatelessWidget {
  const PlugModemBackView({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).plug_modem_back_title,
        ),
        content: Image.asset(
          'assets/images/plug_modem_back.png',
          alignment: Alignment.topLeft,
        ),
        footer: PrimaryButton(
          text: getAppLocalizations(context).next,
          onPress: () {
            NavigationCubit.of(context).push(CheckNodeInternetPath());
          },
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}