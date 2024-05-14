import 'dart:async';
import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/logger.dart';

class IdleChecker extends StatefulWidget {
  final Duration idleTime;
  final Widget child;
  final Function? onIdle;

  const IdleChecker({
    super.key,
    required this.idleTime,
    required this.child,
    this.onIdle,
  });

  @override
  _IdleCheckerState createState() => _IdleCheckerState();
}

class _IdleCheckerState extends State<IdleChecker> {
  Timer? _timer;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _debounce?.cancel();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(widget.idleTime, () {
      widget.onIdle?.call();
    });
  }

  void handleUserInteraction() {
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (_debounce?.isActive ?? false) _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          handleUserInteraction();
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          handleUserInteraction();
        },
        onPanDown: (details) {
          handleUserInteraction();
        },
        child: widget.child,
      ),
    );
  }
}
