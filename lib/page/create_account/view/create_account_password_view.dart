import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/bloc/otp/otp.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/util/validator.dart';

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
    hasError = !ComplexPasswordValidator().validate(passwordController.text);
    if (hasError) {
      setState(() {});
    } else {
      // Remove old value
      context.read<AuthBloc>().add(SetCloudPassword(password: ''));
      context
          .read<AuthBloc>()
          .add(SetCloudPassword(password: passwordController.text));
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          if (previous is AuthOnCreateAccountState &&
              current is AuthOnCreateAccountState) {
            return previous.accountInfo.password !=
                current.accountInfo.password;
          }
          return false;
        },
        listener: (context, state) {
          if (state is AuthOnCreateAccountState) {
            if (state.accountInfo.password.isNotEmpty) {
              final username = state.accountInfo.username;
              NavigationCubit.of(context).push(CreateAccount2SVPath()
                ..args = {
                  'username': username,
                  'function': OtpFunction.setting2sv,
                  'commMethods': state.accountInfo.communicationMethods,
                  'token': state.vToken,
                });
            }
          }
        },
        builder: (context, state) => _contentView());
  }

  Widget _contentView() {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Create a password',
        ),
        content: Column(
          children: [
            const SizedBox(
              height: 15,
            ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}
