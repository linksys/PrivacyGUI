import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'ai_session_service_factory.dart'
    if (dart.library.html) 'ai_session_service_factory_web.dart';

abstract interface class AiSessionService {
  Future<bool> bootstrap(String adminPassword);
  Future<void> logout();
  void close();
}

class HttpAiSessionService implements AiSessionService {
  HttpAiSessionService({
    required http.Client client,
    required Uri baseUri,
    void Function()? onLogout,
  })  : _onLogout = onLogout,
        _client = client,
        _endpoint = baseUri.resolve('/cgi-bin/ai-session.cgi');

  final http.Client _client;
  final Uri _endpoint;
  final void Function()? _onLogout;

  Future<http.Response> _post(Map<String, String> body) => _client.post(
        _endpoint,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-store',
        },
        body: jsonEncode(body),
      );

  @override
  Future<bool> bootstrap(String adminPassword) async {
    final response = await _post({
      'action': 'login',
      'admin_password': adminPassword,
    });
    return response.statusCode == 200;
  }

  @override
  Future<void> logout() async {
    _onLogout?.call();
    await _post(const {'action': 'logout'});
  }

  @override
  void close() => _client.close();
}

final aiSessionServiceProvider = Provider<AiSessionService>((ref) {
  final service = createAiSessionService();
  ref.onDispose(service.close);
  return service;
});
