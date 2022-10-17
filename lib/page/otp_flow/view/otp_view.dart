import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';


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
  late final OtpCubit _cubit;
  late String _username;
  late OtpFunction _function;

  @override
  initState() {
    _cubit = context.read<OtpCubit>();
    OtpFunction _function = OtpFunction.send;
    if (widget.args.containsKey('function')) {
      _function = widget.args['function'] as OtpFunction;
    }
    CommunicationMethod? selected = widget.args['selected'];
    final List<CommunicationMethod> _methods = widget.args['commMethods'] ?? [];
    final String _vToken = widget.args['token'] ?? '';
    Future.delayed(Duration(milliseconds: 100), () {
      _cubit.updateToken(_vToken);
      _cubit.updateOtpMethods(_methods, _function);
      if (selected != null) {
        _cubit.onInputOtp(method: selected);
      }
    });

    ///////////
    _username = widget.args['username'] as String;
    // _fetchToken();
    // _fetchOtpInfo(_function);
    //////////
    super.initState();
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

  // _fetchToken() {
  //   String vToken = '';
  //   if (context.read<AuthBloc>().state is AuthOnCloudLoginState) {
  //     vToken = (context.read<AuthBloc>().state as AuthOnCloudLoginState).vToken;
  //   } else if (context.read<AuthBloc>().state is AuthOnCreateAccountState) {
  //     vToken = (context.read<AuthBloc>().state as AuthOnCreateAccountState).vToken;
  //   } else {
  //     logger.d('ERROR: OtpFlowView: _fetchToken: Unexpected state type');
  //   }
  //   context.read<OtpCubit>().updateToken(vToken);
  // }

  // _fetchOtpInfo(OtpFunction function) async {
  //   _setLoading(true);
  //   await context
  //       .read<AuthBloc>()
  //       .fetchOtpInfo(_username)
  //       .then((value) => _handleAccountInfo(value, function));
  //   _setLoading(false);
  // }
  //
  // _handleAccountInfo(AccountInfo info, OtpFunction function) {
  //   context.read<OtpCubit>().updateOtpMethods(info.otpInfo, function);
  // }
}
