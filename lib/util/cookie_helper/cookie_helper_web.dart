import 'dart:html';

void setCookie(String cookie) {
  document.cookie = cookie;
}

String? getCookie(String key) {
  final cookie = document.cookie ?? '';
  if (cookie.isEmpty) {
    return null;
  }
  final entity = cookie.split("; ").map((item) {
    final split = item.split("=");
    return MapEntry(split[0], split[1]);
  });
  final cookieMap = Map.fromEntries(entity);
  return cookieMap[key];
}
