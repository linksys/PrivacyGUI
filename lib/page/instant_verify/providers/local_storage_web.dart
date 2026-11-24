import 'dart:html' as html;

String? getStoredValue(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void setStoredValue(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}
