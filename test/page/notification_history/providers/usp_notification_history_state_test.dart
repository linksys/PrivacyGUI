// #1580 — `NotificationHistoryState`, on its own.
//
// Constitution Article I §1.7: a State class used by a Provider gets an independent
// test file, in the same `providers/` directory as the Provider's. This one exists
// because every derived getter on it was previously exercised only *through* the
// notifier, where a wrong answer is attributable to either layer.
//
// THE DECISION GUARDED. That the whole retention window lives in `entries` and every
// view of it is derived. The endpoint is deliberately unpaged — Guardian serves the
// lot and #1580 forbids paging it over the wire — so `filteredEntries`,
// `visibleEntries`, `hasMore` and `availableTypes` are the page's entire vocabulary
// for narrowing, and none of them may reach for a read.
//
// HOW IT COULD SILENTLY REVERT. `visibleEntries` slicing before filtering (a page of
// the wrong list), `filteredEntries` trusting the served order instead of sorting on
// `originTs` (the list quietly reverses when the server changes), or `copyWith`
// treating a null `typeFilter` as "unchanged" so the filter can be set and never
// cleared — which is what `clearTypeFilter` exists for and what a plain `??` would
// break.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';
import 'package:privacy_gui/page/notification_history/providers/usp_notification_history_state.dart';

import '../../../mocks/test_data/scenes/notification_history_scene_data.dart';

void main() {
  group('NotificationHistoryState - defaults', () {
    test('an empty state shows nothing and offers no filter', () {
      const state = NotificationHistoryState();

      expect(state.entries, isEmpty);
      expect(state.visibleEntries, isEmpty);
      expect(state.filteredEntries, isEmpty);
      expect(state.availableTypes, isEmpty);
      expect(state.hasMore, isFalse);
      expect(state.typeFilter, isNull);
      expect(state.visibleCount, NotificationHistoryState.pageSize);
    });

    test('pageSize is a client-side number', () {
      // 25 is this page's own choice, not the server's: the endpoint returns the
      // whole window in one response. Pinned so a change is deliberate.
      expect(NotificationHistoryState.pageSize, 25);
    });
  });

  group('NotificationHistoryState - ordering', () {
    test('newest first, whatever order the rows arrived in', () {
      // The endpoint promises newest-first and the client sorts anyway: the promise
      // is a server behaviour this page cannot see broken.
      final state = NotificationHistoryState(entries: [
        notificationEntry('old', 'ValueChange', ms: 1000),
        notificationEntry('new', 'ValueChange', ms: 3000),
        notificationEntry('mid', 'ValueChange', ms: 2000),
      ]);

      expect(state.filteredEntries.map((e) => e.msgId), ['new', 'mid', 'old']);
    });
  });

  group('NotificationHistoryState - filtering', () {
    final entries = [
      notificationEntry('m1', 'ValueChange', ms: 3000),
      notificationEntry('m2', 'OperationComplete', ms: 2000),
      notificationEntry('m3', 'Unknown', ms: 1000),
    ];

    test('a null filter shows every row', () {
      expect(NotificationHistoryState(entries: entries).filteredEntries,
          hasLength(3));
    });

    test('a type filter narrows to that type', () {
      final state =
          NotificationHistoryState(entries: entries, typeFilter: 'Unknown');

      expect(state.filteredEntries.map((e) => e.msgId), ['m3']);
    });

    test('a filter matching nothing yields an empty list, not every row', () {
      final state = NotificationHistoryState(
          entries: entries, typeFilter: 'ObjectCreation');

      expect(state.filteredEntries, isEmpty);
    });

    test('availableTypes comes from the data, sorted', () {
      // Built from what is present rather than from a fixed list of USP's variants:
      // `Unknown` is a real stored value and the cloud may store a seventh before
      // this app knows about it. An option with no rows behind it is worse than a
      // missing one.
      expect(NotificationHistoryState(entries: entries).availableTypes,
          ['OperationComplete', 'Unknown', 'ValueChange']);
    });

    test('availableTypes de-duplicates', () {
      final state = NotificationHistoryState(entries: [
        notificationEntry('a', 'ValueChange'),
        notificationEntry('b', 'ValueChange'),
      ]);

      expect(state.availableTypes, ['ValueChange']);
    });
  });

  group('NotificationHistoryState - paging', () {
    List<NotificationHistoryEntryUIModel> rows(int n) => [
          for (var i = 0; i < n; i++)
            notificationEntry('m$i', 'ValueChange', ms: 1000 + i),
        ];

    test('a window inside one page shows all of it and offers no more', () {
      final state = NotificationHistoryState(entries: rows(5));

      expect(state.visibleEntries, hasLength(5));
      expect(state.hasMore, isFalse);
    });

    test('exactly one page is not "more"', () {
      // The off-by-one: `>` not `>=`, or the button appears with nothing behind it.
      final state = NotificationHistoryState(
          entries: rows(NotificationHistoryState.pageSize));

      expect(
          state.visibleEntries, hasLength(NotificationHistoryState.pageSize));
      expect(state.hasMore, isFalse);
    });

    test('one past a page offers more', () {
      final state = NotificationHistoryState(
          entries: rows(NotificationHistoryState.pageSize + 1));

      expect(state.hasMore, isTrue);
    });

    test('the slice comes off the FILTERED list, not the raw one', () {
      // The defect this test exists for: slicing first would show a page of the
      // wrong list, and with a filter that matches only late rows it would show an
      // empty page while `hasMore` said otherwise.
      final state = NotificationHistoryState(
        entries: [
          ...rows(30),
          notificationEntry('target', 'Unknown', ms: 1),
        ],
        typeFilter: 'Unknown',
        visibleCount: 2,
      );

      expect(state.visibleEntries.map((e) => e.msgId), ['target']);
      expect(state.hasMore, isFalse);
    });
  });

  group('NotificationHistoryState - copyWith', () {
    test('an omitted field is kept', () {
      final state = NotificationHistoryState(
        entries: [notificationEntry('m1', 'ValueChange')],
        typeFilter: 'ValueChange',
        visibleCount: 50,
      );

      final copy = state.copyWith();

      expect(copy.entries, state.entries);
      expect(copy.typeFilter, 'ValueChange');
      expect(copy.visibleCount, 50);
    });

    test('clearTypeFilter is the only way back to "all"', () {
      // `typeFilter: null` cannot mean "clear" — a nullable field with a `??`
      // default reads that as "unchanged", so without the explicit flag the filter
      // could be set and never unset.
      final state = NotificationHistoryState(typeFilter: 'Unknown');

      expect(state.copyWith(typeFilter: null).typeFilter, 'Unknown');
      expect(state.copyWith(clearTypeFilter: true).typeFilter, isNull);
    });

    test('clearTypeFilter wins over a value passed alongside it', () {
      final state = NotificationHistoryState(typeFilter: 'Unknown');

      expect(
        state
            .copyWith(typeFilter: 'ValueChange', clearTypeFilter: true)
            .typeFilter,
        isNull,
        reason:
            'the flag is the caller being explicit; a value passed with it is '
            'the caller contradicting themselves, and the explicit half should '
            'win rather than the order of two named arguments deciding',
      );
    });
  });

  group('NotificationHistoryState - equality', () {
    test('equal states are equal, and every field is in props', () {
      final a = NotificationHistoryState(
        sessionState: emptyNotificationHistoryState.sessionState,
        entries: [notificationEntry('m1', 'ValueChange')],
        typeFilter: 'ValueChange',
        visibleCount: 30,
      );

      expect(a.copyWith(), a);
      expect(a.copyWith(visibleCount: 31), isNot(a));
      expect(a.copyWith(clearTypeFilter: true), isNot(a));
      expect(a.copyWith(entries: const []), isNot(a));
    });
  });
}
