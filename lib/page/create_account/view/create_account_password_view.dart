import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/provider/auth/_auth.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class CreateAccountPasswordView extends ArgumentsConsumerStatefulView {
  const CreateAccountPasswordView({Key? key, super.args}) : super(key: key);

  @override
  _CreateAccountPasswordViewState createState() =>
      _CreateAccountPasswordViewState();
}

class _CreateAccountPasswordViewState
    extends ConsumerState<CreateAccountPasswordView> {
  final TextEditingController passwordController = TextEditingController();
  bool hasError = false;

  void _onNextAction() {
    hasError = !ComplexPasswordValidator().validate(passwordController.text);
    if (hasError) {
      setState(() {});
    } else {
      // // Remove old value
      // context.read<AuthBloc>().add(SetCloudPassword(password: ''));
      // context
      //     .read<AuthBloc>()
      //     .add(SetCloudPassword(password: passwordController.text));
      // TODO set passwod?
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO
    final data = ref.watch(authProvider);
    return _contentView();
    // return BlocConsumer<AuthBloc, AuthState>(
    //     listenWhen: (previous, current) {
    //       if (previous is AuthOnCreateAccountState &&
    //           current is AuthOnCreateAccountState) {
    //         return previous.accountInfo.password !=
    //             current.accountInfo.password;
    //       }
    //       return false;
    //     },
    //     listener: (context, state) {
    //       if (state is AuthOnCreateAccountState) {
    //         if (state.accountInfo.password.isNotEmpty) {
    //           final username = state.accountInfo.username;
    //           ref.read(navigationsProvider.notifier).push(CreateAccount2SVPath()
    //             ..args = {
    //               'username': username,
    //               'function': OtpFunction.setting2sv,
    //               'commMethods': state.accountInfo.communicationMethods,
    //               'token': state.vToken,
    //             });
    //         }
    //       }
    //     },
    //     builder: (context, state) => _contentView());
  }

  Widget _contentView() {
    return StyledAppPageView(
      scrollable: true,
      child: AppBasicLayout(
        header: const BasicHeader(
          title: 'Create a password',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.regular(),
            AppPasswordField.withValidator(
              headerText: 'Password',
              controller: passwordController,
              onChanged: (value) {
                setState(() {
                  hasError = false;
                });
              },
              validations: [
                Validation(
                  description: 'At least 10 characters',
                  validator: (text) => LengthRule().validate(text),
                ),
                Validation(
                  description: 'Upper and lowercase letters',
                  validator: (text) => HybridCaseRule().validate(text),
                ),
                Validation(
                  description: '1 number',
                  validator: (text) => DigitalCheckRule().validate(text),
                ),
                Validation(
                  description: '1 special character',
                  validator: (text) => SpecialCharCheckRule().validate(text),
                ),
              ],
            ),
            AppTertiaryButton('I already have a Linksys account password',
                onTap: () {
              
            }),
            const AppGap.big(),
            AppPrimaryButton(
              'Next',
              onTap: _onNextAction,
            ),
          ],
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}
