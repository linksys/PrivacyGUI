import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/provider/otp/otp.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/cloud/model/cloud_communication_method.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

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
      child: AppBasicLayout(
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
                      child: AppPadding(
                        padding: const AppEdgeInsets.symmetric(
                            vertical: AppGapSize.small),
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
            const AppGap.extraBig(),
            AppPrimaryButton.fillWidth(
              key: const Key('otp_method_selector_view_button_continue'),
              getAppLocalizations(context).text_continue,
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
    return getAppLocalizations(context).otp_send_method_choice_title;
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
