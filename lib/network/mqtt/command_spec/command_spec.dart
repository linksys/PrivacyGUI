import 'dart:convert';

import 'package:uuid/uuid.dart';

abstract class CommandSpec<R> {
  static const Uuid _uuid = Uuid();
  String uuid = _uuid.v1();
  String payload();

  R response(String raw);
}

