import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/event.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/util/logger.dart';

import '../../../bloc/auth/bloc.dart';
import '../../../bloc/auth/state.dart';
import '../../components/base_components/progress_bars/full_screen_spinner.dart';

class CloudReadyForLoginView extends ArgumentsStatefulView {
  const CloudReadyForLoginView({Key? key}) : super(key: key);

  @override
  _CloudReadyForLoginViewState createState() => _CloudReadyForLoginViewState();
}

class _CloudReadyForLoginViewState extends State<CloudReadyForLoginView> {
  @override
  void initState() {
    super.initState();
    _processLogin();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) => BasePageView.noNavigationBar(
              child: FullScreenSpinner(
                  text: getAppLocalizations(context).processing),
            ));
  }

  Future<void> _processLogin() async {
    final _authBloc = context.read<AuthBloc>();
    _authBloc
        .login()
        .then((state) => context.read<AuthBloc>().add(Authorized()));
  }
}
