import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/cloud/model/cloud_communication_method.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/otp_flow/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class OTPMethodSelectorView extends ArgumentsConsumerStatefulView {
  const OTPMethodSelectorView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<OTPMethodSelectorView> createState() =>
      _OTPMethodSelectorViewState();
}

class _OTPMethodSelectorViewState extends ConsumerState<OTPMethodSelectorView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpProvider);
    return _contentView(state);
  }

  Widget _contentView(OtpState state) {
    return StyledAppPageView(
      onBackTap: () {
        ref.read(otpProvider.notifier).processBack();
        context.pop();
      },
      child: (context, constraints) => AppBasicLayout(
        header: AppText.titleLarge(
          _createTitle(state),
          // description: _createDescription(state),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.methods.length,
                itemBuilder: (context, index) => InkWell(
                      key: Key(state.methods[index].method ==
                              CommunicationMethodType.email.name.toUpperCase()
                          ? 'otp_method_selector_view_button_email'
                          : 'otp_method_selector_view_button_sms'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: Spacing.small1),
                        child: AppPanelWithValueCheck(
                          title: state.methods[index].method ==
                                  CommunicationMethodType.email.name
                                      .toUpperCase()
                              ? state.methods[index].target
                              : state.methods[index].method,
                          valueText: ' ',
                          isChecked:
                              state.selectedMethod == state.methods[index],
                        ),
                      ),
                      onTap: () {
                        ref
                            .read(otpProvider.notifier)
                            .selectOtpMethod(state.methods[index]);
                      },
                    )),
            const AppGap.large5(),
            AppFilledButton.fillWidth(
              key: const Key('otp_method_selector_view_button_continue'),
              loc(context).textContinue,
              onTap: () {
                _onSend(state.selectedMethod!);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _createTitle(OtpState state) {
    return loc(context).otpSendMethodChoiceTitle;
  }

  _checkPhoneExist(
      BuildContext context, CommunicationMethod method, String token) {
    if (method.method == CommunicationMethodType.sms.name.toUpperCase()) {
      // Add phone number
    } else {
      _onSend(method);
    }
  }

  _onSend(CommunicationMethod method) {
    _setLoading(true);
    ref.read(otpProvider.notifier).onInputOtp();

    context.pushNamed(RouteNamed.otpInputCode, extra: widget.args);

    _setLoading(false);
  }

  _setLoading(bool isLoading) {
    ref.read(otpProvider.notifier).setLoading(isLoading);
  }
}
