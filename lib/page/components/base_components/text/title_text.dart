import 'package:flutter/material.dart';

class TitleText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const TitleText({Key? key, required this.text, this.style}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? Theme.of(context)
          .textTheme
          .headline1
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}
