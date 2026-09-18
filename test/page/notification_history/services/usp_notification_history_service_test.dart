// #1580 / epic #1575 — the service that reads Guardian's notification store.
//
// THE DECISION GUARDED. That the parser matches the *spec*, not #205's issue
// body, on the one point where the two disagree and the disagreement is silent.
// The envelope is **camelCase** (`deviceUuid`, `lastBoot`, `lastUspActivity`,
// `msgId`, `originTs`, `notificationType`, `commandKey`) while `body` is
// **snake_case** (`value_change.param_path`). #205 spells the envelope
// snake_case; a parser written from the issue returns three nulls, raises
// nothing, and renders a page of em dashes that looks like a device which has
// never spoken.
//
// HOW IT COULD SILENTLY REVERT. Every failure mode here is a null, not a throw:
//
//   1. A key respelled — `last_boot` for `lastBoot` — reads as "no data".
//   2. `originTs` read as seconds rather than milliseconds: the row renders, with
//      a date in 1970. Nothing in the type system objects.
//   3. `notificationType: 'Unknown'` treated as a placeholder and filtered out.
//      It is a real stored value; the row must survive.
//   4. A `404` on the per-entry read mapped to a generic failure, which the page
//      would render as "something went wrong" for the ordinary case of an entry
//      that has aged out.
//
// WHY THIS TEST TYPE. Plain unit tests against a mocked `UspBridgeClient`. There
// is no environment to point at — the whole epic is written contract-first
// against `guardians-ra-api.yml` — so the fixtures below *are* the contract, and
// each one is shaped from the spec rather than from a captured response.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';
import 'package:privacy_gui/page/notification_history/services/usp_notification_history_service.dart';

class _MockBridge extends Mock implements UspBridgeClient {}

void main() {
  late _MockBridge bridge;
  late UspNotificationHistoryService service;

  setUp(() {
    bridge = _MockBridge();
    service = UspNotificationHistoryService(bridge);
  });

  // ═════════════════════════════════════════════════════════════════════════
  // /usp/state
  // ═════════════════════════════════════════════════════════════════════════
  group('session state', () {
    test('reads the camelCase envelope and epoch milliseconds', () async {
      when(() => bridge.uspState()).thenAnswer((_) async => {
            'deviceUuid': 'uuid-1',
            'lastBoot': 1757000000000,
            'lastUspActivity': 1757000060000,
          });

      final state = await service.fetchState();

      expect(state.deviceUuid, 'uuid-1');
      expect(state.lastBoot,
          DateTime.fromMillisecondsSinceEpoch(1757000000000).toLocal());
      expect(state.lastUspActivity,
          DateTime.fromMillisecondsSinceEpoch(1757000060000).toLocal());
    });

    test('both timestamps null is a normal answer, not an error', () async {
      when(() => bridge.uspState()).thenAnswer((_) async => {
            'deviceUuid': 'uuid-1',
            'lastBoot': null,
            'lastUspActivity': null,
          });

      final state = await service.fetchState();

      expect(state.deviceUuid, 'uuid-1');
      expect(state.lastBoot, isNull);
      expect(state.lastUspActivity, isNull);
    });

    test('a snake_case envelope yields nulls — the trap, pinned', () async {
      // Not a behaviour we want; a *demonstration* that #205's spelling produces
      // silence. If a future contract change makes snake_case correct, this test
      // is the one that has to be rewritten deliberately rather than a page of
      // em dashes being noticed in QA.
      when(() => bridge.uspState()).thenAnswer((_) async => {
            'device_uuid': 'uuid-1',
            'last_boot': 1757000000000,
            'last_usp_activity': 1757000060000,
          });

      final state = await service.fetchState();

      expect(state.lastBoot, isNull);
      expect(state.lastUspActivity, isNull);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // /usp/notifications/history
  // ═════════════════════════════════════════════════════════════════════════
  group('history list', () {
    test('parses entries, newest first as served', () async {
      when(() => bridge.notificationsHistory()).thenAnswer((_) async => {
            'entries': [
              {
                'msgId': 'msg-2',
                'originTs': 1757000060000,
                'notificationType': 'OperationComplete',
                'commandKey': 'key-abc',
              },
              {
                'msgId': 'msg-1',
                'originTs': 1757000000000,
                'notificationType': 'ValueChange',
                'commandKey': null,
              },
            ],
            'count': 2,
            'status': 'ok',
          });

      final entries = await service.fetchHistory();

      expect(entries, hasLength(2));
      expect(entries.first.msgId, 'msg-2');
      expect(entries.first.commandKey, 'key-abc');
      expect(entries.first.originTs,
          DateTime.fromMillisecondsSinceEpoch(1757000060000).toLocal());
      // Null on most rows, and that is the common case rather than a defect.
      expect(entries.last.commandKey, isNull);
    });

    test('an empty history is an empty list, not an error', () async {
      when(() => bridge.notificationsHistory())
          .thenAnswer((_) async => {'entries': [], 'count': 0, 'status': 'ok'});

      expect(await service.fetchHistory(), isEmpty);
    });

    test('a missing entries key is an empty list', () async {
      when(() => bridge.notificationsHistory())
          .thenAnswer((_) async => {'count': 0});

      expect(await service.fetchHistory(), isEmpty);
    });

    test('an Unknown notificationType row survives', () async {
      // `Unknown` is a real stored value — what the cloud records for a notify
      // with no recognisable variant. Dropping the row loses the only evidence
      // that anything arrived.
      when(() => bridge.notificationsHistory()).thenAnswer((_) async => {
            'entries': [
              {
                'msgId': 'msg-9',
                'originTs': 1757000000000,
                'notificationType': 'Unknown',
              },
            ],
          });

      final entries = await service.fetchHistory();

      expect(entries, hasLength(1));
      expect(entries.single.notificationType, 'Unknown');
    });

    test('a row with no type at all still renders as Unknown', () async {
      when(() => bridge.notificationsHistory()).thenAnswer((_) async => {
            'entries': [
              {'msgId': 'msg-9', 'originTs': 1757000000000},
            ],
          });

      expect((await service.fetchHistory()).single.notificationType, 'Unknown');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // /usp/notifications/{msgId}
  // ═════════════════════════════════════════════════════════════════════════
  group('one entry with its body', () {
    Map<String, dynamic> envelope(Map<String, dynamic> body) => {
          'msgId': 'msg-1',
          'originTs': 1757000000000,
          'notificationType': 'ValueChange',
          'body': body,
        };

    test('a value_change body is read from snake_case keys', () async {
      when(() => bridge.notification('msg-1'))
          .thenAnswer((_) async => envelope({
                'value_change': {
                  'param_path': 'Device.WiFi.SSID.1.SSID',
                  'param_value': 'Linksys-Guest',
                },
              }));

      final detail = await service.fetchDetail('msg-1');

      final body = detail.body as ValueChangeBodyUIModel;
      expect(body.paramPath, 'Device.WiFi.SSID.1.SSID');
      expect(body.paramValue, 'Linksys-Guest');
    });

    test('an oper_complete body with output args is a success', () async {
      when(() => bridge.notification('msg-1'))
          .thenAnswer((_) async => envelope({
                'oper_complete': {
                  'command_name': 'Device.IP.Diagnostics.IPPing()',
                  'command_key': 'key-abc',
                  'output_args': {'Status': 'Complete', 'SuccessCount': '5'},
                },
              }));

      final body = (await service.fetchDetail('msg-1')).body
          as OperationCompleteBodyUIModel;

      expect(body.commandName, 'Device.IP.Diagnostics.IPPing()');
      expect(body.commandKey, 'key-abc');
      expect(body.outputArgs['SuccessCount'], '5');
      expect(body.refused, isFalse);
      expect(body.errorCode, isNull);
    });

    test('an oper_complete body with cmd_failure is a refusal', () async {
      when(() => bridge.notification('msg-1'))
          .thenAnswer((_) async => envelope({
                'oper_complete': {
                  'command_name': 'Device.IP.Diagnostics.IPPing()',
                  'command_key': 'key-abc',
                  'cmd_failure': {'err_code': '7004', 'err_msg': 'refused'},
                },
              }));

      final body = (await service.fetchDetail('msg-1')).body
          as OperationCompleteBodyUIModel;

      expect(body.refused, isTrue);
      expect(body.errorCode, '7004');
      expect(body.errorMessage, 'refused');
    });

    test('a cmd_failure with no code is still a refusal', () async {
      // The same misparse #1579 fixed on the live path, arriving a second time
      // because this is an independent parse of the same payload.
      when(() => bridge.notification('msg-1'))
          .thenAnswer((_) async => envelope({
                'oper_complete': {
                  'command_name': 'X()',
                  'command_key': 'k',
                  'cmd_failure': {'err_msg': 'not permitted'},
                },
              }));

      final body = (await service.fetchDetail('msg-1')).body
          as OperationCompleteBodyUIModel;

      expect(body.refused, isTrue);
      expect(body.errorCode, isNull);
      expect(body.errorMessage, 'not permitted');
    });

    test('an oper_complete with neither member is a success', () async {
      when(() => bridge.notification('msg-1'))
          .thenAnswer((_) async => envelope({
                'oper_complete': {'command_name': 'X()', 'command_key': 'k'},
              }));

      final body = (await service.fetchDetail('msg-1')).body
          as OperationCompleteBodyUIModel;

      expect(body.refused, isFalse);
      expect(body.outputArgs, isEmpty);
    });

    test('an event body is read', () async {
      when(() => bridge.notification('msg-1'))
          .thenAnswer((_) async => envelope({
                'event': {
                  'event_name': 'Device.Boot!',
                  'params': {'CommandKey': 'k'},
                },
              }));

      final body =
          (await service.fetchDetail('msg-1')).body as EventBodyUIModel;

      expect(body.eventName, 'Device.Boot!');
      expect(body.params['CommandKey'], 'k');
    });

    test('the other three members fall back to pretty-printed JSON', () async {
      when(() => bridge.notification('msg-1'))
          .thenAnswer((_) async => envelope({
                'obj_creation': {'obj_path': 'Device.WiFi.SSID.3.'},
              }));

      final body = (await service.fetchDetail('msg-1')).body as RawBodyUIModel;

      expect(body.pretty, contains('obj_creation'));
      expect(body.pretty, contains('Device.WiFi.SSID.3.'));
      expect(body.isEmpty, isFalse);
    });

    test('no body at all is an empty raw body, not a crash', () async {
      when(() => bridge.notification('msg-1')).thenAnswer((_) async => {
            'msgId': 'msg-1',
            'originTs': 1757000000000,
            'notificationType': 'Unknown',
          });

      final detail = await service.fetchDetail('msg-1');

      expect((detail.body as RawBodyUIModel).isEmpty, isTrue);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Errors → ServiceError (constitution Article XIII)
  // ═════════════════════════════════════════════════════════════════════════
  group('errors are mapped in the service, per Article XIII', () {
    test('a 404 on one entry is ResourceNotFoundError', () async {
      // The spec makes 404 cover "does not exist" and "is not yours" and says
      // not to tell them apart, so one error type is the whole answer. The page
      // reports "no longer available" from it — a generic failure here would
      // make an entry that aged out look like a broken session.
      when(() => bridge.notification('gone'))
          .thenThrow(BridgeReadException(404, 'notification'));

      expect(
        () => service.fetchDetail('gone'),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });

    test('any other status is UnexpectedError', () async {
      when(() => bridge.notificationsHistory())
          .thenThrow(BridgeReadException(500, 'notificationsHistory'));

      expect(service.fetchHistory, throwsA(isA<UnexpectedError>()));
    });

    test('a dead session is SessionTokenExpiredError', () async {
      when(() => bridge.uspState())
          .thenThrow(SessionExpiredException('Remote session expired'));

      expect(service.fetchState, throwsA(isA<SessionTokenExpiredError>()));
    });

    test('a transport with no RemoteReads is ServiceNotInitializedError',
        () async {
      // What a local build gets if it reaches the page by hand-typed URL and the
      // page's own null check is ever removed: a StateError from the client,
      // which must not escape the service as a raw framework error.
      when(() => bridge.notificationsHistory())
          .thenThrow(StateError('needs RemoteReads'));

      expect(
        service.fetchHistory,
        throwsA(isA<ServiceNotInitializedError>()),
      );
    });
  });
}
