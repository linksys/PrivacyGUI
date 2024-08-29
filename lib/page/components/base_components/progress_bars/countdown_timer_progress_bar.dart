import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CountdownTimerProgressBar extends ConsumerStatefulWidget {
  const CountdownTimerProgressBar({
    Key? key,
    required this.duration,
    this.semanticLabel,
  }) : super(key: key);

  final int duration;
  final String? semanticLabel;

  @override
  ConsumerState<CountdownTimerProgressBar> createState() =>
      _CountdownTimerProgressBarState();
}

class _CountdownTimerProgressBarState
    extends ConsumerState<CountdownTimerProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  double progress = 1.0;
  String get remainingTimeText {
    Duration count = _controller.duration! * _controller.value;
    return '${(count.inMinutes % 60).toString().padLeft(2, '0')}:${(count.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    );

    _controller.addListener(() {
      setState(() {
        progress = _controller.value;
      });
    });

    _controller.reverse(from: 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            value: progress,
            strokeWidth: 8,
            semanticsLabel: widget.semanticLabel,
          ),
        ),
        AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Text(
                remainingTimeText,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
              );
            })
      ],
    );
  }
}
