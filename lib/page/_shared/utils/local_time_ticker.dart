import 'dart:async';

import 'package:flutter/widgets.dart';

mixin LocalTimeTicker<T extends StatefulWidget> on State<T> {
  Timer? _tickTimer;
  DateTime? _currentTime;

  DateTime? get currentTime => _currentTime;

  void syncTime(DateTime? parsedTime, {DateTime? fetchedAt}) {
    _tickTimer?.cancel();
    if (parsedTime == null) {
      _currentTime = null;
      return;
    }
    final elapsed = fetchedAt != null
        ? DateTime.now().difference(fetchedAt)
        : Duration.zero;
    _currentTime = parsedTime.add(elapsed);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = _currentTime!.add(const Duration(seconds: 1));
      });
    });
  }

  void disposeTicker() {
    _tickTimer?.cancel();
  }
}
