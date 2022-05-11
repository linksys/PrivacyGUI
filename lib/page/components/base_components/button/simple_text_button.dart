import 'package:flutter/material.dart';

class SimpleTextButton extends StatelessWidget {

  const SimpleTextButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  final String text;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(
        text,
        style: Theme.of(context).textTheme.button?.copyWith(
          color: Theme.of(context).colorScheme.onTertiary,
        ),
      ),
      onPressed: onPressed,
    );
  }
}