import 'package:flutter/material.dart';
import 'package:linksys_core/theme/_theme.dart';

class AppProgressBar extends StatefulWidget {
  const AppProgressBar({Key? key}) : super(key: key);

  @override
  State<AppProgressBar> createState() =>
      _AppProgressBarState();
}

class _AppProgressBarState extends State<AppProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _controller.addListener(() {
      setState(() {});
    });
    _controller.repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(0)),
      child: LinearProgressIndicator(
        value: _controller.value,
        backgroundColor: AppTheme.of(context).colors.textBoxText,
        color: ConstantColors.primaryLinksysBlue,
        minHeight: 8,
      ),
    );
  }
}
