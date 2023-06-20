import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/provider/otp/otp.dart';
import 'package:linksys_moab/core/cloud/model/cloud_communication_method.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class OtpFlowView extends ArgumentsConsumerStatefulView {
  const OtpFlowView({Key? key, super.args, super.next}) : super(key: key);

  @override
  ConsumerState<OtpFlowView> createState() => OtpFlowViewState();
}

class OtpFlowViewState extends ConsumerState<OtpFlowView> {
  @override
  initState() {
    final otp = ref.read(otpProvider.notifier);
    OtpFunction function = OtpFunction.send;
    if (widget.args.containsKey('function')) {
      function = widget.args['function'] as OtpFunction;
    }
    CommunicationMethod? selected = widget.args['selected'];
    final List<CommunicationMethod>? methods = widget.args['commMethods'];
    final String vToken = widget.args['token'] ?? '';
    final String username = widget.args['username'] ?? '';
    final future = username.isEmpty
        ? Future.delayed(const Duration(milliseconds: 100))
        : otp.fetchMaskedMethods(username: username);
    future.then((_) {
      otp.updateToken(vToken);
      otp.updateOtpMethods(methods, function);
      if (selected != null) {
        otp.onInputOtp(method: selected);
      }
    });

    ///////////
    // _username = widget.args['username'] as String;
    // _fetchToken();
    // _fetchOtpInfo(_function);
    //////////
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(otpProvider, (previous, next) {
      final previousStep = previous?.step;
      final nextStep = next.step;
      if (nextStep == previousStep) {
        return;
      }
      if (nextStep == OtpStep.inputOtp) {
        final next = widget.next ?? UnknownPath();
        ref.read(navigationsProvider.notifier).replace(OtpInputCodePath()
          ..args.addAll(widget.args)
          ..next = next);
      } else if (nextStep == OtpStep.chooseOtpMethod) {
        final next = widget.next ?? UnknownPath();
        ref.read(navigationsProvider.notifier).replace(OtpMethodChoosesPath()
          ..next = next
          ..args.addAll(widget.args));
      }
    });
    final state = ref.watch(otpProvider);
    return Stack(children: [
      WillPopScope(
          onWillPop: () async {
            if (state.isLoading) {
              return false;
            } else if (state.step != OtpStep.chooseOtpMethod) {
              ref.watch(otpProvider.notifier).processBack();
              return false;
            } else {
              return true;
            }
          },
          child: _contentView(state)),
      if (state.isLoading)
        const AppFullScreenSpinner(
          text: '',
          background: Colors.transparent,
        )
    ]);
  }

  Widget _contentView(OtpState state) {
    return const AppPageView();
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
