import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TitleText extends ConsumerWidget {
  final String text;
  final TextStyle? style;

  const TitleText({Key? key, required this.text, this.style}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      text,
      style: style ??
          Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}
