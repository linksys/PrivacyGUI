import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BaseLayout extends StatelessWidget {
  final Widget? header;
  final Widget? content;
  final Widget? footer;

  const BaseLayout({
    Key? key,
    this.header,
    this.content,
    this.footer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        header ?? Container(),
        content ?? Container(),
        const Spacer(),
        footer ?? Container(),
      ],
    );
  }

}