import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/indeterminate_progressbar.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/route/model/model.dart';

class SaveSettingsView extends StatefulWidget {
  SaveSettingsView({
    Key? key,
  }) : super(key: key);

  @override
  State<SaveSettingsView> createState() => _SaveSettingsViewState();
}

class _SaveSettingsViewState extends State<SaveSettingsView> {
  @override
  void initState() {
    super.initState();
    _createAccountProcess();
  }

  //TODO: The svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );

  _createAccountProcess() async {
    await context
        .read<AuthBloc>()
        .createVerifiedAccount()
        .then((value) => _fakeInternetChecking());
  }

  _fakeInternetChecking() async {
    await Future.delayed(const Duration(seconds: 5));
    NavigationCubit.of(context).push(SetupFinishPath());
  }

  @override
  Widget build(BuildContext context) {
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
  }
}
