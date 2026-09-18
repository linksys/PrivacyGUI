// #1577 / epic #1575 — telling "the device is offline" from "the connection dropped".
//
// THE DECISION GUARDED. Two situations that need **opposite** responses arrive through
// the same failed SSE connect. Guardian refuses a stream against an offline device
// with a 400, before it publishes anything, and keeps refusing until the device comes
// back — so the answer is "wait". Anything else is the path between this browser and
// the proxy — so the answer is "try again". #205 Item 8 asks the UI to tell them
// apart; before this the banner could not, because the status was interpolated into a
// string error.
//
// Also guarded here: **the heartbeat watchdog is written and switched off.** Guardian's
// spec says the RA stream heartbeats every 20 s and `HeartbeatConfig.remoteWithHeartbeat`
// is that config — but a spec is not a deployment, and if that environment does not
// send heartbeats a 35-second watchdog declares the stream dead every 35 seconds and
// pushes the app into recovery. So the value exists, is asserted, and is not wired up
// until #1575's verification item 1 is answered.
//
// HOW IT COULD SILENTLY REVERT.
//
//   * The typed error going back to a string. Everything still compiles, the cause
//     silently reads `transportFailure` for every failure, and the banner tells an
//     agent to retry against a router that is not there.
//   * A successful connect not clearing the cause — a stale 400 then outlives the
//     outage and the banner accuses an online router of being offline.
//   * `HeartbeatConfig.remote` being switched to the 35-second value "because the spec
//     says so". That is a deployment claim, and the test below names what has to
//     happen first.
//
// WHY THIS TEST TYPE. Unit tests over `SseConnectionManager` with a mocked bridge, one
// `StreamController` per case: the manager is what reads the error, and the state it
// derives is what the banner renders.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';

import '../mocks.dart';

void main() {
  late MockUspBridgeClient bridge;
  late StreamController<SseEvent> stream;
  late SseConnectionManager manager;

  setUp(() {
    bridge = MockUspBridgeClient();
    stream = StreamController<SseEvent>();
    when(() => bridge.notifications()).thenAnswer((_) => stream.stream);
    when(() => bridge.abortSse()).thenReturn(null);
    manager = SseConnectionManager(
      bridge,
      heartbeatConfig: HeartbeatConfig.remote,
      // A long backoff, so a case that records a cause is not immediately followed
      // by a reconnect attempt that overwrites it.
      initialBackoff: const Duration(seconds: 30),
    );
  });

  tearDown(() {
    manager.dispose();
    // Not awaited, deliberately: `close()` on a controller that was never listened
    // to completes only once someone listens and the stream is done, so awaiting it
    // in a synchronous case — `starts as none` never calls `connect()` — hangs until
    // the test times out. Every other suite in this directory closes it the same way.
    if (!stream.isClosed) stream.close();
  });

  group('the disconnect cause', () {
    test('starts as none', () {
      expect(manager.lastDisconnectCause, SseDisconnectCause.none);
    });

    test('a 400 is the device being offline', () async {
      // Guardian's answer for a device it cannot reach, returned before it publishes
      // anything. The one status that means "waiting is the only option".
      await manager.connect();
      stream.addError(SseStreamException(400, 'Bad Request'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(manager.lastDisconnectCause, SseDisconnectCause.deviceOffline);
    });

    test('a 502 is a transport failure', () async {
      await manager.connect();
      stream.addError(SseStreamException(502, 'Bad Gateway'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(manager.lastDisconnectCause, SseDisconnectCause.transportFailure);
    });

    test('an untyped error is a transport failure', () async {
      // The pre-#1577 shape, and what a network error still looks like: no status to
      // read, so the honest answer is the one that does not claim to know.
      await manager.connect();
      stream.addError('SSE connection failed: something');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(manager.lastDisconnectCause, SseDisconnectCause.transportFailure);
    });

    test('traffic clears it', () async {
      // Otherwise a 400 from an earlier outage outlives it and the banner accuses a
      // router that is answering of being offline.
      await manager.connect();
      stream.addError(SseStreamException(400, 'Bad Request'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(manager.lastDisconnectCause, SseDisconnectCause.deviceOffline);

      stream.add(SseEvent(event: 'heartbeat', data: ''));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(manager.lastDisconnectCause, SseDisconnectCause.none);
    });

    test('a clean close does not overwrite a recorded 400', () async {
      // Guardian closes every proxied stream at ~10 minutes, so `_onDone` is the
      // routine path. Clearing the cause there would throw away the one signal the
      // banner has, on the most common event in a support session.
      await manager.connect();
      stream.addError(SseStreamException(400, 'Bad Request'));
      await Future.delayed(const Duration(milliseconds: 50));

      await stream.close();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(manager.lastDisconnectCause, SseDisconnectCause.deviceOffline);
    });
  });

  group('the heartbeat watchdog is written and switched off', () {
    test('remote is the off one, and that is what is in force', () {
      // The live value. Flipping it is a one-word change — name
      // `remoteWithHeartbeat` in `HeartbeatConfig.remote`'s place — and this
      // assertion is what makes the flip deliberate rather than incidental.
      expect(HeartbeatConfig.remote.enabled, isFalse,
          reason: 'blocked on #1575 verification item 1: does the RA stream '
              'actually send heartbeats? If it does not, a 35s watchdog declares '
              'the stream dead every 35s and pushes the app into recovery — '
              'strictly worse than no watchdog.');
      expect(HeartbeatConfig.remote.timeout, Duration.zero);
    });

    test('remoteWithHeartbeat is 20s plus a 15s grace', () {
      // The same arithmetic as local's 30 + 15. Written now so that answering the
      // verification item is a config swap rather than a design decision under time
      // pressure.
      expect(HeartbeatConfig.remoteWithHeartbeat.enabled, isTrue);
      expect(HeartbeatConfig.remoteWithHeartbeat.timeout,
          const Duration(seconds: 35));
    });

    test('neither remote config runs the heartbeat auth check', () {
      // Unaffected by the flip: that check refreshes a WASM session token, and a
      // Guardian `temporaryAccessToken` cannot be refreshed.
      expect(HeartbeatConfig.remote.authCheckEnabled, isFalse);
      expect(HeartbeatConfig.remoteWithHeartbeat.authCheckEnabled, isFalse);
    });

    test('local is unchanged', () {
      expect(HeartbeatConfig.local.enabled, isTrue);
      expect(HeartbeatConfig.local.timeout, const Duration(seconds: 45));
      expect(HeartbeatConfig.local.authCheckEnabled, isTrue);
    });
  });
}
