import 'package:flutter/material.dart';

class SimpleTextButton extends StatelessWidget {
  const SimpleTextButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.padding,
    this.style,
  }) : super(key: key);

  factory SimpleTextButton.noPadding({
    Key? key,
    required String text,
    required void Function() onPressed,
  }) {
    return SimpleTextButton(text: text, onPressed: onPressed, padding: EdgeInsets.zero,);
  }

  factory SimpleTextButton.onPaddingWithStyle({
    Key? key,
    required String text,
    required void Function() onPressed,
    required TextStyle textStyle
  }) {
    return SimpleTextButton(text: text, onPressed: onPressed, padding: EdgeInsets.zero, style: textStyle);
  }

  final String text;
  final void Function() onPressed;
  final EdgeInsets? padding;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: padding == null ? null : TextButton.styleFrom(padding: padding),
      child: Text(
        text,
        style: style ?? Theme.of(context).textTheme.button?.copyWith(
              color: Theme.of(context).colorScheme.onTertiary,
            ),
      ),
      onPressed: onPressed,
    );
  }
}
