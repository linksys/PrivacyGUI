import 'package:flutter/material.dart';
import 'dart:async'; // Required for Timer

/// A widget that shows a continuously rolling digit, like a slot machine.
/// It uses a [ListWheelScrollView] to create an infinite looping effect of digits 0-9.
class ContinuousRollingDigit extends StatefulWidget {
  /// The interval at which the digit changes.
  final Duration changeInterval;

  /// The duration of the animation when rolling to the next digit.
  /// This should be less than or equal to [changeInterval].
  final Duration animationDuration;

  final double fontSize;
  final Color? fontColor;

  const ContinuousRollingDigit({
    Key? key,
    this.changeInterval = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 80),
    this.fontSize = 16,
    this.fontColor,
  })  : assert(animationDuration <= changeInterval,
            'animationDuration must be less than or equal to changeInterval'),
        super(key: key);

  @override
  State<ContinuousRollingDigit> createState() => _ContinuousRollingDigitState();
}

class _ContinuousRollingDigitState extends State<ContinuousRollingDigit> {
  late FixedExtentScrollController _scrollController;
  Timer? _timer;
  int _currentItem = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    // Start the timer to continuously scroll through digits.
    _timer = Timer.periodic(widget.changeInterval, (Timer timer) {
      if (_scrollController.hasClients) {
        _currentItem++;
        _scrollController.animateToItem(
          _currentItem,
          duration: widget.animationDuration,
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digitStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
          color: widget.fontColor,
        );

    return SizedBox(
      width: widget.fontSize * 1,
      height: widget.fontSize * 1.2,
      child: IgnorePointer(
        // Disable user interaction
        child: ListWheelScrollView.useDelegate(
          controller: _scrollController,
          itemExtent: widget.fontSize * 1.2,
          physics: const NeverScrollableScrollPhysics(),
          childDelegate: ListWheelChildLoopingListDelegate(
            children: List<Widget>.generate(10, (index) {
              return Text(
                index.toString(),
                style: digitStyle,
                textAlign: TextAlign.center,
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// A widget that displays two continuously and independently rolling digits.
class AnimatedDigitalText extends StatelessWidget {
  const AnimatedDigitalText({super.key, this.fontSize = 16, this.fontColor});

  final double fontSize;
  final Color? fontColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // First digit, rolling at its own pace.
          ContinuousRollingDigit(
            changeInterval: const Duration(milliseconds: 80),
            animationDuration: const Duration(milliseconds: 40),
            fontSize: fontSize,
            fontColor: fontColor,
          ),
          // Second digit, rolling at a different pace to appear independent.
          ContinuousRollingDigit(
            changeInterval: const Duration(milliseconds: 60),
            animationDuration: const Duration(milliseconds: 40),
            fontSize: fontSize,
            fontColor: fontColor,
          ),
        ],
      ),
    );
  }
}
