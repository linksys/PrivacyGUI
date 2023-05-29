import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DescriptionText extends ConsumerWidget {
  final String text;

  const DescriptionText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .displaySmall
          ?.copyWith(color: Theme.of(context).colorScheme.tertiary)
          .copyWith(height: 1.5),
    );
  }
}
