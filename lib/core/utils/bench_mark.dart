import 'package:flutter/foundation.dart';
import 'package:linksys_app/core/utils/logger.dart';

class BenchMarkLogger {
  final String name;
  late DateTime _start;
  late DateTime _end;

  BenchMarkLogger({required this.name});

  void start() {
    _start = DateTime.now();
    if (kDebugMode) {
      logger.d(
          '${describeIdentity(this)} - $name: start at <$_start>');
    }
  }

  void end() {
    _end = DateTime.now();
    if (kDebugMode) {
      logger.d(
          '${describeIdentity(this)} - $name: end at <$_end>, delta time is <${_calcuteDeltaTime()}>');
    }
  }

  int _calcuteDeltaTime() {
    return _end.millisecondsSinceEpoch - _start.millisecondsSinceEpoch;
  }
}
