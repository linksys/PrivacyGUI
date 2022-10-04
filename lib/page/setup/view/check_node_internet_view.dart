import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/setup/bloc.dart';
import 'package:linksys_moab/bloc/setup/event.dart';
import 'package:linksys_moab/bloc/setup/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/internet_check_path.dart';
import 'package:linksys_moab/route/_route.dart';


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
    _fakeInternetChecking();
  }

  _fakeInternetChecking() async {
    context.read<SetupBloc>().add(
      const ResumePointChanged(status: SetupResumePoint.INTERNETCHECK)
    );
    final bloc = context.read<ConnectivityCubit>();
    final state = await bloc.forceUpdate();

    // bool isConnect = await bloc.connectToLocalBroker();
    // if (!isConnect) {
    //   // TODO not a Moab/Linksys router
    // }

    // TODO get gateway ip
    // TODO get device info
    // TODO update better action
    // final configuredData = await bloc.isRouterConfigured();
    // bool hasConfigured = !configuredData.isDefaultPassword & configuredData.isSetByUser;

    // TODO getWANStatus?

    _hasInternet = state.hasInternet;
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
