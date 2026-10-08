import 'package:flutter/services.dart';
import 'copy_text_stub.dart' if (dart.library.html) 'copy_text_web.dart'
    as browser;

/// Keep the synchronous browser copy path inside the user's copy gesture.
/// Unlike the async clipboard API, it also works on local router origins.
Future<bool> copyDiagnosticText(String text) async {
  if (browser.copyText(text)) return true;
  try {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  } catch (_) {
    return false;
  }
}
