import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/utils/logger.dart';

class BenchMarkLogger {
  final String name;
  final bool recordOnly;
  late DateTime _start;
  late DateTime _end;

  BenchMarkLogger({
    required this.name,
    this.recordOnly = false,
  });

  void start() {
    _start = DateTime.now();
    if (kDebugMode && !recordOnly) {
      logger.d('${describeIdentity(this)} - $name: start at <$_start>');
    }
  }

  ///
  /// @return milliseconds
  ///
  int end() {
    _end = DateTime.now();
    int delta = _calcuteDeltaTime();
    if (kDebugMode && !recordOnly) {
      logger.d(
          '${describeIdentity(this)} - $name: end at <$_end>, delta time is <$delta>');
    }
    return delta;
  }

  int _calcuteDeltaTime() {
    return _end.millisecondsSinceEpoch - _start.millisecondsSinceEpoch;
  }
}
