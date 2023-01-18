import 'package:flutter/material.dart';

class CountdownTimerProgressBar extends StatefulWidget {
  const CountdownTimerProgressBar({
    Key? key,
    required this.duration,
  }) : super(key: key);

  final int duration;

  @override
  State<CountdownTimerProgressBar> createState() =>
      _CountdownTimerProgressBarState();
}

class _CountdownTimerProgressBarState extends State<CountdownTimerProgressBar>
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
          ),
        ),
        AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Text(
                remainingTimeText,
                style: Theme.of(context).textTheme.headline1?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
              );
            })
      ],
    );
  }
}
