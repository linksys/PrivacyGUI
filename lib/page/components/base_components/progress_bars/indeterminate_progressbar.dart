import 'package:flutter/material.dart';

class IndeterminateProgressBar extends StatefulWidget {
  const IndeterminateProgressBar({Key? key}) : super(key: key);

  @override
  _IndeterminateProgressBarState createState() =>
      _IndeterminateProgressBarState();
}

class _IndeterminateProgressBarState extends State<IndeterminateProgressBar>
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
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: LinearProgressIndicator(
        value: _controller.value,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        minHeight: 14,
      ),
    );
  }
}
