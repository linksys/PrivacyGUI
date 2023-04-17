import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BaseAppBar extends ConsumerWidget {
  const BaseAppBar(
      {Key? key,
      this.title,
      required this.leading,
      required this.action,
      this.alignment})
      : super(key: key);

  final Widget? title;
  final List<Widget> leading;
  final List<Widget> action;
  final MainAxisAlignment? alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> children = [];
    children.addAll(leading);
    children.add(const Spacer());
    if (title != null) children.add(title!);
    children.add(const Spacer());
    children.addAll(action);

    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: alignment ?? MainAxisAlignment.start,
        children: children,
      ),
    );
  }
}
