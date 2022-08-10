import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/bloc/otp/otp_cubit.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/model/otp_path.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/util/logger.dart';


class OtpFlowView extends ArgumentsStatelessView {
  const OtpFlowView({Key? key, super.args, super.next}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ContentView(
      args: args,
      next: next,
    );
  }
}

class _ContentView extends ArgumentsStatefulView {
  const _ContentView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<_ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<_ContentView> {
  late String _username;
  late OtpFunction _function;

  @override
  initState() {
    super.initState();
    _username = widget.args['username'] as String;
    logger.d('OTP flow: $_username');
    logger.d('NEXT: ${widget.next}');

    OtpFunction _function = OtpFunction.send;
    if (widget.args.containsKey('function')) {
      _function = widget.args['function'] as OtpFunction;
    }
    _fetchToken();
    _fetchOtpInfo(_function);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OtpCubit, OtpState>(
      listenWhen: (previous, next) {
        return previous.step != next.step;
      },
      listener: (context, state) {
        if (state.step == OtpStep.inputOtp) {
          final next = widget.next ?? UnknownPath();
          logger.d('NEXT2: ${next}');

          NavigationCubit.of(context).replace(OtpInputCodePath()
            ..args.addAll(widget.args)
            ..next = next);
        } else if (state.step == OtpStep.chooseOtpMethod) {
          final next = widget.next ?? UnknownPath();
          NavigationCubit.of(context).replace(OtpMethodChoosesPath()
            ..next = next
            ..args.addAll(widget.args));
        }
      },
      builder: (context, state) => Stack(children: [
        WillPopScope(
            onWillPop: () async {
              if (state.isLoading) {
                return false;
              } else if (state.step != OtpStep.chooseOtpMethod) {
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
    return BasePageView.noNavigationBar();
  }

  _setLoading(bool isLoading) {
    context.read<OtpCubit>().setLoading(isLoading);
  }

  _fetchToken() {
    context.read<OtpCubit>().updateToken(context.read<AuthBloc>().state.vToken);
  }

  _fetchOtpInfo(OtpFunction function) async {
    _setLoading(true);
    await context
        .read<AuthBloc>()
        .fetchOtpInfo(_username)
        .then((value) => _handleAccountInfo(value, function));
    _setLoading(false);
  }

  _handleAccountInfo(AccountInfo info, OtpFunction function) {
    context.read<OtpCubit>().updateOtpMethods(info.otpInfo, function);
  }
}
