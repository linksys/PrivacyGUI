import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/network/http/model/base_response.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/util/validator.dart';

import '../../../bloc/auth/bloc.dart';
import '../../../bloc/auth/state.dart';
import '../../../repository/model/dummy_model.dart';
import '../../../route/navigation_cubit.dart';
import '../../components/base_components/input_fields/input_field.dart';
import '../../components/base_components/progress_bars/full_screen_spinner.dart';
import '../../components/customs/password_validity_widget.dart';
import '../../create_account/view/create_account_password_view.dart';

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
    _authBloc.login().then((state) => _authBloc);
  }

}
