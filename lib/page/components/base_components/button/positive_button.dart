import 'package:flutter/material.dart';

class PositiveButton extends StatelessWidget {
  final String? text;
  final Icon? icon;
  final void Function()? onPress;

  const PositiveButton({Key? key, this.text, this.icon, this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return icon != null ?
    ElevatedButton.icon(
      icon: icon!,
      label: const Text('Elevated Button'),
      style: ElevatedButton.styleFrom(
        primary: Theme.of(context).colorScheme.onPrimary,
        onPrimary: Theme.of(context).colorScheme.primary,
        textStyle: Theme.of(context).textTheme.button,
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: () => print('Tap Elevated Button'),
    )
    :
    ElevatedButton(
      child: Text(text ?? ''),
      style: ElevatedButton.styleFrom(
        primary: Theme.of(context).colorScheme.onPrimary,
        onPrimary: Theme.of(context).colorScheme.primary,
        textStyle: Theme.of(context).textTheme.button,
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: onPress ?? () {
        print('PositiveButton onPress');
      },
    );
  }

}