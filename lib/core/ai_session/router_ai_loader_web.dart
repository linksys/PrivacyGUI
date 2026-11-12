import 'dart:html' as html;
import 'dart:js_util' as js_util;

const _splashHook = 'removeSplashFromWeb';

/// The widget's "GUI is ready" hook, held privately once the bundle has run.
///
/// The widget learns that the GUI is ready (and clears the suppression a
/// logout sets) by wrapping `window.removeSplashFromWeb` when it loads. The GUI
/// also calls that function on every route redirect (FlutterNativeSplash.remove
/// on web), so left in place the wrapper would re-arm the widget on the login
/// screen right after a logout and show its manual-login card there. Once the
/// bundle has run, the GUI therefore puts its own splash remover back and keeps
/// the widget's wrapper here, calling it only after an authenticated AI session.
Object? _widgetReadyHook;

/// Appends one deferred `<script src="...">` for the Router AI bundle to the
/// document head, or re-arms the widget when the bundle is already loaded. Any
/// existing reference to the same file name - including query-string or
/// fragment variants - counts as already loaded, so a page can never end up
/// with two loaders. The widget initialises itself whether it arrives before or
/// after the document finishes parsing.
///
/// Returns true only if a script element was added by this call.
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
    _signalWidgetReady();
    return false;
  }

  final splashRemover = _getGlobal(_splashHook);
  final script = html.ScriptElement()
    ..src = src
    ..defer = true;
  script.onLoad.first.then((_) {
    final installed = _getGlobal(_splashHook);
    if (installed != null && !identical(installed, splashRemover)) {
      _widgetReadyHook = installed;
      _setGlobal(_splashHook, splashRemover);
    }
    _signalWidgetReady();
  });
  html.document.head!.append(script);
  return true;
}

void _signalWidgetReady() {
  final hook = _widgetReadyHook;
  if (hook == null) return;
  try {
    js_util.callMethod<void>(hook, 'call', [html.window]);
  } catch (_) {
    // The widget is optional; a failing hook must never affect the GUI.
  }
}

Object? _getGlobal(String name) {
  try {
    return js_util.hasProperty(html.window, name)
        ? js_util.getProperty<Object?>(html.window, name)
        : null;
  } catch (_) {
    return null;
  }
}

void _setGlobal(String name, Object? value) {
  try {
    js_util.setProperty(html.window, name, value);
  } catch (_) {
    // Leave the page as it is rather than break the GUI.
  }
}
