import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_cubit.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_state.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/navigation_cubit.dart';
import 'package:moab_poc/route/route.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OTPMethodSelectorView extends ArgumentsStatefulView {
  const OTPMethodSelectorView(
      {Key? key, super.args})
      : super(key: key);

  @override
  _OTPMethodSelectorViewState createState() => _OTPMethodSelectorViewState();
}

class _OTPMethodSelectorViewState extends State<OTPMethodSelectorView> {

  @override
  void initState() {

  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
      builder: (context, state) => _contentView(state),
    );
  }

  Widget _contentView(OtpState state) {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: _createTitle(state),
          description: _createDescription(state),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.methods.length,
                itemBuilder: (context, index) =>
                    GestureDetector(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SelectableItem(
                          text: state.methods[index].method == OtpMethod.email
                              ? state.methods[index].data
                              : state.methods[index].method.name.toUpperCase(),
                          isSelected: state.selectedMethod == state.methods[index],
                          height: 66,
                        ),
                      ),
                      onTap: () {
                        context.read<OtpCubit>().selectOtpMethod(state.methods[index]);
                      },
                    )),
            const SizedBox(
              height: 60,
            ),
            PrimaryButton(
              text: !state.isSendFunction() && state.selectedMethod?.method == OtpMethod.sms ? getAppLocalizations(context).add_phone_number : getAppLocalizations(context).text_continue,
              onPress: () { !state.isSendFunction() ? _checkPhoneExist(state.selectedMethod!) : _onSend(state.selectedMethod!);},
            ),
            const SizedBox(
              height: 60,
            ),
            if (state.isSettingFunction())
              SimpleTextButton(text: getAppLocalizations(context).otp_create_password_instead, onPressed: () {
                NavigationCubit.of(context).push(CreateCloudPasswordPath());
              }),
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

  _checkPhoneExist(OtpInfo method) {
    if (method.method == OtpMethod.sms) {
      context.read<OtpCubit>().addPhone();
    } else {
      _onSend(method);
    }
  }
  _onSend(OtpInfo method) async {
    _setLoading(true);
    await context.read<AuthBloc>().passwordLessLogin(
        method.data, method.method.name).then((value) =>
        context.read<OtpCubit>().updateToken(value)
    );
    _setLoading(false);
  }

  _setLoading(bool isLoading) {
    context.read<OtpCubit>().setLoading(isLoading);
  }
}