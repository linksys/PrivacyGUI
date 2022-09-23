import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/create_account/view/_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:pin_code_fields/pin_code_fields.dart';

class LocalRecoveryKeyView extends ArgumentsStatefulView {
  const LocalRecoveryKeyView({Key? key, super.args}) : super(key: key);

  @override
  _LocalResetRouterPasswordState createState() =>
      _LocalResetRouterPasswordState();
}

class _LocalResetRouterPasswordState
    extends State<LocalRecoveryKeyView> {
  bool _isLoading = false;
  final TextEditingController _otpController = TextEditingController();
  String _errorReason = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => _isLoading
          ? FullScreenSpinner(text: getAppLocalizations(context).processing)
          : _contentView(),
    );
  }

  Widget _contentView() {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).reset_router_password,
        ),
        content: Column(
          children: [
            PinCodeTextField(
              onChanged: (String value) {
                setState(() {
                  _errorReason = '';
                });
              },
              onCompleted: (String? value) => _onNext(value),
              length: 5,
              appContext: context,
              controller: _otpController,
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                  shape: PinCodeFieldShape.underline,
                  fieldHeight: 46,
                  fieldWidth: 48,
                  activeFillColor: Colors.transparent,
                  inactiveFillColor: Colors.transparent,
                  selectedFillColor: Colors.transparent,
                  inactiveColor: Colors.white),
            ),
            const SizedBox(
              height: 16,
            ),
            if (_errorReason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  _errorReason,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _onNext(String? value) {
    NavigationCubit.of(context).push(AuthLocalResetPasswordPath()..args = {'type': AdminPasswordType.reset});
    // NavigationCubit.of(context).push(AuthResetLocalOtpPath()
    //   ..args = {
    //     'username': 'austin.chang@linksys.com', // TODO
    //   });
  }
}
