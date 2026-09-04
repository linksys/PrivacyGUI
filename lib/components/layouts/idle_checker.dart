import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/pwa/pwa_install_service.dart';
import 'package:privacy_gui/route/constants.dart';

const List<String> idleCheckWhiteList = [RouteNamed.addNodes];

/// Watches for user activity and calls [onIdle] once [idleTime] passes without
/// any.
///
/// "Activity" is deliberately broad, because every gap in it logs someone out
/// mid-task. Four sources feed it, and they are four rather than one because no
/// single Flutter hook sees them all:
///
/// * **Keys** — observed on the `HardwareKeyboard` binding, so focus does not
///   matter. Key *repeats* are ignored (see [_handleKeyEvent]).
/// * **Pointer down** — taps and the start of any drag.
/// * **Pointer signals** — wheel and trackpad scrolling, which are neither
///   hover nor down events.
/// * **Pan-zoom** — how embedders with native trackpad gestures report a scroll
///   instead; not a pointer signal, so it needs its own hook.
/// * **Hover** — any mouse movement.
///
/// The countdown runs regardless of whether the caller will act on it: [onIdle]
/// is where suppression rules belong, so that they all live in one place and
/// stay reachable. The one exception this widget owns is PWA standalone mode
/// (see [_handleIdle]).
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
    _timer = Timer(widget.idleTime, _handleIdle);
  }

  void _handleUserInteraction() {
    _resetTimer();
  }

  /// Suppresses the *action*, not the countdown.
  ///
  /// In PWA standalone mode (an installed app) there is no idle logout. Checking
  /// that here rather than in [_resetTimer] matters for three reasons:
  /// `isStandalone` is a live `matchMedia` query, so asking once per expiry
  /// costs nothing where asking per keystroke would not; the answer is read at
  /// the moment it is acted on rather than cached; and the caller's own
  /// suppression rules in [IdleChecker.onIdle] stay reachable instead of
  /// becoming dead code for installed users.
  void _handleIdle() {
    if (ref.read(pwaInstallServiceProvider.notifier).isStandalone) {
      return;
    }
    widget.onIdle?.call();
  }

  /// Observes key events only, never consumes them - hence the constant
  /// `false`, which leaves the event free to travel on to whatever has focus.
  bool _handleKeyEvent(KeyEvent event) {
    // A held-down key repeats for as long as it is held, so counting repeats
    // would let a paperweight on the keyboard hold a session open forever. The
    // initial press already counted.
    if (event is KeyRepeatEvent) {
      return false;
    }
    _handleUserInteraction();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Translucent, not opaque: see pointer signals without absorbing hits.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleUserInteraction(),
      onPointerSignal: (_) => _handleUserInteraction(),
      onPointerPanZoomUpdate: (_) => _handleUserInteraction(),
      child: MouseRegion(
        onHover: (_) => _handleUserInteraction(),
        child: widget.child,
      ),
    );
  }
}
