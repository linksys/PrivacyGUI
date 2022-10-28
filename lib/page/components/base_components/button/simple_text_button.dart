import 'package:flutter/material.dart';

class SimpleTextButton extends StatelessWidget {
  const SimpleTextButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.padding,
    this.style,
  }) : super(key: key);

  factory SimpleTextButton.noPadding({
    Key? key,
    required String text,
    TextStyle? style,
    void Function()? onPressed,
  }) {
    return SimpleTextButton(
      text: text,
      style: style,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
    );
  }

  factory SimpleTextButton.onPaddingWithStyle(
      {Key? key,
      required String text,
      void Function()? onPressed,
      required TextStyle textStyle}) {
    return SimpleTextButton(
        text: text,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: textStyle);
  }

  final String text;
  final void Function()? onPressed;
  final EdgeInsets? padding;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: padding == null ? null : TextButton.styleFrom(padding: padding),
      child: Text(
        text,
        style: style ??
            Theme.of(context).textTheme.button?.copyWith(
                  color: onPressed != null
                      ? Theme.of(context).colorScheme.onTertiary
                      : const Color.fromRGBO(8, 112, 234, 0.5),
                ),
      ),
      onPressed: onPressed,
    );
  }
}
