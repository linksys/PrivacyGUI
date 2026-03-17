import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'usp_service.dart';

/// HTTP/SSE client for usp-bridge endpoints that don't use protobuf.
///
/// Uses the JWT session token from [UspService] for authentication.
/// Handles: Health, SSE Notifications, Subscription, Turbo Channel.
///
/// All REST endpoints are wrapped with 401 retry logic that delegates
/// re-authentication to [UspService.reauth].
class UspBridgeClient {
  final UspService _usp;

  UspBridgeClient(this._usp);

  String get _baseUrl => _usp.baseUrl;

  String get _token {
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
      };

  // ══════════════════════════════════════════════════════════════════════════
  // 401 Auth Retry (REST path)
  // ══════════════════════════════════════════════════════════════════════════

  /// Wraps a REST request with 401 retry. On 401, delegates to
  /// [UspService.reauth] (shared Completer lock) then retries once.
  Future<T> _withAuthRetry<T>(
    Future<http.Response> Function() request,
    T Function(http.Response) parser,
  ) async {
    var response = await request();
    if (response.statusCode == 401) {
      debugPrint('[UspBridgeClient] 401 detected, triggering reauth...');
      await _usp.reauth();
      response = await request();
    }
    return parser(response);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Health
  // ══════════════════════════════════════════════════════════════════════════

  /// Calls GET /api/v1/health.
  Future<Map<String, dynamic>> health() async {
    return _withAuthRetry(
      () =>
          http.get(Uri.parse('$_baseUrl/api/v1/health'), headers: _authHeaders),
      (r) => jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SSE Notifications
  // ══════════════════════════════════════════════════════════════════════════

  /// Opens an SSE connection to GET /api/v1/notifications.
  ///
  /// Browser-native EventSource does not support custom headers, so we use
  /// the Fetch API with ReadableStream to parse the text/event-stream.
  Stream<SseEvent> notifications() {
    final controller = StreamController<SseEvent>();
    web.AbortController? abortController;

    controller.onListen = () {
      abortController = web.AbortController();
      _startSseStream(controller, abortController!);
    };

    controller.onCancel = () {
      abortController?.abort();
    };

    return controller.stream;
  }

  /// Quick diagnostic: hit the SSE endpoint with a regular http.get
  /// to check if it's reachable (will buffer and timeout for SSE streams).
  Future<Map<String, String>> notificationsProbe() async {
    final response = await http
        .get(
      Uri.parse('$_baseUrl/api/v1/notifications'),
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
      final url = '$_baseUrl/api/v1/notifications';
      debug('Fetching $url ...');

      final token = _token;
      debug('Token: ${token.substring(0, 20)}...(${token.length} chars)');

      final headers = web.Headers();
      headers.append('Authorization', 'Bearer $token');
      headers.append('Accept', 'text/event-stream');

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
          if (authRetryCount >= 1) {
            debug('401 retry limit reached (max 1 retry)');
            controller.addError('SSE 401 after reauth retry');
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
            controller.addError('SSE 401 reauth failed: $e');
            await controller.close();
          }
          return;
        }
        controller.addError(
            'SSE connection failed: ${response.status} ${response.statusText}');
        await controller.close();
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
        Uri.parse('$_baseUrl/api/v1/subscription'),
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
        Uri.parse('$_baseUrl/api/v1/subscription'),
        headers: _authHeaders,
        body: jsonEncode({
          'action': 'unregister',
          'subscription_id': subscriptionId,
        }),
      ),
      (r) => jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Turbo Channel
  // ══════════════════════════════════════════════════════════════════════════

  /// Starts a turbo channel session.
  Future<Map<String, dynamic>> turboStart() async {
    return _turboPost('start');
  }

  /// Sends a heartbeat to keep the turbo channel alive.
  Future<Map<String, dynamic>> turboHeartbeat() async {
    return _turboPost('heartbeat');
  }

  /// Gets the current turbo channel status.
  Future<Map<String, dynamic>> turboStatus() async {
    return _withAuthRetry(
      () => http.get(Uri.parse('$_baseUrl/api/v1/turbo/status'),
          headers: _authHeaders),
      (r) => jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  /// Releases the turbo channel.
  Future<Map<String, dynamic>> turboRelease() async {
    return _turboPost('release');
  }

  Future<Map<String, dynamic>> _turboPost(String action) async {
    return _withAuthRetry(
      () => http.post(Uri.parse('$_baseUrl/api/v1/turbo/$action'),
          headers: _authHeaders),
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
