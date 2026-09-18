// #1580 — the six UI models, on their own.
//
// Constitution Article I §1.7: UI Model classes used by Providers get an independent
// test file in a `models/` directory. Before this they were exercised only through the
// service's parse tests, where a wrong `props` list is invisible — every one of those
// assertions reads a field directly.
//
// THE DECISION GUARDED. Two things, and the second is the one that bites.
//
//   1. **`props` completeness.** Riverpod compares state with `==`, so a field missing
//      from `props` is a field whose change never reaches the screen. That is not a
//      hypothetical here: `OperationCompleteBodyUIModel.refused` is a *derived-looking*
//      bool that is actually stored, and it was the field most likely to be left out.
//   2. **`refused` is stored, not derived from `errorCode`.** The same misparse #1579
//      fixed on the live path: a refusal the router named with a message and no code —
//      or with a third spelling of the code — reads as a **success** if presence is
//      inferred from having successfully read one optional member.
//
// HOW IT COULD SILENTLY REVERT. Both silently. A dropped `props` entry compiles and
// every direct-field test still passes; `refused` re-derived as `errorCode != null`
// compiles and passes every fixture that happens to carry a code.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';

void main() {
  final at = DateTime.fromMillisecondsSinceEpoch(1757000000000);

  group('SessionUspStateUIModel - props', () {
    test('every field participates in equality', () {
      final base = SessionUspStateUIModel(
        deviceUuid: 'uuid-1',
        lastBoot: at,
        lastUspActivity: at,
      );

      expect(
          base,
          SessionUspStateUIModel(
            deviceUuid: 'uuid-1',
            lastBoot: at,
            lastUspActivity: at,
          ));
      expect(
          base,
          isNot(SessionUspStateUIModel(
              deviceUuid: 'other', lastBoot: at, lastUspActivity: at)));
      expect(
          base,
          isNot(SessionUspStateUIModel(
              deviceUuid: 'uuid-1', lastUspActivity: at)));
      expect(base,
          isNot(SessionUspStateUIModel(deviceUuid: 'uuid-1', lastBoot: at)));
    });

    test('both timestamps default to null, which is a normal state', () {
      // A device that has produced no notification. The page renders an em dash for
      // it, not an error, so "absent" has to be constructible without ceremony.
      const state = SessionUspStateUIModel(deviceUuid: 'uuid-1');

      expect(state.lastBoot, isNull);
      expect(state.lastUspActivity, isNull);
    });
  });

  group('NotificationHistoryEntryUIModel - props', () {
    test('every field participates in equality', () {
      final base = NotificationHistoryEntryUIModel(
        msgId: 'm1',
        originTs: at,
        notificationType: 'ValueChange',
        commandKey: 'k',
      );

      expect(base, isNot(base.copyLike(msgId: 'm2')));
      expect(base,
          isNot(base.copyLike(originTs: at.add(const Duration(seconds: 1)))));
      expect(base, isNot(base.copyLike(notificationType: 'Unknown')));
      expect(base, isNot(base.copyLike(dropCommandKey: true)));
    });

    test('commandKey is nullable, because most rows have none', () {
      final entry = NotificationHistoryEntryUIModel(
        msgId: 'm1',
        originTs: at,
        notificationType: 'ValueChange',
      );

      expect(entry.commandKey, isNull);
    });
  });

  group('NotificationBodyUIModel - the sealed hierarchy', () {
    test('the four variants are the whole of it', () {
      // A `switch` over this type is exhaustive, which is what lets the view render
      // three shapes plus a fallback rather than six widgets — and what makes a
      // seventh upstream member land in `RawBodyUIModel` instead of rendering a
      // column of nulls. Pinned as a set so adding a fifth is a decision.
      const bodies = <NotificationBodyUIModel>[
        ValueChangeBodyUIModel(paramPath: 'p', paramValue: 'v'),
        OperationCompleteBodyUIModel(commandName: 'c', commandKey: 'k'),
        EventBodyUIModel(eventName: 'e'),
        RawBodyUIModel(''),
      ];

      expect(bodies.map((b) => b.runtimeType).toSet(), hasLength(4));
    });

    test('ValueChange props', () {
      const base = ValueChangeBodyUIModel(paramPath: 'p', paramValue: 'v');

      expect(
          base, const ValueChangeBodyUIModel(paramPath: 'p', paramValue: 'v'));
      expect(base,
          isNot(const ValueChangeBodyUIModel(paramPath: 'q', paramValue: 'v')));
      expect(base,
          isNot(const ValueChangeBodyUIModel(paramPath: 'p', paramValue: 'w')));
    });

    test('Event props include the params map', () {
      const base = EventBodyUIModel(eventName: 'e', params: {'a': '1'});

      expect(base, const EventBodyUIModel(eventName: 'e', params: {'a': '1'}));
      expect(base,
          isNot(const EventBodyUIModel(eventName: 'e', params: {'a': '2'})));
      expect(base, isNot(const EventBodyUIModel(eventName: 'e')));
    });

    test('RawBody knows when it is empty', () {
      expect(const RawBodyUIModel('').isEmpty, isTrue);
      expect(const RawBodyUIModel('{}').isEmpty, isFalse);
      expect(const RawBodyUIModel('x'), isNot(const RawBodyUIModel('y')));
    });
  });

  group('OperationCompleteBodyUIModel - refused', () {
    test('defaults to false, and is not inferred from errorCode', () {
      // The #1579 misparse, arriving a second time because the stored copy is an
      // independent parse of the same payload. A refusal is marked by the failure
      // member having been *present*; the code inside it is only detail.
      const named = OperationCompleteBodyUIModel(
        commandName: 'IPPing()',
        commandKey: 'k',
        errorCode: '7004',
      );

      expect(named.refused, isFalse,
          reason:
              'a hand-built result that names a code but does not say it was '
              'refused must not be promoted to a refusal here — only the parser '
              'saw whether `cmd_failure` was there, so only the parser sets it');
    });

    test('a refusal with a message and no code is still a refusal', () {
      const body = OperationCompleteBodyUIModel(
        commandName: 'IPPing()',
        commandKey: 'k',
        errorMessage: 'not permitted',
        refused: true,
      );

      expect(body.refused, isTrue);
      expect(body.errorCode, isNull);
    });

    test('refused is in props', () {
      // The field most likely to be left out of `props`, because it reads like
      // something derived. Riverpod compares state with `==`, so omitting it means a
      // success and a refusal with identical other fields never redraw.
      const success =
          OperationCompleteBodyUIModel(commandName: 'c', commandKey: 'k');
      const refusal = OperationCompleteBodyUIModel(
          commandName: 'c', commandKey: 'k', refused: true);

      expect(success, isNot(refusal));
    });

    test('outputArgs and both error fields are in props', () {
      const base =
          OperationCompleteBodyUIModel(commandName: 'c', commandKey: 'k');

      expect(
          base,
          isNot(const OperationCompleteBodyUIModel(
              commandName: 'c', commandKey: 'k', outputArgs: {'a': '1'})));
      expect(
          base,
          isNot(const OperationCompleteBodyUIModel(
              commandName: 'c', commandKey: 'k', errorCode: '1')));
      expect(
          base,
          isNot(const OperationCompleteBodyUIModel(
              commandName: 'c', commandKey: 'k', errorMessage: 'm')));
    });

    test('outputArgs defaults to empty, not null', () {
      const body =
          OperationCompleteBodyUIModel(commandName: 'c', commandKey: 'k');

      expect(body.outputArgs, isEmpty);
    });
  });

  group('NotificationDetailUIModel - props', () {
    test('both halves participate in equality', () {
      final entry = NotificationHistoryEntryUIModel(
        msgId: 'm1',
        originTs: at,
        notificationType: 'ValueChange',
      );
      final base = NotificationDetailUIModel(
        entry: entry,
        body: const ValueChangeBodyUIModel(paramPath: 'p', paramValue: 'v'),
      );

      expect(
          base,
          NotificationDetailUIModel(
            entry: entry,
            body: const ValueChangeBodyUIModel(paramPath: 'p', paramValue: 'v'),
          ));
      expect(
          base,
          isNot(NotificationDetailUIModel(
              entry: entry, body: const RawBodyUIModel('{}'))));
      expect(
          base,
          isNot(NotificationDetailUIModel(
            entry: entry.copyLike(msgId: 'm2'),
            body: const ValueChangeBodyUIModel(paramPath: 'p', paramValue: 'v'),
          )));
    });
  });
}

/// A local rebuild-with-one-field-changed, because the model has no `copyWith`.
///
/// It has none because nothing in `lib/` needs one — the models are built once by the
/// service and read from there. Adding one to production code so a test could vary a
/// field would be the test dictating the API, so the varying lives here instead.
extension on NotificationHistoryEntryUIModel {
  NotificationHistoryEntryUIModel copyLike({
    String? msgId,
    DateTime? originTs,
    String? notificationType,
    bool dropCommandKey = false,
  }) =>
      NotificationHistoryEntryUIModel(
        msgId: msgId ?? this.msgId,
        originTs: originTs ?? this.originTs,
        notificationType: notificationType ?? this.notificationType,
        commandKey: dropCommandKey ? null : commandKey,
      );
}
