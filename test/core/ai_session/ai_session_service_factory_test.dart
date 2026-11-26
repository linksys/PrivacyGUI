// Off the web, Router AI has no session: the router-hosted page it signs in
// to exists only in the web build (ai_session_service_factory_web.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service_factory.dart';

void main() {
  test('off the web, the session service signs nothing in', () async {
    final service = createAiSessionService();

    expect(service, isA<DisabledAiSessionService>());
    expect(await service.bootstrap('admin-password'), isFalse);
  });
}
