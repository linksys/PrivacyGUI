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
import 'package:linksys_moab/util/logger.dart';

class CheckNodeInternetView extends StatefulWidget {
  const CheckNodeInternetView({
    Key? key,
  }) : super(key: key);

  @override
  State<CheckNodeInternetView> createState() => _CheckNodeInternetViewState();
}

class _CheckNodeInternetViewState extends State<CheckNodeInternetView> {
  late final SetupBloc _setupBloc;
  late final InternetCheckCubit _internetCheckCubit;
  late final ConnectivityCubit _connectivityCubit;

  @override
  void initState() {
    _setupBloc = context.read<SetupBloc>();
    _internetCheckCubit = context.read<InternetCheckCubit>();
    _connectivityCubit = context.read<ConnectivityCubit>();
    super.initState();
    _tryInternetChecking();
  }

  _tryInternetChecking() async {
    _setupBloc
        .add(const ResumePointChanged(status: SetupResumePoint.internetCheck));

    bool isConnected = await _tryConnectMQTT();

    _internetCheckCubit.setConnectToRouter(isConnected);
  }

  Future<bool> _tryConnectMQTT() async {
    const maxRetry = 20;
    int retry = 0;
    bool isConnect = false;
    do {
      isConnect = await _connectivityCubit
          .connectToLocalBroker()
          .onError((error, stackTrace) => false);
      logger.d('check internet:: _tryConnectMQTT: retry: $retry, $isConnect');
      if (isConnect) {
        return isConnect;
      } else {
        retry++;
        await Future.delayed(const Duration(seconds: 6));
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
          _internetCheckCubit.detectWANStatus();
        } else if (state.status == InternetCheckStatus.pppoe) {
          // go pppoe page
          NavigationCubit.of(context).push(EnterIspSettingsPath());
        } else if (state.status == InternetCheckStatus.static) {
          // go static page
          NavigationCubit.of(context).push(EnterStaticIpPath());
        } else if (state.status == InternetCheckStatus.connectedToRouter) {
          _internetCheckCubit.initDevice();
        } else if (state.status == InternetCheckStatus.errorConnectedToRouter) {
          // Not a moab/linksys router
          NavigationCubit.of(context).push(UnplugModemPath());
        } else if (state.status == InternetCheckStatus.checkWiring) {
          // go check wiring page
          NavigationCubit.of(context).push(CheckWiringPath());
        } else if (state.status ==
            InternetCheckStatus.getInternetConnectionStatus) {
          _internetCheckCubit.getInternetConnectionStatus();
        } else if (state.status == InternetCheckStatus.noInternet) {
          // Go no internet page
          NavigationCubit.of(context).push(NoInternetOptionsPath());
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
                  _internetCheckCubit.setManuallyInput();
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
