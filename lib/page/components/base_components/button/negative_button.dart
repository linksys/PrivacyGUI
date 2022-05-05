import 'package:flutter/material.dart';

class NegativeButton extends StatelessWidget {
  final String? text;
  final Icon? icon;
  final void Function()? onPress;

  const NegativeButton({Key? key, this.text, this.icon, this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return icon != null ?
    ElevatedButton.icon(
      icon: icon!,
      label: const Text('Elevated Button'),
      style: ElevatedButton.styleFrom(
        primary: Theme.of(context).colorScheme.onSecondary,
        onPrimary: Theme.of(context).colorScheme.secondary,
        textStyle: Theme.of(context).textTheme.button,
        elevation: 0,
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: () => print('Tap Elevated Button'),
    )
        :
    ElevatedButton(
      child: Text(text ?? ''),
      style: ElevatedButton.styleFrom(
        primary: Theme.of(context).colorScheme.onSecondary,
        onPrimary: Theme.of(context).colorScheme.secondary,
        textStyle: Theme.of(context).textTheme.button,
        elevation: 0,
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: onPress ?? () {
        print('NegativeButton onPress');
      },
    );
  }

}