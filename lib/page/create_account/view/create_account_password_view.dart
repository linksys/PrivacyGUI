import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_state.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/navigation_cubit.dart';
import 'package:moab_poc/route/route.dart';

class CreateAccountPasswordView extends ArgumentsStatefulView {
  const CreateAccountPasswordView({Key? key, super.args}) : super(key: key);

  @override
  _CreateAccountPasswordViewState createState() =>
      _CreateAccountPasswordViewState();
}

class _CreateAccountPasswordViewState extends State<CreateAccountPasswordView> {
  final TextEditingController passwordController = TextEditingController();
  bool hasError = false;

  void _onNextAction() {
    hasError = passwordController.text.isEmpty;
    if (hasError) {
      setState(() {});
    } else {
      final username = context.read<AuthBloc>().state.accountInfo.username;
      NavigationCubit.of(context).push(CreateAccount2SVPath()
        ..args = {
          'username': username,
          'function': OtpFunction.setting2sv
        });
    }
  }


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Create a password',
        ),
        content: Column(
          children: [
            const SizedBox(height: 15,),
            PasswordInputField.withValidator(
              titleText: 'Password',
              controller: passwordController,
              isError: hasError,
              onChanged: (value) {
                setState(() {
                  hasError = false;
                });
              },
            ),
            SimpleTextButton(
                text: 'I already have a Linksys account password',
                onPressed: () {
                  NavigationCubit.of(context).push(SameAccountPromptPath());
                }),
            const SizedBox(
              height: 30,
            ),
            PrimaryButton(
              text: 'Next',
              onPress: _onNextAction,
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}

