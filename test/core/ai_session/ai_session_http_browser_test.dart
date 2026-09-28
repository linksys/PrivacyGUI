@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/browser_client.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';

// Run with tools/test_ai_session_browser.py, which provides the local HTTP
// fixture. Only synthetic credentials/cookies are used.
void main() {
  test('logout aborts a real browser login before a late cookie can arrive',
      () async {
    const origin = String.fromEnvironment('AI_SESSION_TEST_ORIGIN');
    expect(origin, isNotEmpty, reason: 'Use tools/test_ai_session_browser.py');
    final base = Uri.parse(origin);
    final control = BrowserClient()..withCredentials = true;
    final service = HttpAiSessionService(
      clientFactory: () => BrowserClient()..withCredentials = true,
      baseUri: base,
    );
    addTearDown(control.close);
    addTearDown(service.close);

    Future<Map<String, dynamic>> state() async =>
        jsonDecode((await control.get(base.resolve('/test-state'))).body);
    Future<void> waitFor(String key) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!(await state())[key]) {
        if (DateTime.now().isAfter(deadline)) {
          fail('Fixture did not reach $key');
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    // Positive control: a normal login sets the cookie and logout removes it.
    expect(await service.bootstrap('ImmediateFixture'), isTrue);
    expect((await state())['cookie_present'], isTrue);
    await service.logout();
    expect((await state())['cookie_present'], isFalse);

    final cancelled =
        expectLater(service.bootstrap('HeldFixture'), throwsStateError);
    await waitFor('held'); // Server has the request but sends no headers yet.
    await service.logout();
    await cancelled;
    await control.post(base.resolve('/release'));
    await waitFor('released');
    expect((await state())['cookie_present'], isFalse,
        reason: 'An aborted login must not restore its late HttpOnly cookie');

    expect(await service.bootstrap('ImmediateFixture'), isTrue,
        reason: 'Cancellation must not poison a later transport');
    expect((await state())['cookie_present'], isTrue);
    await service.logout();
    expect((await state())['cookie_present'], isFalse);
  });
}
