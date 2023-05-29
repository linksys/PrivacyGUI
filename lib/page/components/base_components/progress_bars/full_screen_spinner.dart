import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';

class FullScreenSpinner extends ConsumerWidget {
  final String? text;
  final Color? background;
  final Color? color;
  const FullScreenSpinner({Key? key, this.text, this.background, this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration:
          BoxDecoration(color: background ?? Theme.of(context).colorScheme.background),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: color ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(
              height: 8,
            ),
            DescriptionText(text: text ?? ''),
          ],
        ),
      ),
    );
  }
}
