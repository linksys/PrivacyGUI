import 'dart:html' as html;

/// Appends one deferred `<script src="...">` for the Router AI bundle to the
/// document head. Any existing reference to the same file name - including
/// query-string or fragment variants - counts as already loaded, so a page can
/// never end up with two loaders. The widget initialises itself whether it
/// arrives before or after the document finishes parsing.
bool injectRouterAiBundle(String src) {
  final fileName = Uri.parse(src).pathSegments.last;
  final alreadyLoaded = html.document
      .querySelectorAll('script[src]')
      .whereType<html.ScriptElement>()
      .any((script) {
    final segments = Uri.tryParse(script.src)?.pathSegments ?? const [];
    return segments.isNotEmpty && segments.last == fileName;
  });
  if (alreadyLoaded) return false;

  final script = html.ScriptElement()
    ..src = src
    ..defer = true;
  html.document.head!.append(script);
  return true;
}
