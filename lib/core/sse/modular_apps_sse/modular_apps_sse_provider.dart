// create a notifier provider for SSE connection
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/sse/models/sse_packet.dart';
import 'package:privacy_gui/core/sse/modular_apps_sse/modular_apps_sse_state.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/core/jnap/providers/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'package:privacy_gui/core/jnap/providers/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/ip_getter/web_get_local_ip.dart';

final sseConnectionProvider =
    NotifierProvider<SSEConnectionNotifier, SSEConnectionState>(
        () => SSEConnectionNotifier());

class SSEConnectionNotifier extends Notifier<SSEConnectionState> {
  http.Client? _httpClient;
  StreamSubscription<List<int>>? _subscription;

  // Manual buffering for partial lines
  List<int> _buffer = [];
  // Reconnection logic (simplified)
  Timer? _reconnectTimer;
  int _reconnectDelayMs = 1000; // Start with 1 second

  @override
  SSEConnectionState build() {
    return SSEConnectionState();
  }

  Future<void> disconnect() async {
    state = state.copyWith(isConnected: false);
    _httpClient?.close();
    _subscription?.cancel();
    _reconnectTimer?.cancel();
  }

  Future<void> connect() async {
    _httpClient = http.Client();
    final sseUrl = 'https://${getLocalIp(ref)}/cgi-bin/sse_push.cgi';
    final localPwd = ref.read(authProvider).value?.localPassword ??
        await const FlutterSecureStorage().read(key: pLocalPassword) ??
        '';
    logger.d('[SSE]: Connection URL: $sseUrl');
    logger.d('[SSE]: Connection Local Password: $localPwd');
    try {
      final request = http.Request('GET', Uri.parse(sseUrl));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Connection'] = 'keep-alive';
      request.headers['Authorization'] =
          'Basic ${Utils.stringBase64Encode('admin:$localPwd')}';
      if (state.lastEventId?.isNotEmpty ?? false) {
        request.headers['Last-Event-ID'] = state.lastEventId!;
      }

      final response = await _httpClient!.send(request);

      if (response.statusCode == 200) {
        logger.d('[SSE]: HTTP Stream connected.');
        // state = state.copyWith(isConnected: true);
        _reconnectDelayMs = 1000; // Reset delay on successful connection

        _subscription = response.stream.listen(
          (List<int> chunk) {
            // Ensure buffer is always a growable list
            _buffer = List<int>.from(_buffer);
            _buffer.addAll(chunk);
            _processBuffer(); // Process the buffer to find events
          },
          onError: (dynamic error) {
            logger.e('[SSE]: Stream Error: $error');
            _scheduleReconnect();
          },
          onDone: () {
            logger.d('[SSE]: Stream disconnected.');
            _scheduleReconnect();
          },
        );
      } else {
        logger.e('[SSE]: Failed to connect HTTP Stream: ${response.statusCode}');
        _scheduleReconnect();
      }
    } catch (e) {
      logger.e('[SSE]: HTTP Stream Connection Failed: $e');
      _scheduleReconnect();
    }
  }

  void _processBuffer() {
    String currentData = utf8.decode(_buffer);
    int eventEndIndex;

    while ((eventEndIndex = currentData.indexOf('\n\n')) != -1 ||
        (eventEndIndex = currentData.indexOf('\r\n\r\n')) != -1) {
      String eventBlock = currentData.substring(0, eventEndIndex);

      String id = '';
      String data = '';
      String eventType = '';
      int retry = 0;
      int timestamp = 0;
      String message = '';

      List<String> lines = eventBlock.split(RegExp(r'\r?\n'));
      for (String line in lines) {
        if (line.startsWith('id:')) {
          id = line.substring(3).trim();
        } else if (line.startsWith('data:')) {
          data += line.substring(5).trim();
        } else if (line.startsWith('event:')) {
          eventType = line.substring(6).trim();
        } else if (line.startsWith('retry:')) {
          retry = int.tryParse(line.substring(6).trim()) ?? 0;
        } else if (line.startsWith('timestamp:')) {
          timestamp = int.tryParse(line.substring(10).trim()) ?? 0;
        } else if (line.startsWith('message:')) {
          message = line.substring(8).trim();
        }
        // Handle other fields like "field: value" if necessary
      }
      final packet = SSEPacket(
        id: id,
        data: data,
        eventType: eventType,
        retry: retry,
        timestamp: timestamp,
        message: message,
      );
      logger.d('[SSE]: Receive Packet: $packet');
      // set connected when receive initial event
      if (eventType == 'initial') {
        state = state.copyWith(isConnected: true);
      }
      // Process the parsed event
      if (eventType.isNotEmpty && message.isNotEmpty) {
        // keep last 20 messages
        state = state.copyWith(
          packets: state.packets.length > 20
              ? [...state.packets.sublist(state.packets.length - 20), packet]
              : [...state.packets, packet],
          lastEventId: id, // Update last received ID in state
        );
      }

      // Consume the processed part of the buffer
      _buffer = utf8.encode(currentData.substring(
          eventEndIndex + (currentData.contains('\r\n\r\n') ? 4 : 2)));
      currentData = utf8.decode(_buffer);
    }
  }

  void _scheduleReconnect() {
    _subscription?.cancel(); // Cancel any ongoing subscription
    _reconnectTimer?.cancel(); // Cancel previous timer if any

    _reconnectTimer = Timer(Duration(milliseconds: _reconnectDelayMs), () {
      logger.d(
          '[SSE]: Attempting to reconnect in ${_reconnectDelayMs / 1000} seconds...');
      _reconnectDelayMs = (_reconnectDelayMs * 2)
          .clamp(1000, 30000)
          .toInt(); // Exponential backoff, max 30s
      connect();
    });
  }
}
