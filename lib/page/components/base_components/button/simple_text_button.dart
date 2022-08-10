import 'package:flutter/material.dart';

class SimpleTextButton extends StatelessWidget {
  const SimpleTextButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.padding
  }) : super(key: key);

  factory SimpleTextButton.noPadding({
    Key? key,
    required String text,
    required void Function() onPressed,
  }) {
    return SimpleTextButton(text: text, onPressed: onPressed, padding: EdgeInsets.zero,);
  }

  final String text;
  final void Function() onPressed;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: padding == null ? null : TextButton.styleFrom(padding: padding),
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
