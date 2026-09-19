// Selected only on web by copy_text.dart; native builds use the stub.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool copyText(String text) {
  final previousFocus = html.document.activeElement;
  final field = html.TextAreaElement()
    ..value = text
    ..readOnly = true
    ..style.position = 'fixed'
    ..style.left = '-9999px'
    ..style.top = '0';
  try {
    html.document.body!.append(field);
    field.focus();
    field.select();
    return html.document.execCommand('copy');
  } catch (_) {
    return false;
  } finally {
    field.remove();
    previousFocus?.focus();
  }
}
