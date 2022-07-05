import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_cubit.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_state.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/navigation_cubit.dart';
import 'package:moab_poc/route/route.dart';

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
          title: state.isSettingLoginType ? 'Choose how to receive log in codes' : 'Where should we send your code?',
          description: state.isSettingLoginType ? 'We\'ll send you a one-time passcode that expires' : '',
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
              text: 'Send',
              onPress: () { state.isSettingLoginType ? _checkPhoneExist(state.selectedMethod!) : _onSend(state.selectedMethod!);},
            ),
            const SizedBox(
              height: 60,
            ),
            if (state.isSettingLoginType)
              SimpleTextButton(text: 'I want to create a password instead', onPressed: () {
                NavigationCubit.of(context).push(CreateCloudPasswordPath());
              }),
          ],
        ),
      ),
    );
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
