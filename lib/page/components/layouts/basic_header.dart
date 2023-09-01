import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class BasicHeader extends ConsumerWidget {
  const BasicHeader(
      {Key? key,
      this.title,
      this.description,
      this.spacing,
      this.alignment,
      this.titleTextStyle})
      : super(key: key);

  final String? title;
  final String? description;
  final double? spacing;
  final CrossAxisAlignment? alignment;
  final TextStyle? titleTextStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: alignment ?? CrossAxisAlignment.start,
      children: [
        AppText.displayLarge(
          title ?? '',
        ),
        const AppGap.regular(),
        AppText.bodyMedium(description ?? ''),
      ],
    );
  }
}
