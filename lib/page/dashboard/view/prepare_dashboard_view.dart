import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/account/_account.dart';
import 'package:linksys_moab/bloc/auth/_auth.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/security/security_profile_manager.dart';

import '../../../localization/localization_hook.dart';
import '../../../route/model/dashboard_path.dart';
import '../../../route/navigation_cubit.dart';
import '../../../util/logger.dart';
import '../../components/base_components/progress_bars/full_screen_spinner.dart';
import '../../components/views/arguments_view.dart';

class PrepareDashboardView extends ArgumentsStatefulView {
  const PrepareDashboardView({
    Key? key,
  }) : super(key: key);

  @override
  _PrepareDashboardViewState createState() => _PrepareDashboardViewState();
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

    return FullScreenSpinner(text: getAppLocalizations(context).processing);
  }

  _checkSelfNetworks() async {
    if (context.read<AuthBloc>().state is AuthCloudLoginState) {
      await context.read<ProfilesCubit>().fetchProfiles();
      await context.read<AccountCubit>().fetchAccount();
      await context.read<ConnectivityCubit>().connectToRemoteBroker();
      await context.read<NetworkCubit>().getNetworks(accountId: context.read<AccountCubit>().state.id);
    } else {
      await context.read<ConnectivityCubit>().connectToLocalBroker();
    }

    // await SecurityProfileManager.instance().fetchDefaultPresets();
    NavigationCubit.of(context).clearAndPush(DashboardHomePath());
  }
}
