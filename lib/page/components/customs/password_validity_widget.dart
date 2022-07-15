import 'package:flutter/material.dart';
import 'package:moab_poc/util/validator.dart';

class PasswordValidityWidget extends StatelessWidget {
  final List<PasswordValidation> _validityList = [
    PasswordValidation('At least 10 characters', LengthRule().name, false),
    PasswordValidation(
        'Upper and lowercase letters', HybridCaseRule().name, false),
    PasswordValidation('1 number', DigitalCheckRule().name, false),
    PasswordValidation(
        '1 special character', SpecialCharCheckRule().name, false),
  ];
  final String passwordText;

  PasswordValidityWidget({
    Key? key,
    required this.passwordText,
  }) : super(key: key) {
    Map<String, bool> validityList =
        ComplexPasswordValidator().validateDetail(passwordText);
    _validityList
        .map((element) =>
            element.validation = validityList[element.ruleName] ?? true)
        .toList();
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

class PasswordValidation {
  final String text;
  final String ruleName;
  bool validation;

  PasswordValidation(this.text, this.ruleName, this.validation);
}
