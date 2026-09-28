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
    Duration logoutRetryBackoff = const Duration(milliseconds: 500),
  })  : _onLogout = onLogout,
        _clientFactory = clientFactory,
        _requestTimeout = requestTimeout,
        _logoutRetryBackoff = logoutRetryBackoff,
        _endpoint = baseUri.resolve('/cgi-bin/ai-session.cgi');

  static const _logoutAttempts = 3;

  final http.Client Function() _clientFactory;
  final Duration _requestTimeout;
  final Duration _logoutRetryBackoff;
  final Uri _endpoint;
  final void Function()? _onLogout;
  final _pending = <http.Client, Completer<http.Response>>{};
  // Bumped by _cancelPending so a superseded logout retry loop can tell that
  // a newer login/logout owns the session and must not revoke it.
  int _generation = 0;
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
    _generation++;
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
    final generation = _generation;
    _onLogout?.call();
    // Server-side revocation is the only thing that stops the widget's status
    // poll from resurrecting the chat after logout, so transient failures are
    // retried. A newer login/logout supersedes the loop instead of letting a
    // stale retry revoke the session it now owns.
    for (var attempt = 1; ; attempt++) {
      try {
        await _post(const {'action': 'logout'});
        return;
      } catch (_) {
        if (_generation != generation) return;
        if (_closed || attempt >= _logoutAttempts) rethrow;
      }
      await Future<void>.delayed(_logoutRetryBackoff * (1 << (attempt - 1)));
      if (_closed || _generation != generation) return;
    }
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
