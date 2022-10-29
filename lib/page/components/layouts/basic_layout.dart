import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BasicLayout extends StatelessWidget {
  final Widget? header;
  final Widget? content;
  final Widget? footer;
  final CrossAxisAlignment? crossAxisAlignment;

  const BasicLayout({
    Key? key,
    this.header,
    this.content,
    this.footer,
    this.crossAxisAlignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    if (header != null) widgets.add(header!);
    if (content != null) widgets.add(Expanded(child: content!));
    if (footer != null) widgets.add(footer!);

    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      children: widgets,
    );
  }
}
