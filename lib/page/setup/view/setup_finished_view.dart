import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/setup/bloc.dart';
import 'package:linksys_moab/bloc/setup/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/base_components/text/description_text.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/route/model/model.dart';

class SetupFinishedView extends ArgumentsStatelessView {
  SetupFinishedView({Key? key, super.args}) : super(key: key);

  //TODO: The svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );

  final Widget wifiIcon = Image.asset('assets/images/wifi_logo_grey.png');
  final Widget lockIcon = Image.asset('assets/images/lock_icon.png');
  final Widget portraitIcon = Image.asset('assets/images/portrait_icon.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).wifi_ready_view_title,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 48,
            ),
            DescriptionText(
                text: getAppLocalizations(context).wifi_ready_view_connect_to),
            const SizedBox(height: 8),
            BlocBuilder<SetupBloc, SetupState>(
                buildWhen: (previous, current) =>
                    previous.wifiSSID != current.wifiSSID,
                builder: (context, state) {
                  return infoCard(context, wifiIcon,
                      getAppLocalizations(context).wifi_name, state.wifiSSID);
                }),
            const SizedBox(height: 8),
            BlocBuilder<SetupBloc, SetupState>(
                buildWhen: (previous, current) =>
                    previous.wifiPassword != current.wifiPassword,
                builder: (context, state) {
                  return infoCard(
                      context,
                      lockIcon,
                      getAppLocalizations(context).wifi_password,
                      state.wifiPassword);
                }),
            const SizedBox(height: 58),
            DescriptionText(
                text: getAppLocalizations(context).wifi_ready_view_login_info),
            const SizedBox(height: 8),
            // TODO handle local login
            FutureBuilder<void>(
              future: context.read<AccountCubit>().fetchAccount(),
              builder: (context, snapshot) {
                return infoCard(
                    context,
                    portraitIcon,
                    getAppLocalizations(context).linksys_account,
                    context.read<AccountCubit>().state.username);
                // if (state is AuthCloudLoginState) {
                //   return infoCard(
                //       context,
                //       portraitIcon,
                //       getAppLocalizations(context).linksys_account,
                //       state.accountInfo.username);
                // } else if (state is AuthLocalLoginState) {
                //   return infoCard(context, portraitIcon, "router password",
                //       state.localLoginInfo.routerPassword);
                // } else {
                //   return const Divider(height: 0);
                // }
              },
            ),
          ],
        ),
        footer: PrimaryButton(
          text: getAppLocalizations(context).go_to_dashboard,
          onPress: () {
            NavigationCubit.of(context).push(PrepareDashboardPath());
          },
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}

Widget infoCard(
    BuildContext context, Widget image, String title, String content) {
  return Container(
    padding: const EdgeInsets.all(19),
    color: MoabColor.cardBackground,
    child: Row(
      children: [
        image,
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    ?.copyWith(color: Colors.white)),
            DescriptionText(text: content)
          ],
        )
      ],
    ),
  );
}
