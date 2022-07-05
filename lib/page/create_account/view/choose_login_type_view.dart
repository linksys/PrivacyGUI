import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/base_components/input_fields/input_field.dart';
import 'package:moab_poc/page/components/base_components/selectable_item.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';

class ChooseLoginTypeView extends ArgumentsStatefulView {
  const ChooseLoginTypeView(
      {Key? key, super.args})
      : super(key: key);

  @override
  _ChooseLoginTypeState createState() => _ChooseLoginTypeState();
}

class _ChooseLoginTypeState extends State<ChooseLoginTypeView> {
  final List<LoginMethod> _methods = [
    LoginMethod('Send me a code', '(Recommended)'),
    LoginMethod('Password', null),
  ];
  late String selectedMethod;

  @override
  void initState() {
    super.initState();
    selectedMethod = _methods.first.name;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Choose login method',
        ),
        content: Column(
          children: [
            SizedBox(
              height: 93.0 * _methods.length,
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _methods.length,
                  itemBuilder: (context, index) => GestureDetector(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: SelectableItem(
                            text: _methods[index].name,
                            description: _methods[index].description,
                            isSelected: selectedMethod == _methods[index].name,
                            height: 79,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedMethod = _methods[index].name;
                          });
                        },
                      )),
            ),
            SizedBox(
              height: selectedMethod == 'Password' ? 27 : 35,
            ),
            Visibility(
              visible: selectedMethod == 'Password',
              child: PasswordValidationView(
                onSkip: () {
                  NavigationCubit.of(context).push(AlreadyHaveOldAccountPath());
                },
              ),
            ),
            PrimaryButton(
              text: 'Next',
              onPress: selectedMethod == 'Password'
                  ? () {
                      NavigationCubit.of(context).push(EnableTwoSVPath());
                    }
                  : () {
                      NavigationCubit.of(context)
                          .push(CreateAccountOtpPath()..args = {'username': 'test@linksys.com'});
                    },
            )
          ],
        ),
      ),
    );
  }
}

class LoginMethod {
  final String name;
  final String? description;

  LoginMethod(this.name, this.description);
}

class PasswordValidationView extends StatefulWidget {
  final TextEditingController textController = TextEditingController();
  final void Function() onSkip;

  PasswordValidationView({
    Key? key,
    required this.onSkip,
  }) : super(key: key);

  @override
  _PasswordValidationState createState() => _PasswordValidationState();
}

class _PasswordValidationState extends State<PasswordValidationView> {
  late final List<PasswordValidation> _passwordValidations = [
    PasswordValidation('At least 10 characters', false),
    PasswordValidation('Upper and lowercase letters', false),
    PasswordValidation('1 number', false),
    PasswordValidation('1 special character', false),
  ];

  @override
  Widget build(BuildContext context) {
    // TODO: need a font size 12 here
    TextStyle? _textStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(color: Theme.of(context).colorScheme.surface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputField(
          titleText: 'Password',
          hintText: 'Password',
          controller: widget.textController,
          onChanged: (value) {
            setState(() {
              _passwordValidations[0].validation =
                  widget.textController.text.length >= 10;
              _passwordValidations[1].validation =
                  widget.textController.text.containUpperAndLowercaseLetters();
              _passwordValidations[2].validation =
                  widget.textController.text.containOneNumber();
              _passwordValidations[3].validation =
                  widget.textController.text.containOneSpecialCharacter();
            });
          },
        ),
        const SizedBox(
          height: 22,
        ),
        Text(
          'PasswordValidation',
          style: _textStyle,
        ),
        const SizedBox(
          height: 2,
        ),
        SizedBox(
          height: 23.0 * _passwordValidations.length,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _passwordValidations.length,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    (_passwordValidations[index].validation
                        ? Image.asset('assets/images/icon_ellipse_green.png')
                        : Image.asset('assets/images/icon_ellipse.png')),
                    const SizedBox(
                      width: 7,
                    ),
                    Text(
                      _passwordValidations[index].text,
                      style: _textStyle,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(
          height: 29,
        ),
        SimpleTextButton(
            text: 'I already have a Linksys account password',
            onPressed: (){}),
        const SizedBox(
          height: 42,
        ),
      ],
    );
  }
}

class PasswordValidation {
  final String text;
  bool validation;

  PasswordValidation(this.text, this.validation);
}

extension StringValidators on String {
  containUpperAndLowercaseLetters() {
    RegExp regEx = RegExp(r"(?=.*[a-z])(?=.*[A-Z])\w+");
    return regEx.hasMatch(this);
  }

  containOneNumber() {
    RegExp regEx = RegExp(r"(?=.*?[0-9])\w+");
    return regEx.hasMatch(this);
  }

  containOneSpecialCharacter() {
    RegExp regEx = RegExp(
        r"(?=.*?[\x20-\x29\x2A-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7D-\x7E])\w+");
    return regEx.hasMatch(this);
  }

  isValidEmailFormat() {
    RegExp regEx = RegExp(
        r"^[a-zA-Z0-9.!#$%&‘*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
    return regEx.hasMatch(this);
  }
}
