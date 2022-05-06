import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BasicLayout extends StatelessWidget {
  final Widget? header;
  final Widget? content;
  final Widget? footer;
  final CrossAxisAlignment? alignment;

  const BasicLayout({
    Key? key,
    this.header,
    this.content,
    this.footer,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment ?? CrossAxisAlignment.center,
      children: [
        header ?? Container(),
        content ?? Container(),
        const Spacer(),
        footer ?? Container(),
      ],
    );
  }

}