import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class OTPMethodSelectorView extends ArgumentsConsumerStatefulView {
  const OTPMethodSelectorView({Key? key, super.args, super.next})
      : super(key: key);

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
      child: AppBasicLayout(
        header: AppText.screenName(
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
            AppPrimaryButton(
              key: const Key('otp_method_selector_view_button_continue'),
              !state.isSendFunction() &&
                      state.selectedMethod?.method ==
                          CommunicationMethodType.sms.name.toUpperCase()
                  ? getAppLocalizations(context).add_phone_number
                  : getAppLocalizations(context).text_continue,
              onTap: () {
                !state.isSendFunction()
                    ? _checkPhoneExist(state.selectedMethod!, state.token)
                    : _onSend(state.selectedMethod!);
              },
            ),
            const AppGap.extraBig(),
            if (state.isSettingFunction())
              AppTertiaryButton(
                key: const Key(
                    'otp_method_selector_view_button_create_password'),
                getAppLocalizations(context).otp_create_password_instead,
                onTap: () {
                  final username = widget.args['username'];
                  ref.read(navigationsProvider.notifier).push(
                      CreateCloudPasswordPath()..args = {'username': username});
                },
              ),
          ],
        ),
      ),
    );
  }

  String _createTitle(OtpState state) {
    if (state.isSendFunction()) {
      return getAppLocalizations(context).otp_send_method_choice_title;
    } else if (state.isSettingFunction()) {
      return getAppLocalizations(context).otp_setting_method_choice_title;
    } else if (state.isSetting2svFunction()) {
      return getAppLocalizations(context).otp_2sv_setting_method_choice_title;
    } else {
      return '';
    }
  }

  String _createDescription(OtpState state) {
    if (state.isSendFunction()) {
      return '';
    } else if (state.isSettingFunction()) {
      return getAppLocalizations(context).otp_method_choice_description;
    } else if (state.isSetting2svFunction()) {
      return getAppLocalizations(context).otp_method_choice_description;
    } else {
      return '';
    }
  }

  _checkPhoneExist(CommunicationMethod method, String token) {
    if (method.method == CommunicationMethodType.sms.name.toUpperCase()) {
      ref.read(otpProvider.notifier).addPhone();
      ref.read(navigationsProvider.notifier).push(OtpAddPhonePath()
        ..next = widget.next
        ..args.addAll(widget.args));
    } else {
      _onSend(method);
    }
  }

  _onSend(CommunicationMethod method) {
    _setLoading(true);
    ref.read(otpProvider.notifier).onInputOtp();
    ref.read(navigationsProvider.notifier).push(OtpInputCodePath()
      ..next = widget.next
      ..args.addAll(widget.args));
    _setLoading(false);
  }

  _setLoading(bool isLoading) {
    ref.read(otpProvider.notifier).setLoading(isLoading);
  }
}
