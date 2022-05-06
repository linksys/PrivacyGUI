import 'package:flutter/material.dart';

class PositiveButton extends StatelessWidget {
  final String? text;
  final Icon? icon;
  final void Function()? onPress;

  const PositiveButton({Key? key, this.text, this.icon, this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonTitle = Text(text ?? '');
    final buttonStyle = ElevatedButton.styleFrom(
      primary: Theme.of(context).colorScheme.primary,
      onPrimary: Theme.of(context).colorScheme.onPrimary,
      textStyle: Theme.of(context).textTheme.button,
      minimumSize: const Size.fromHeight(56),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
    final action = onPress ?? () => print('PositiveButton onPressed');

    return icon != null
        ? ElevatedButton.icon(
            icon: icon!,
            label: buttonTitle,
            style: buttonStyle,
            onPressed: action,
          )
        : ElevatedButton(
            child: buttonTitle,
            style: buttonStyle,
            onPressed: action,
          );
  }
}
