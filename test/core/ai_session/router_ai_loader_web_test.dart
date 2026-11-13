@TestOn('browser')
library;

import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';
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

  // On the web the real factory returns the HTTP service, so this is the only
  // place the provider's own build-flag gate is observable.
  test('a default build gets the disabled AI session service on the web', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(aiSessionServiceProvider),
        isA<DisabledAiSessionService>());
    expect(loadRouterAiBundle(), isFalse);
    expect(_aiScripts(), isEmpty);
  }, skip: BuildConfig.enableRouterAi ? 'default-build check' : false);

  test('an existing query or fragment variant counts as already loaded', () {
    html.document.head!
        .append(html.ScriptElement()..src = '/ai/linksys-ai.js?v=2#retry');
    expect(injectRouterAiBundle(routerAiBundlePath), isFalse);
    expect(_aiScripts(), hasLength(1));
  });

  // A stand-in for the real widget bundle: like linksys-ai.js it wraps
  // window.removeSplashFromWeb as its "GUI ready" signal and listens for
  // linksys-ai-session-ended.
  group('widget ready hook', () {
    late Object guiSplashRemover;

    setUp(() {
      resetRouterAiLoaderForTest();
      guiSplashRemover = js_util.allowInterop(() {});
      js_util.setProperty(html.window, 'removeSplashFromWeb', guiSplashRemover);
      js_util.setProperty(html.window, '__aiReady', 0);
      js_util.setProperty(html.window, '__aiEnded', 0);
    });

    String fakeWidgetUrl() => html.Url.createObjectUrlFromBlob(html.Blob([
          '(function(){var orig=window.removeSplashFromWeb;'
              'window.removeSplashFromWeb=function(){if(orig)orig();window.__aiReady++;};'
              'window.addEventListener("linksys-ai-session-ended",function(){window.__aiEnded++;});'
              '})();'
        ], 'text/javascript'));

    Future<void> loaded(String src) async {
      final script = html.document
          .querySelectorAll('script[src]')
          .whereType<html.ScriptElement>()
          .lastWhere((s) => s.src == src);
      await script.onLoad.first;
      await Future<void>.delayed(Duration.zero);
    }

    int counter(String name) => js_util.getProperty<int>(html.window, name);

    test('after login the widget is armed once and redirects never re-arm it',
        () async {
      final src = fakeWidgetUrl();
      expect(injectRouterAiBundle(src), isTrue);
      await loaded(src);

      expect(counter('__aiReady'), 1);
      expect(
          identical(
              js_util.getProperty<Object?>(html.window, 'removeSplashFromWeb'),
              guiSplashRemover),
          isTrue,
          reason: 'the GUI gets its own splash remover back');
      js_util.callMethod<void>(html.window, 'removeSplashFromWeb', const []);
      expect(counter('__aiReady'), 1, reason: 'a route redirect must not re-arm');
    });

    test('a logout while the bundle downloads never arms the widget', () async {
      final src = fakeWidgetUrl();
      expect(injectRouterAiBundle(src), isTrue);
      disarmInjectedRouterAiBundle(); // logout before the bundle has run
      await loaded(src);

      expect(counter('__aiReady'), 0);
      expect(counter('__aiEnded'), 1,
          reason: 'the missed session-ended event is replayed');
    });

    test('a login after that logout arms the already-loaded widget', () async {
      final src = fakeWidgetUrl();
      injectRouterAiBundle(src);
      disarmInjectedRouterAiBundle();
      await loaded(src);
      expect(counter('__aiReady'), 0);

      expect(injectRouterAiBundle(src), isFalse);
      expect(counter('__aiReady'), 1);
    });
  });
}
