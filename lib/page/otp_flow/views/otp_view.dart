import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/cloud/model/cloud_communication_method.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/otp_flow/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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

    CommunicationMethod? selected = widget.args['selected'];
    final List<CommunicationMethod>? methods = widget.args['commMethods'];
    final String vToken = widget.args['token'] ?? '';
    final String username = widget.args['username'] ?? '';
    final String function = widget.args['function'] ?? '';
    final future = function == 'add'
        ? otp.prepareAddMfa()
        : otp.fetchMfaMethods(username: username);
    future.then((_) {
      if (vToken.isNotEmpty) {
        otp.updateToken(vToken);
      }
      otp.updateOtpMethods(methods);
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
        context.pushReplacementNamed(RouteNamed.otpInputCode,
            extra: widget.args);
      } else if (next == OtpStep.chooseOtpMethod) {
        context.pushReplacementNamed(RouteNamed.otpSelectMethods,
            extra: widget.args);
      } else if (next == OtpStep.addPhone) {
        context.pushReplacementNamed(RouteNamed.otpAddPhone,
            extra: widget.args);
      }
    });
    return const AppFullScreenSpinner();
  }
}
