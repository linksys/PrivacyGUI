import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  final String? text;
  final Icon? icon;
  final VoidCallback? onPress;

  const SecondaryButton({Key? key, this.text, this.icon, this.onPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonTitle = Text(text ?? '');
    final buttonStyle = ElevatedButton.styleFrom(
      primary: Theme.of(context).colorScheme.secondary,
      onPrimary: Theme.of(context).colorScheme.onSecondary,
      textStyle: Theme.of(context).textTheme.button,
      minimumSize: const Size.fromHeight(56),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 0,
    );
    final action = onPress ?? () => print('SecondaryButton onPressed');

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
