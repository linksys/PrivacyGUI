import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecondaryButton extends ConsumerWidget {
  final String? text;
  final Icon? icon;
  final VoidCallback? onPress;

  const SecondaryButton({Key? key, this.text, this.icon, this.onPress})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonTitle = Text(text ?? '');
    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSecondary, backgroundColor: Theme.of(context).colorScheme.secondary,
      minimumSize: const Size.fromHeight(56),
      elevation: 0,
    );

    return icon != null
        ? ElevatedButton.icon(
            icon: icon!,
            label: buttonTitle,
            style: buttonStyle,
            onPressed: onPress,
          )
        : ElevatedButton(
            style: buttonStyle,
            onPressed: onPress,
            child: buttonTitle,
          );
  }
}
