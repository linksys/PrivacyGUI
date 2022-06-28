import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/state.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:moab_poc/page/components/base_components/selectable_item.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/logger.dart';

class LoginOTPMethodsView extends ArgumentsStatefulView {
  const LoginOTPMethodsView(
      {Key? key, super.args})
      : super(key: key);

  @override
  _ChooseOTPMethodsState createState() => _ChooseOTPMethodsState();
}

class _ChooseOTPMethodsState extends State<LoginOTPMethodsView> {
  late List<OtpInfo> _methods;
  late OtpInfo selectedMethod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    logger.d('LoginOTPMethodsView: ${widget.args}');
    setState(() {
      _methods = widget.args!['otpMethod'] as List<OtpInfo>;
    });
    selectedMethod = _methods.first;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) =>
      _isLoading
          ? const FullScreenSpinner(text: 'processing...')
          : _contentView(),
    );
  }

  Widget _contentView() {
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
                itemCount: _methods.length,
                itemBuilder: (context, index) =>
                    GestureDetector(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SelectableItem(
                          text: _methods[index].method == OtpMethod.email
                              ? _methods[index].data
                              : _methods[index].method.name.toUpperCase(),
                          isSelected: selectedMethod == _methods[index],
                          height: 66,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedMethod = _methods[index];
                        });
                      },
                    )),
            const SizedBox(
              height: 61,
            ),
            PrimaryButton(
              text: 'Send',
              onPress: _onSend,
            )
          ],
        ),
      ),
    );
  }

  _onSend() async {
    setState(() {
      _isLoading = true;
    });
    await context.read<AuthBloc>().passwordLessLogin(
        selectedMethod.data, selectedMethod.method.name).then((value) =>
        NavigationCubit.of(context).push(AuthInputOtpPath()
          ..args = {'dest': selectedMethod, 'token': value})
    );
    setState(() {
      _isLoading = false;
    });
  }
}
