
import 'package:flutter/cupertino.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../theme/data/colors.dart';

class AppPinCodeInput extends StatelessWidget {

  final void Function(String)? onChanged;
  final void Function(String?)? onCompleted;
  final int length;
  final bool enabled;

  const AppPinCodeInput({super.key,
    this.onChanged,
    this.onCompleted,
    required this.length,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      key: const Key('otp_input_view_input_field_code'),
      onChanged: (String value) {},
      onCompleted: (String? value) {},
      length: 4,
      enabled: enabled,
      appContext: context,
      keyboardType: TextInputType.number,
      hintCharacter: '-',
      cursorColor: ConstantColors.primaryLinksysWhite,
      enableActiveFill: true,
      pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          fieldHeight: 102,
          fieldWidth: 88,
          activeFillColor: ConstantColors.baseSecondaryGray,
          inactiveFillColor: ConstantColors.baseSecondaryGray,
          selectedFillColor: ConstantColors.baseSecondaryGray,
          inactiveColor: ConstantColors.baseSecondaryGray,
          activeColor: ConstantColors.baseSecondaryGray,
          selectedColor: ConstantColors.primaryLinksysWhite),
    );
  }
}