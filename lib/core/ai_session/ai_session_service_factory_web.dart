import 'dart:html' as html;

import 'package:http/browser_client.dart';

import 'ai_session_service.dart';

AiSessionService createAiSessionService() {
  final client = BrowserClient()..withCredentials = true;
  return HttpAiSessionService(
    client: client,
    baseUri: Uri.base,
    onLogout: () {
      // sessionStorage survives the route change back to the login screen.
      // Clear the per-tab engine conversation explicitly so teardown remains
      // complete even if navigation replaces the widget before its event
      // listener runs.
      html.window.sessionStorage.remove('aiMsdmSid');
      html.window.dispatchEvent(
        html.CustomEvent('linksys-ai-session-ended'),
      );
    },
  );
}
