import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/setup/bloc.dart';
import 'package:linksys_moab/bloc/setup/event.dart';
import 'package:linksys_moab/bloc/setup/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/model/internet_check_path.dart';
import 'package:linksys_moab/route/route.dart';

class CheckNodeInternetView extends StatefulWidget {
  const CheckNodeInternetView({
    Key? key,
  }) : super(key: key);

  @override
  State<CheckNodeInternetView> createState() => _CheckNodeInternetViewState();
}

class _CheckNodeInternetViewState extends State<CheckNodeInternetView> {
  bool _hasInternet = false;

  @override
  void initState() {
    super.initState();
    //TODO: Add real Internet check function
    _fakeInternetChecking();
  }

  _fakeInternetChecking() async {
    context.read<SetupBloc>().add(
      const ResumePointChanged(status: SetupResumePoint.INTERNETCHECK)
    );
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      _hasInternet = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    NavigationCubit.of(context).push(InternetConnectedPath());
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).check_for_internet,
        ),
        content: Container(
          child: const IndeterminateProgressBar(),
          alignment: Alignment.topCenter,
        ),
        footer: !_hasInternet ? Center(
          child: SimpleTextButton(
            text: getAppLocalizations(context).enter_isp_settings,
            onPressed: () {
              NavigationCubit.of(context).push(SelectIspSettingsPath());
            },
          ),
        ) : null,
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
