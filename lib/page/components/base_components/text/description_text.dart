import 'package:flutter/material.dart';

class DescriptionText extends StatelessWidget {
  final String text;

  const DescriptionText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .headline3
          ?.copyWith(color: Theme.of(context).colorScheme.tertiary)
          ?.copyWith(height: 1.5),
    );
  }
}
