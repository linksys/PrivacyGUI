import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IndeterminateProgressBar extends ConsumerStatefulWidget {
  final String? semanticLabel;

  const IndeterminateProgressBar({this.semanticLabel, Key? key})
      : super(key: key);

  @override
  ConsumerState<IndeterminateProgressBar> createState() =>
      _IndeterminateProgressBarState();
}

class _IndeterminateProgressBarState
    extends ConsumerState<IndeterminateProgressBar>
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
        semanticsLabel: widget.semanticLabel,
      ),
    );
  }
}
