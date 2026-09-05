@TestOn('browser')
library;

import 'dart:html' as html;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service_factory_web.dart';

void main() {
  test('web logout dispatches the shared session-ended event', () async {
    final events = <html.Event>[];
    void listener(html.Event event) => events.add(event);

    html.window.addEventListener('linksys-ai-session-ended', listener);
    addTearDown(
      () => html.window.removeEventListener(
        'linksys-ai-session-ended',
        listener,
      ),
    );

    await createAiSessionService().logout();

    expect(events, hasLength(1));
  });
}
