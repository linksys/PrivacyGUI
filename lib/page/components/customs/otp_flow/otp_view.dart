import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_code_input.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_cubit.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_method_selector_view.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';

import 'otp_state.dart';

class OtpFlowView extends ArgumentsStatelessView {
  const OtpFlowView({Key? key, super.args}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => OtpCubit(),
        child: _ContentView(
          args: args,
        ));
  }
}

class _ContentView extends ArgumentsStatefulView {
  const _ContentView({Key? key, super.args}) : super(key: key);

  @override
  State<_ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<_ContentView> {
  late BasePath _nextPath;
  late String _username;

  @override
  initState() {
    super.initState();
    _nextPath = widget.args!['onNext'] as BasePath;
    _username = widget.args!['username'] as String;
    _fetchOtpInfo();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
      builder: (context, state) => Stack(children: [
        WillPopScope(
            onWillPop: () async {
              if (state.isLoading) {
                return false;
              } else if (state.step == OtpStep.inputOtp){
                context.read<OtpCubit>().processBack();
                return false;
              } else {
                return true;
              }
            },
            child: _contentView(state)),
        if (state.isLoading)
          const FullScreenSpinner(
            text: '',
            background: Colors.transparent,
          )
      ]),
    );
  }

  Widget _contentView(OtpState state) {
    if (state.step == OtpStep.chooseOtpMethod) {
      return OTPMethodSelectorView();
    } else if (state.step == OtpStep.inputOtp) {
      return OtpCodeInputView(nextPath: _nextPath,);
    } else {
      return BasePageView.noNavigationBar();
    }
  }

  _setLoading(bool isLoading) {
    context.read<OtpCubit>().setLoading(isLoading);
  }

  _fetchOtpInfo() async {
    _setLoading(true);
    await context
        .read<AuthBloc>()
        .testUsername(_username)
        .then((value) => _handleAccountInfo(value));
    _setLoading(false);
  }

  _handleAccountInfo(AccountInfo info) {
    context.read<OtpCubit>().updateOtpMethods(info.otpInfo);
  }
}
