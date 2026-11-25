// The non-web loader of the Router AI widget (router_ai_loader_stub.dart),
// which router_ai_loader.dart picks on every platform but the web.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/ai_session/router_ai_loader.dart'
    show routerAiBundlePath;
import 'package:privacy_gui/core/ai_session/router_ai_loader_stub.dart';

void main() {
  test('off the web, says it added no script, and disarming returns', () {
    expect(injectRouterAiBundle(routerAiBundlePath), isFalse);
    expect(disarmInjectedRouterAiBundle, returnsNormally);
  });
}
