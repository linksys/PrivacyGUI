import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/internet_check/cubit.dart';
import 'package:linksys_moab/bloc/internet_check/state.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
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

  @override
  void initState() {
    super.initState();
    _fakeInternetChecking();
  }

  _fakeInternetChecking() async {
    context
        .read<SetupBloc>()
        .add(const ResumePointChanged(status: SetupResumePoint.internetCheck));
    final connCubit = context.read<ConnectivityCubit>();
    final internetCheckCubit = context.read<InternetCheckCubit>();
    await connCubit.stopChecking();

    bool isConnected = await _tryConnectMQTT();

    internetCheckCubit.setConnectToRouter(isConnected);
  }

  Future<bool> _tryConnectMQTT() async {
    final connCubit = context.read<ConnectivityCubit>();
    const maxRetry = 10;
    int retry = 0;
    bool isConnect = false;
    do {
      isConnect = await connCubit.connectToLocalBroker();
      if (isConnect) {
        return isConnect;
      } else {
        retry++;
        await Future.delayed(const Duration(seconds: 5));
      }
    } while (retry < maxRetry);
    return isConnect;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternetCheckCubit, InternetCheckState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == InternetCheckStatus.detectWANStatus) {
          context.read<InternetCheckCubit>().detectWANStatus();
        } else if (state.status == InternetCheckStatus.pppoe) {
          // go pppoe page
        } else if (state.status == InternetCheckStatus.static) {
          // go static page
        } else if (state.status == InternetCheckStatus.connectedToRouter) {
          context.read<InternetCheckCubit>().initDevice();
        } else if (state.status == InternetCheckStatus.errorConnectedToRouter) {
          // Not a moab/linksys router
        } else if (state.status == InternetCheckStatus.checkWiring) {
          // go check wiring page
        } else if (state.status == InternetCheckStatus.getInternetConnectionStatus) {
          context.read<InternetCheckCubit>().getInternetConnectionStatus();
        } else if (state.status == InternetCheckStatus.noInternet) {
          // Go no internet page
        } else if (state.status == InternetCheckStatus.manually) {
          // go manually
          NavigationCubit.of(context).push(SelectIspSettingsPath());
        } else if (state.status == InternetCheckStatus.connected) {
          // go connected page
          NavigationCubit.of(context).push(InternetConnectedPath());
        }
      },
      builder: (context, state) => BasePageView.noNavigationBar(
        child: BasicLayout(
          header: BasicHeader(
            title: getAppLocalizations(context).check_for_internet,
          ),
          content: Container(
            child: const IndeterminateProgressBar(),
            alignment: Alignment.topCenter,
          ),
          footer: Offstage(
            offstage: state.status == InternetCheckStatus.init,
            child: Center(
              child: SimpleTextButton(
                text: getAppLocalizations(context).enter_isp_settings,
                onPressed: () {
                  context.read<InternetCheckCubit>().setManuallyInput();
                },
              ),
            ),
          ),
          alignment: CrossAxisAlignment.start,
        ),
      ),
    );
  }
}
