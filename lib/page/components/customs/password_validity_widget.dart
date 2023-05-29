import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

class PasswordValidityWidget extends ConsumerWidget {
  final List<PasswordValidation> _validityList = [
    PasswordValidation('At least 10 characters', LengthRule().name, false),
    PasswordValidation(
        'Upper and lowercase letters', HybridCaseRule().name, false),
    PasswordValidation('1 number', DigitalCheckRule().name, false),
    PasswordValidation(
        '1 special character', SpecialCharCheckRule().name, false),
  ];
  final String passwordText;
  final void Function(bool isValid)? onValidationChanged;

  PasswordValidityWidget({
    Key? key,
    required this.passwordText,
    this.onValidationChanged,
  }) : super(key: key) {
    Map<String, bool> validityList =
        ComplexPasswordValidator().validateDetail(passwordText);
    _validityList
        .map((element) =>
            element.validation = validityList[element.ruleName] ?? true)
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextStyle? textStyle = Theme.of(context)
        .textTheme
        .headlineMedium
        ?.copyWith(color: Theme.of(context).colorScheme.surface);

    List<Widget> columnList = [
      Text(
        'Password must have',
        style: textStyle,
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
              style: textStyle,
            ),
          ],
        );
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columnList,
    );
  }
}

class PasswordValidation {
  final String text;
  final String ruleName;
  bool validation;

  PasswordValidation(this.text, this.ruleName, this.validation);
}
