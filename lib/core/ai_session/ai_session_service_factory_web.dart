import 'dart:html' as html;

import 'package:http/browser_client.dart';

import 'ai_session_service.dart';

AiSessionService createAiSessionService() {
  final client = BrowserClient()..withCredentials = true;
  return HttpAiSessionService(
    client: client,
    baseUri: Uri.base,
    onLogout: () => html.window.dispatchEvent(
      html.CustomEvent('linksys-ai-session-ended'),
    ),
  );
}
