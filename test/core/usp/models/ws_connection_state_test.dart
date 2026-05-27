import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/models/ws_connection_state.dart';

void main() {
  group('WsConnectionState', () {
    test('enum has expected values', () {
      expect(WsConnectionState.values, hasLength(3));
      expect(WsConnectionState.values, contains(WsConnectionState.connecting));
      expect(WsConnectionState.values, contains(WsConnectionState.open));
      expect(WsConnectionState.values, contains(WsConnectionState.closed));
    });
  });

  group('parseWsConnectionState', () {
    test('parses "open" correctly', () {
      expect(parseWsConnectionState('open'), WsConnectionState.open);
      expect(parseWsConnectionState('Open'), WsConnectionState.open);
      expect(parseWsConnectionState('OPEN'), WsConnectionState.open);
    });

    test('parses "closed" correctly', () {
      expect(parseWsConnectionState('closed'), WsConnectionState.closed);
      expect(parseWsConnectionState('Closed'), WsConnectionState.closed);
      expect(parseWsConnectionState('CLOSED'), WsConnectionState.closed);
    });

    test('parses "connecting" correctly', () {
      expect(
          parseWsConnectionState('connecting'), WsConnectionState.connecting);
      expect(
          parseWsConnectionState('Connecting'), WsConnectionState.connecting);
      expect(
          parseWsConnectionState('CONNECTING'), WsConnectionState.connecting);
    });

    test('defaults to closed for unknown states', () {
      expect(parseWsConnectionState('unknown'), WsConnectionState.closed);
      expect(parseWsConnectionState(''), WsConnectionState.closed);
      expect(parseWsConnectionState('error'), WsConnectionState.closed);
      expect(parseWsConnectionState('disconnected'), WsConnectionState.closed);
    });
  });
}
