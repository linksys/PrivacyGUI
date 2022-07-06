import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/customs/otp_flow/otp_state.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/navigation_cubit.dart';
import 'package:moab_poc/route/route.dart';

class CreateAccountPasswordView extends StatefulWidget {
  const CreateAccountPasswordView({Key? key}) : super(key: key);

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
      NavigationCubit.of(context).push(CreateAccount2SVPath()
        ..args = {
          'username': 'test@linksys.com',
          'function': OtpFunction.setting2sv
        });
    }
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: InputField(
                titleText: 'Password',
                controller: passwordController,
                isError: hasError,
                onChanged: (value) {
                  setState(() {
                    hasError = false;
                  });
                },
              ),
            ),
            PasswordValidityWidget(passwordText: passwordController.text),
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

//TODO: Move to the Common Widget directory
class PasswordValidityWidget extends StatelessWidget {
  final List<PasswordValidation> _validityList = [
    PasswordValidation('At least 10 characters', false),
    PasswordValidation('Upper and lowercase letters', false),
    PasswordValidation('1 number', false),
    PasswordValidation('1 special character', false),
  ];
  final String passwordText;

  PasswordValidityWidget({
    Key? key,
    required this.passwordText,
  }) : super(key: key) {
    _validityList.map((element) {
      switch (_validityList.indexOf(element)) {
        case 0:
          element.validation = passwordText.length >= 10;
          break;
        case 1:
          element.validation = passwordText.containUpperAndLowercaseLetters();
          break;
        case 2:
          element.validation = passwordText.containOneNumber();
          break;
        case 3:
          element.validation = passwordText.containOneSpecialCharacter();
          break;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle? _textStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(color: Theme.of(context).colorScheme.surface);

    List<Widget> _columnList = [
      Text(
        'Password must have',
        style: _textStyle,
      ),
      const SizedBox(
        height: 4,
      ),
      ...List.generate(_validityList.length, (index) {
        return Row(
          children: [
            _validityList[index].validation
                ? Image.asset('assets/images/icon_ellipse_green.png')
                : Image.asset('assets/images/icon_ellipse.png'),
            const SizedBox(
              width: 8,
            ),
            Text(
              _validityList[index].text,
              style: _textStyle,
            ),
          ],
        );
      }),
    ];

    return Column(
      children: _columnList,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}
