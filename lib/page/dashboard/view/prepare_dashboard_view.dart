import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/account/_account.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../localization/localization_hook.dart';
import '../../../route/model/dashboard_path.dart';
import '../../../route/navigation_cubit.dart';
import '../../../util/logger.dart';
import '../../components/views/arguments_view.dart';

class PrepareDashboardView extends ArgumentsStatefulView {
  const PrepareDashboardView({
    Key? key,
  }) : super(key: key);

  @override
  State<PrepareDashboardView> createState() => _PrepareDashboardViewState();
}

class _PrepareDashboardViewState extends State<PrepareDashboardView> {
  @override
  void initState() {
    super.initState();

    _checkSelfNetworks();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('DEBUG:: PrepareDashboardView: build');

    return LinksysFullScreenSpinner(text: getAppLocalizations(context).processing);
  }

  _checkSelfNetworks() async {
    await context.read<ConnectivityCubit>().forceUpdate();
    if (context.read<AuthBloc>().state is AuthCloudLoginState) {
      if (context.read<NetworkCubit>().state.selected == null) {
        // TODO #LINKSYS
        // await context.read<AccountCubit>().fetchAccount();
        await context
            .read<NetworkCubit>()
            .getNetworks(accountId: context.read<AccountCubit>().state.id);
        NavigationCubit.of(context).clearAndPush(SelectNetworkPath());
        return;
      }
    }
    logger.d('Go to dashboard');
    final routerDeviceInfo = await context
        .read<NetworkCubit>()
        .getDeviceInfo()
        .then<RouterDeviceInfo?>((value) => value)
        .onError((error, stackTrace) => null);
    if (routerDeviceInfo != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          linkstyPrefCurrentSN, routerDeviceInfo.serialNumber);
      NavigationCubit.of(context).clearAndPush(DashboardHomePath());
    } else {
      // TODO #LINKSYS Error handling for unable to get deviceinfo
    }
  }
}
