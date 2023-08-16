import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_moab/core/utils/logger.dart';
import 'package:linksys_moab/provider/otp/otp.dart';
import 'package:linksys_moab/core/cloud/model/cloud_communication_method.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/constants.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class OtpFlowView extends ArgumentsConsumerStatefulView {
  const OtpFlowView({
    Key? key,
    super.args,
  }) : super(key: key);

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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('otp view build!!!');
    ref.listen(otpProvider.select((value) => value.step), (previous, next) {
      if (next == OtpStep.inputOtp) {
        context.goNamed(RouteNamed.otpInputCode, queryParameters: widget.args);
      } else if (next == OtpStep.chooseOtpMethod) {
        context.goNamed(RouteNamed.otpSelectMethods,
            queryParameters: widget.args);
      }
    });
    return const AppFullScreenSpinner();
  }
}
