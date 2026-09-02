import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/pwa/pwa_install_service.dart';
import 'package:privacy_gui/route/constants.dart';

const List<String> idleCheckWhiteList = [RouteNamed.addNodes];

class IdleChecker extends ConsumerStatefulWidget {
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
  ConsumerState<IdleChecker> createState() => _IdleCheckerState();
}

class _IdleCheckerState extends ConsumerState<IdleChecker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Key events never reach the pointer listeners in build(), so observe them
    // at the binding level instead: that catches keystrokes no matter which
    // widget currently holds focus.
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _resetTimer();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();

    // In PWA Standalone mode (installed app), disable idle cleaner
    final pwaService = ref.read(pwaInstallServiceProvider.notifier);
    if (pwaService.isStandalone) {
      return;
    }

    _timer = Timer(widget.idleTime, () {
      widget.onIdle?.call();
    });
  }

  void handleUserInteraction() {
    _resetTimer();
  }

  /// Observes key events only, never consumes them - hence the constant
  /// `false`, which leaves the event free to travel on to whatever has focus.
  bool _handleKeyEvent(KeyEvent event) {
    handleUserInteraction();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Wheel and trackpad scrolling arrive as pointer signals, which are neither
    // hover nor down events, so the GestureDetector below never sees them.
    return Listener(
      // Translucent, not opaque: see pointer signals without absorbing hits.
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (_) => handleUserInteraction(),
      child: MouseRegion(
        // Every hover event resets the countdown directly. The 500ms debounce
        // this replaces could starve indefinitely: it rescheduled itself on
        // each event, so a mouse that never paused never reset anything.
        onHover: (_) => handleUserInteraction(),
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
      ),
    );
  }
}
