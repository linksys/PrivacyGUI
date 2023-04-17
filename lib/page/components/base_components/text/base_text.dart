import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/design/text_style.dart';

class BaseText extends ConsumerWidget {
  final String text;
  final TextStyle style;
  final Color? color;

  const BaseText({
    super.key,
    required this.text,
    required this.style,
    this.color,
  });

  // BaseText.title(this.text, {super.key, this.color}) : style = bold23;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      text,
      style: color != null ? style.copyWith(color: color) : style,
    );
  }
}
