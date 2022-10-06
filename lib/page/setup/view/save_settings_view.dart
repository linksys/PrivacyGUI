import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/setup/bloc.dart';
import 'package:linksys_moab/bloc/setup/event.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/indeterminate_progressbar.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/route/model/_model.dart';

class SaveSettingsView extends ArgumentsStatefulView {
  const SaveSettingsView({
    Key? key, super.args
  }) : super(key: key);

  @override
  State<SaveSettingsView> createState() => _SaveSettingsViewState();
}

class _SaveSettingsViewState extends State<SaveSettingsView> {
  @override
  void initState() {
    super.initState();
    _processAllSettings();
  }

  //TODO: The svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );

  _processAllSettings() async {
    await _createCloudAccountProcess();
  }
  _createCloudAccountProcess() async {
    final authBloc = context.read<AuthBloc>();
    if (authBloc.state is AuthOnCloudLoginState) {
      authBloc.add(CloudLogin());
    } else if (authBloc.state is AuthOnCreateAccountState) {
      // TODO waiting for cloud modify
      // Add create account event
      authBloc
          .createVerifiedAccount()
          .then((value) => authBloc.add(CloudLogin()));
    }
  }

  //
  // // TODO no use
  // _fakeInternetChecking() async {
  //   await Future.delayed(const Duration(seconds: 5));
  //   NavigationCubit.of(context).clearAndPush(SetupFinishPath());
  // }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (BuildContext context, state) {
        if (state is AuthCloudLoginState) {
          NavigationCubit.of(context).clearAndPush(SetupFinishPath());
        } else if (state is AuthLocalLoginState) {
          NavigationCubit.of(context).clearAndPush(SetupFinishPath());
        }
      },
      builder: (context, state) {
        return BasePageView.noNavigationBar(
          child: BasicLayout(
            header: BasicHeader(
              title: getAppLocalizations(context).saving_settings_view_title,
            ),
            content: Center(
              child: Column(
                children: [
                  image,
                  const SizedBox(
                    height: 130,
                  ),
                  Center(
                      child: Text(
                          getAppLocalizations(context).adding_nodes_more_info)),
                  const SizedBox(
                    height: 69,
                  ),
                  const IndeterminateProgressBar(),
                ],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
            alignment: CrossAxisAlignment.start,
          ),
        );
      },
    );
  }
}
