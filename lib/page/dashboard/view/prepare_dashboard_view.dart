import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/account/_account.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/connectivity/connectivity_provider.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/model/router/device_info.dart';
import 'package:linksys_moab/repository/router/providers/polling_provider.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../localization/localization_hook.dart';
import '../../../route/model/dashboard_path.dart';
import '../../../util/logger.dart';
import '../../components/views/arguments_view.dart';

class PrepareDashboardView extends ArgumentsConsumerStatefulView {
  const PrepareDashboardView({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<PrepareDashboardView> createState() =>
      _PrepareDashboardViewState();
}

class _PrepareDashboardViewState extends ConsumerState<PrepareDashboardView> {
  @override
  void initState() {
    super.initState();
    _checkSelfNetworks();
  }

  @override
  Widget build(BuildContext context) =>
      AppFullScreenSpinner(text: getAppLocalizations(context).processing);

  _checkSelfNetworks() async {
    await ref.read(connectivityProvider.notifier).forceUpdate();
    if (context.read<AuthBloc>().state is AuthCloudLoginState) {
      if (context.read<NetworkCubit>().state.selected == null) {
        // TODO #LINKSYS
        // await context.read<AccountCubit>().fetchAccount();
        await context
            .read<NetworkCubit>()
            .getNetworks(accountId: context.read<AccountCubit>().state.id);
        ref
            .read(navigationsProvider.notifier)
            .clearAndPush(SelectNetworkPath());
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
      ref.watch(navigationsProvider.notifier).clearAndPush(DashboardHomePath());
      ref.watch(pollingProvider.notifier).startPolling();
    } else {
      // TODO #LINKSYS Error handling for unable to get deviceinfo
    }
  }
}
