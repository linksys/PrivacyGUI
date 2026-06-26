import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'bridge_endpoints.dart';
import 'sse_operation_strategy.dart';
import 'usp_client.dart';

export 'sse_operation_strategy.dart' show AuthBehavior;

/// Exception thrown when session expires and cannot be recovered.
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException(this.message);

  @override
  String toString() => 'SessionExpiredException: $message';
}

/// Global JS property to persist SSE AbortController across hot restarts.
@JS('_sseAbort')
external JSAny? get _jsSseAbort;

@JS('_sseAbort')
external set _jsSseAbort(JSAny? value);

/// HTTP/SSE client for usp-bridge endpoints that don't use protobuf.
///
/// Uses the JWT session token from [UspClient] for authentication.
/// Handles: Health, SSE Notifications, Subscription, Turbo Channel.
///
/// All REST endpoints are wrapped with 401 retry logic that delegates
/// re-authentication to [UspClient.reauth].
class UspBridgeClient {
  final UspClient _usp;
  final BridgeEndpoints _endpoints;
  final String? _overrideToken;
  final String? _clientTypeId;
  final AuthBehavior _authBehavior;

  /// Called when auth fails and cannot be recovered (session expired).
  void Function()? onAuthFailed;

  UspBridgeClient(
    this._usp, {
    BridgeEndpoints? endpoints,
    String? authToken,
    String? clientTypeId,
    AuthBehavior authBehavior = AuthBehavior.local,
  })  : _endpoints = endpoints ?? BridgeEndpoints.local,
        _overrideToken = authToken,
        _clientTypeId = clientTypeId,
        _authBehavior = authBehavior;

  /// Active SSE AbortController — stored so [abortSse] can cancel
  /// synchronously from a `beforeunload` handler.
  web.AbortController? _sseAbortController;

  String get _baseUrl => _usp.baseUrl;

  String get _token {
    // Remote mode: use override token (temporaryAccessToken from Guardian)
    if (_overrideToken != null) return _overrideToken;

    // Local mode: use session token from WASM client
    final token = _usp.sessionToken;
    if (token == null) {
      throw StateError('Session token not available. '
          'Ensure the WASM client exports sessionToken() and login is complete.');
    }
    return token;
  }

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        if (_clientTypeId != null) 'X-Linksys-Client-Type-Id': _clientTypeId,
      };

  // ══════════════════════════════════════════════════════════════════════════
  // 401 Auth Retry (REST path)
  // ══════════════════════════════════════════════════════════════════════════

  /// Wraps a REST request with 401 handling based on [AuthBehavior].
  ///
  /// Local mode: delegates to [UspClient.reauth] then retries once.
  /// Remote mode: no retry (temporaryAccessToken cannot refresh), triggers
  /// [onAuthFailed] and throws [SessionExpiredException].
  Future<T> _withAuthRetry<T>(
    Future<http.Response> Function() request,
    T Function(http.Response) parser,
  ) async {
    var response = await request();
    if (response.statusCode == 401) {
      if (_authBehavior.shouldRetryOnFailure) {
        // Local mode: reauth + retry
        debugPrint('[UspBridgeClient] 401 detected, attempting reauth...');
        await _usp.reauth();
        response = await request();
        if (response.statusCode == 401) {
          debugPrint('[UspBridgeClient] 401 after reauth — session expired');
          onAuthFailed?.call();
          throw SessionExpiredException('Local session expired after reauth');
        }
      } else {
        // Remote mode: no retry, session is over
        debugPrint('[UspBridgeClient] 401 in Remote mode — session expired');
        onAuthFailed?.call();
        throw SessionExpiredException('Remote session expired');
      }
    }
    return parser(response);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Health
  // ══════════════════════════════════════════════════════════════════════════

  /// Calls GET health endpoint.
  Future<Map<String, dynamic>> health() async {
    return _withAuthRetry(
      () => http.get(Uri.parse('$_baseUrl${_endpoints.health}'),
          headers: _authHeaders),
      (r) => jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SSE Notifications
  // ══════════════════════════════════════════════════════════════════════════

  /// Synchronously abort the active SSE Fetch stream.
  ///
  /// Called from `beforeunload` / `pagehide` handlers where only synchronous
  /// code is guaranteed to execute. This ensures the browser's TCP socket to
  /// lighttpd is released immediately on page refresh/close.
  void abortSse() {
    _sseAbortController?.abort();
    _sseAbortController = null;
  }

  /// Abort any SSE connection left over from a previous hot restart.
  ///
  /// Hot restart recreates Dart state but does NOT trigger `beforeunload`,
  /// so the browser keeps the old Fetch SSE stream alive. We store the
  /// AbortController on `window` so the new Dart isolate can abort it.
  static void abortPreviousSession() {
    try {
      final prev = _jsSseAbort;
      if (prev != null && prev is web.AbortController) {
        prev.abort();
      }
    } catch (_) {}
  }

  void _storeSseAbortOnWindow() {
    if (_sseAbortController != null) {
      _jsSseAbort = _sseAbortController!;
    }
  }

  /// Opens an SSE connection to GET /api/v1/notifications.
  ///
  /// Browser-native EventSource does not support custom headers, so we use
  /// the Fetch API with ReadableStream to parse the text/event-stream.
  Stream<SseEvent> notifications() {
    final controller = StreamController<SseEvent>();

    controller.onListen = () {
      // Abort any leftover SSE from window (covers rapid hot-restart sequences)
      abortPreviousSession();
      _sseAbortController = web.AbortController();
      _storeSseAbortOnWindow();
      _startSseStream(controller, _sseAbortController!);
    };

    controller.onCancel = () {
      _sseAbortController?.abort();
      _sseAbortController = null;
    };

    return controller.stream;
  }

  /// Quick diagnostic: hit the SSE endpoint with a regular http.get
  /// to check if it's reachable (will buffer and timeout for SSE streams).
  Future<Map<String, String>> notificationsProbe() async {
    final response = await http
        .get(
      Uri.parse('$_baseUrl${_endpoints.notifications}'),
      headers: _authHeaders,
    )
        .timeout(const Duration(seconds: 5), onTimeout: () {
      return http.Response('(timeout after 5s - expected for SSE)', 200);
    });
    return {
      'status': response.statusCode.toString(),
      'contentType': response.headers['content-type'] ?? '(none)',
      'bodyLength': response.body.length.toString(),
      'bodyPreview': response.body.length > 500
          ? response.body.substring(0, 500)
          : response.body,
    };
  }

  Future<void> _startSseStream(
    StreamController<SseEvent> controller,
    web.AbortController abortController, {
    int authRetryCount = 0,
  }) async {
    void debug(String msg) {
      if (!controller.isClosed) {
        controller.add(SseEvent(event: '_debug', data: msg));
      }
    }

    try {
      final url = '$_baseUrl${_endpoints.notifications}';
      debug('Fetching $url ...');

      final headers = web.Headers();
      _authHeaders.forEach((k, v) => headers.append(k, v));
      headers.set('Accept', 'text/event-stream'); // override Content-Type

      final init = web.RequestInit(
        method: 'GET',
        headers: headers,
        signal: abortController.signal,
      );

      debug('Calling fetch()...');
      final response = await web.window.fetch(url.toJS, init).toDart;
      debug('Fetch returned: ${response.status} ${response.statusText} '
          'type=${response.type} headers.content-type=${response.headers.get('content-type')}');

      if (!response.ok) {
        if (response.status == 401) {
          if (_authBehavior.shouldRetryOnFailure) {
            // Local mode: attempt reauth and retry
            if (authRetryCount >= 1) {
              debug('401 retry limit reached (max 1 retry)');
              onAuthFailed?.call();
              controller.addError(SessionExpiredException(
                  'Local session expired after reauth'));
              await controller.close();
              return;
            }
            debug('401 detected, attempting reauth and reconnect...');
            try {
              await _usp.reauth();
              debug('Reauth succeeded, reconnecting SSE...');
              await _startSseStream(controller, abortController,
                  authRetryCount: authRetryCount + 1);
            } catch (e) {
              debug('Reauth failed: $e');
              onAuthFailed?.call();
              controller.addError(
                  SessionExpiredException('SSE 401 reauth failed: $e'));
              await controller.close();
            }
          } else {
            // Remote mode: no retry, session is over
            debug('401 in Remote mode — session expired, closing SSE');
            onAuthFailed?.call();
            controller
                .addError(SessionExpiredException('Remote session expired'));
            await controller.close();
          }
          return;
        }
        // Use addError only (not close) — the error listener in
        // SseConnectionManager._onError will handle cleanup and reconnect.
        // Calling both addError + close fires both _onError and _onDone,
        // which causes double _handleStreamEnd and timer multiplication.
        controller.addError(
            'SSE connection failed: ${response.status} ${response.statusText}');
        if (!controller.isClosed) {
          await controller.close();
        }
        return;
      }

      final body = response.body;
      if (body == null) {
        controller.addError('SSE response has no body');
        await controller.close();
        return;
      }

      debug('Got response body, creating reader...');
      final reader = body.getReader() as web.ReadableStreamDefaultReader;
      final decoder = web.TextDecoder();
      var buffer = '';
      var chunkCount = 0;

      debug('Entering read loop...');
      while (!controller.isClosed) {
        final result = await reader.read().toDart;
        if (result.done) {
          debug('Stream done (server closed connection)');
          break;
        }

        final jsValue = result.value;
        if (jsValue == null) {
          debug('Read returned null value, continuing...');
          continue;
        }

        chunkCount++;
        final chunk = decoder.decode(jsValue as web.AllowSharedBufferSource);
        debug(
            'Chunk #$chunkCount (${chunk.length} chars): ${chunk.length > 200 ? '${chunk.substring(0, 200)}...' : chunk}');
        buffer += chunk;

        // Parse SSE frames: double newline separates events
        while (buffer.contains('\n\n')) {
          final idx = buffer.indexOf('\n\n');
          final frame = buffer.substring(0, idx);
          buffer = buffer.substring(idx + 2);

          debug('Parsed frame: "$frame"');
          final event = _parseSseFrame(frame);
          if (event != null && !controller.isClosed) {
            controller.add(event);
          }
        }
      }

      if (!controller.isClosed) {
        await controller.close();
      }
    } catch (e, st) {
      if (!controller.isClosed) {
        // AbortError is expected when we cancel
        final isAbort = e.toString().contains('AbortError');
        if (!isAbort) {
          debug('Exception: $e');
          debug('Stack: $st');
          controller.addError(e);
        }
        await controller.close();
      }
    }
  }

  /// Parses a single SSE frame into an [SseEvent].
  SseEvent? _parseSseFrame(String frame) {
    String? event;
    final dataLines = <String>[];
    String? id;

    for (final line in frame.split('\n')) {
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trim());
      } else if (line.startsWith('id:')) {
        id = line.substring(3).trim();
      }
    }

    if (event == null && dataLines.isEmpty) return null;

    return SseEvent(
      event: event ?? 'message',
      data: dataLines.join('\n'),
      id: id,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Subscription
  // ══════════════════════════════════════════════════════════════════════════

  /// Registers a subscription for parameter change notifications.
  ///
  /// The bridge creates an OBUSPA `Device.LocalAgent.Subscription.{i}`
  /// instance automatically and routes notifications to the SSE stream.
  ///
  /// [notifType]: 1=ValueChange, 2=ObjectCreation, 3=ObjectDeletion,
  ///              4=OperationComplete, 5=Event
  Future<Map<String, dynamic>> subscribe({
    required String subscriptionId,
    required String path,
    required int notifType,
  }) async {
    const notifTypeNames = {
      1: 'ValueChange',
      2: 'ObjectCreation',
      3: 'ObjectDeletion',
      4: 'OperationComplete',
      5: 'Event',
    };
    return _withAuthRetry(
      () => http.post(
        Uri.parse('$_baseUrl${_endpoints.subscription}'),
        headers: _authHeaders,
        body: jsonEncode({
          'action': 'register',
          'subscription_id': subscriptionId,
          'NotifType': notifTypeNames[notifType] ?? 'ValueChange',
          'ReferenceList': path,
        }),
      ),
      (r) => jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  /// Unregisters an existing subscription.
  Future<Map<String, dynamic>> unsubscribe({
    required String subscriptionId,
  }) async {
    return _withAuthRetry(
      () => http.post(
        Uri.parse('$_baseUrl${_endpoints.subscription}'),
        headers: _authHeaders,
        body: jsonEncode({
          'action': 'unregister',
          'subscription_id': subscriptionId,
        }),
      ),
      (r) => jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  /// Lists all active subscriptions (Remote mode only).
  Future<List<String>> listSubscriptions() async {
    final response = await _withAuthRetry(
      () => http.get(
        Uri.parse('$_baseUrl${_endpoints.subscription}'),
        headers: _authHeaders,
      ),
      (r) => jsonDecode(r.body),
    );
    // Format: { "subscriptions": [{"subscription_id": "...", ...}, ...] }
    if (response is Map && response['subscriptions'] is List) {
      final subs = response['subscriptions'] as List;
      return subs
          .map((s) => s is Map ? s['subscription_id'] as String? : null)
          .whereType<String>()
          .toList();
    }
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Turbo Channel
  // ══════════════════════════════════════════════════════════════════════════

  /// Starts a turbo channel session.
  Future<Map<String, dynamic>> turboStart() async {
    return _turboPost('start');
  }

  /// Sends a heartbeat to keep the turbo channel alive.
  Future<Map<String, dynamic>> turboHeartbeat({String? sessionId}) async {
    return _turboPost('heartbeat', sessionId: sessionId);
  }

  /// Gets the current turbo channel status.
  Future<Map<String, dynamic>> turboStatus() async {
    return _withAuthRetry(
      () => http.get(Uri.parse('$_baseUrl${_endpoints.turboPrefix}/status'),
          headers: _authHeaders),
      (r) => jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  /// Releases the turbo channel.
  Future<Map<String, dynamic>> turboRelease({String? sessionId}) async {
    return _turboPost('release', sessionId: sessionId);
  }

  Future<Map<String, dynamic>> _turboPost(String action,
      {String? sessionId}) async {
    final body =
        sessionId != null ? jsonEncode({'session_id': sessionId}) : null;
    return _withAuthRetry(
      () => http.post(
        Uri.parse('$_baseUrl${_endpoints.turboPrefix}/$action'),
        headers: {
          ..._authHeaders,
          'Content-Type': 'application/json',
        },
        body: body,
      ),
      (r) => jsonDecode(r.body) as Map<String, dynamic>,
    );
  }
}

/// A parsed Server-Sent Event.
class SseEvent {
  final String event;
  final String data;
  final String? id;

  SseEvent({required this.event, required this.data, this.id});

  @override
  String toString() => 'SseEvent(event=$event, data=$data, id=$id)';
}
