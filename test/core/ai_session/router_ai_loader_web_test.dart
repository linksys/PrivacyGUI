@TestOn('browser')
library;

import 'dart:html' as html;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/ai_session/router_ai_loader.dart';
import 'package:privacy_gui/core/ai_session/router_ai_loader_web.dart';

List<html.ScriptElement> _aiScripts() => html.document
    .querySelectorAll('script[src]')
    .whereType<html.ScriptElement>()
    .where((s) => Uri.parse(s.src).pathSegments.last == 'linksys-ai.js')
    .toList();

void _removeAiScripts() {
  for (final script in _aiScripts()) {
    script.remove();
  }
}

void main() {
  setUp(_removeAiScripts);
  tearDown(_removeAiScripts);

  test('adds exactly one deferred, root-relative loader', () {
    expect(injectRouterAiBundle(routerAiBundlePath), isTrue);
    expect(injectRouterAiBundle(routerAiBundlePath), isFalse);

    final scripts = _aiScripts();
    expect(scripts, hasLength(1));
    expect(scripts.single.getAttribute('src'), '/ai/linksys-ai.js');
    expect(scripts.single.defer, isTrue);
  });

  test('an existing query or fragment variant counts as already loaded', () {
    html.document.head!
        .append(html.ScriptElement()..src = '/ai/linksys-ai.js?v=2#retry');
    expect(injectRouterAiBundle(routerAiBundlePath), isFalse);
    expect(_aiScripts(), hasLength(1));
  });
}
