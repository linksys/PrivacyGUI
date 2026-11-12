import 'dart:html' as html;
import 'dart:js_util' as js_util;

/// Appends one deferred `<script src="...">` for the Router AI bundle to the
/// document head. Any existing reference to the same file name - including
/// query-string or fragment variants - counts as already loaded, so a page can
/// never end up with two loaders. The widget initialises itself whether it
/// arrives before or after the document finishes parsing.
///
/// The loader is added only after login, when the splash screen is long gone.
/// The widget learns that the GUI is ready (and clears the suppression a
/// logout sets) through its wrapper around `window.removeSplashFromWeb`, which
/// it installs when the bundle runs. That function is the GUI's own and is
/// idempotent, so it is called once the new bundle has loaded, or immediately
/// when the bundle is already on the page.
bool injectRouterAiBundle(String src) {
  final fileName = Uri.parse(src).pathSegments.last;
  final alreadyLoaded = html.document
      .querySelectorAll('script[src]')
      .whereType<html.ScriptElement>()
      .any((script) {
    final segments = Uri.tryParse(script.src)?.pathSegments ?? const [];
    return segments.isNotEmpty && segments.last == fileName;
  });
  if (alreadyLoaded) {
    _signalGuiReady();
    return false;
  }

  final script = html.ScriptElement()
    ..src = src
    ..defer = true;
  script.onLoad.first.then((_) => _signalGuiReady());
  html.document.head!.append(script);
  return true;
}

void _signalGuiReady() {
  try {
    if (js_util.hasProperty(html.window, 'removeSplashFromWeb')) {
      js_util.callMethod<void>(html.window, 'removeSplashFromWeb', const []);
    }
  } catch (_) {
    // The widget is optional; a missing or failing hook must never affect the
    // GUI.
  }
}
