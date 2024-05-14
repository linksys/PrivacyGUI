import 'dart:async';

mixin DebugObserver {
  Timer? _timer;
  int _clickCount = 0;

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
