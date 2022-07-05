import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:moab_poc/page/components/base_components/selectable_item.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class LocalResetRouterPasswordView extends ArgumentsStatefulView {
  const LocalResetRouterPasswordView({Key? key, super.args}) : super(key: key);

  @override
  _LocalResetRouterPasswordState createState() =>
      _LocalResetRouterPasswordState();
}

class _LocalResetRouterPasswordState
    extends State<LocalResetRouterPasswordView> {
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
          ? const FullScreenSpinner(text: 'processing...')
          : _contentView(),
    );
  }

  Widget _contentView() {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Reset router password',
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
    // NavigationCubit.of(context).clearAndPush(DashboardMainPath());
    NavigationCubit.of(context).push(AuthResetLocalOtpPath()
      ..args = {
        'username': 'austin.chang@linksys.com', // TODO
      });
  }
}
