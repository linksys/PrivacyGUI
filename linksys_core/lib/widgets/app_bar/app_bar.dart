import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';

class LinksysAppBar extends StatelessWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? trailing;

  const LinksysAppBar({
    Key? key,
    this.title,
    this.leading,
    this.trailing,
  }): super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ConstantColors.transparent,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _barLayout(),
      ),
    );
  }


  List<Widget> _barLayout() {
    final leading = this.leading;
    final title = this.title;
    final trailing = this.trailing;

    return [
      leading ?? const SizedBox(width: 44,),
      if (leading != null || (trailing != null && trailing.isNotEmpty)) const Spacer(),
      if (title != null) title,
      if (leading != null || (trailing != null && trailing.isNotEmpty)) const Spacer(),
      if (trailing != null && trailing.isNotEmpty) ...trailing,
      if (trailing == null || trailing.isEmpty) const SizedBox(width: 44,), // Extra check
    ];
  }
}