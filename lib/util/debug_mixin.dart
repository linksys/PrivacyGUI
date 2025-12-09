import 'dart:async';

/// A mixin that provides a mechanism to observe and react to a rapid sequence of events,
/// such as multiple taps, to trigger a debug mode or feature.
///
/// This mixin maintains a counter that increments with each call to [increase]. If the
/// specified number of calls is reached within a 1-second interval, it signals
/// an activation event. The counter automatically resets if the time between
/// calls exceeds the interval.
mixin DebugObserver {
  Timer? _timer;
  int _clickCount = 0;

  /// Increments the event counter and checks if the activation threshold has been met.
  ///
  /// Each call to this method increments a counter. A timer is reset with each call.
  /// If the counter reaches 6 within a 1-second window, this method returns `true`.
  /// Otherwise, it returns `false`. The counter resets to 0 if 1 second elapses
  /// between calls.
  ///
  /// Returns `true` if the click count reaches 5, indicating the debug trigger condition is met.
  /// Otherwise, returns `false`.
  bool increase() {
    if (_timer != null && (_timer?.isActive ?? false)) {
      _timer?.cancel();
    }
    _timer = Timer(const Duration(seconds: 1), () {
      _clickCount = 0;
      _timer?.cancel();
    });
    return _clickCount++ == 5;
  }
}
