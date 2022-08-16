import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth/bloc.dart';
import '../../../bloc/auth/event.dart';
import '../../../bloc/auth/state.dart';
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

  _checkSelfNetworks() {
    // TODO: Need to be modified
    // NavigationCubit.of(context).clearAndPush(NoRouterPath());
    // NavigationCubit.of(context).clearAndPush(RouterPickerPath());
    NavigationCubit.of(context).clearAndPush(DashboardHomePath());
  }
}
