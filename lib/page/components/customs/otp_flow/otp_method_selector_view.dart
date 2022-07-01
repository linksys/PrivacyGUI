import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:moab_poc/page/components/base_components/selectable_item.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_cubit.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_state.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/logger.dart';

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
        header: const BasicHeader(
          title: 'Where should we send your code?',
        ),
        content: Column(
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
              height: 61,
            ),
            PrimaryButton(
              text: 'Send',
              onPress: () { _onSend(state.selectedMethod!);},
            )
          ],
        ),
      ),
    );
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
