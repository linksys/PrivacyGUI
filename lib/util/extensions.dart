import 'dart:convert';

extension JsonUtil on String {
  bool isJsonFormat() {
    try {
      jsonDecode(this);
      return true;
    } catch (_) {
      return false;
    }
  }
}