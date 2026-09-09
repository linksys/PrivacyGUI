import 'dart:async';
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
    required http.Client Function() clientFactory,
    required Uri baseUri,
    void Function()? onLogout,
    Duration requestTimeout = const Duration(seconds: 5),
  })  : _onLogout = onLogout,
        _clientFactory = clientFactory,
        _requestTimeout = requestTimeout,
        _endpoint = baseUri.resolve('/cgi-bin/ai-session.cgi');

  final http.Client Function() _clientFactory;
  final Duration _requestTimeout;
  final Uri _endpoint;
  final void Function()? _onLogout;
  final _pending = <http.Client, Completer<http.Response>>{};
  bool _closed = false;

  Future<http.Response> _post(Map<String, String> body) async {
    if (_closed) throw StateError('AI session service is closed');
    // Each operation owns its transport so cancellation cannot close a newer
    // login/logout request. Closing BrowserClient aborts an in-flight fetch.
    final client = _clientFactory();
    final cancelled = Completer<http.Response>();
    _pending[client] = cancelled;
    try {
      return await Future.any([
        client.post(
          _endpoint,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cache-Control': 'no-store',
          },
          body: jsonEncode(body),
        ),
        cancelled.future,
      ]).timeout(_requestTimeout);
    } finally {
      if (_pending.remove(client) != null) client.close();
    }
  }

  void _cancelPending() {
    final pending = Map.of(_pending);
    _pending.clear();
    for (final entry in pending.entries) {
      entry.value.completeError(StateError('AI session request superseded'));
      entry.key.close();
    }
  }

  @override
  Future<bool> bootstrap(String adminPassword) async {
    _cancelPending();
    final response = await _post({
      'action': 'login',
      'admin_password': adminPassword,
    });
    return response.statusCode == 200;
  }

  @override
  Future<void> logout() async {
    // Cancel pending bootstrap before revoking the current cookie; its late
    // response must not establish a new session after local logout.
    _cancelPending();
    _onLogout?.call();
    await _post(const {'action': 'logout'});
  }

  @override
  void close() {
    _closed = true;
    _cancelPending();
  }
}

final aiSessionServiceProvider = Provider<AiSessionService>((ref) {
  final service = createAiSessionService();
  ref.onDispose(service.close);
  return service;
});
