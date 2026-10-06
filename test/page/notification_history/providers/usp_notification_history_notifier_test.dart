// #1580 / epic #1575 — the notifier behind the notification history page.
//
// THE DECISION GUARDED. That **nothing on this page is on a timer**. The spec
// prohibits polling these reads outright: Guardian already polls DynamoDB on the
// client's behalf every ~10 s, so a second polling layer multiplies the read
// volume the design budgets for. Acceptance 5 of #1580 asks for this to be
// asserted against a mock's call count rather than eyeballed, because a polling
// loop is invisible in a screenshot and cheap to add by accident — an
// `AsyncNotifier` that gets a `Timer.periodic` in its `build()` looks like
// working code.
//
// HOW IT COULD SILENTLY REVERT. A refresh wired to a stream or a timer instead of
// to the pull gesture; an `invalidate` on a provider the page watches, turning
// every rebuild into two HTTP reads; or a `ref.listen` on the SSE manager added
// later to "keep the list live", which would poll once per notification.
//
// WHY THIS TEST TYPE. Provider-level with a mocked service: the claim is about
// call *counts* after time passes. The one test that passes time builds the
// provider inside `fakeAsync`, because a fake clock only fires timers created in
// its own zone.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';
import 'package:privacy_gui/page/notification_history/providers/usp_notification_history_notifier.dart';
import 'package:privacy_gui/page/notification_history/services/usp_notification_history_service.dart';

import '../../../mocks/test_data/notification_history_test_data.dart';

class MockUspNotificationHistoryService extends Mock
    implements UspNotificationHistoryService {}

SessionUspStateUIModel _state({DateTime? boot}) => SessionUspStateUIModel(
      lastBoot: boot,
      lastUspActivity: null,
    );

void main() {
  late MockUspNotificationHistoryService service;

  ProviderContainer containerWith(List<NotificationHistoryEntryUIModel> rows) {
    when(() => service.fetchState()).thenAnswer((_) async => _state());
    when(() => service.fetchHistory()).thenAnswer((_) async => rows);
    final container = ProviderContainer(overrides: [
      uspNotificationHistoryServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => service = MockUspNotificationHistoryService());

  group('UspNotificationHistoryNotifier - session open', () {
    test('reads state and history exactly once each', () async {
      final container = containerWith(
          [NotificationHistoryTestData.entry('m1', 'ValueChange')]);

      final state = await container.read(uspNotificationHistoryProvider.future);
      expect(state.sessionState, isNotNull);
      expect(state.entries, hasLength(1));
      verify(() => service.fetchState()).called(1);
      verify(() => service.fetchHistory()).called(1);
    });

    test('an empty history is data, not an error', () async {
      final container = containerWith([]);

      final state = await container.read(uspNotificationHistoryProvider.future);

      expect(state.entries, isEmpty);
      expect(state.sessionState, isNotNull);
    });

    test('nothing further is read as an hour passes', () {
      // Acceptance 5. **The provider is built inside `fakeAsync`**, and that is the
      // whole correction. A fake clock fires only the timers created in its own
      // zone; the previous version built and read the provider in the real zone
      // and then elapsed an hour of fake time, which fires nothing — measured: a
      // `Timer.periodic(10s)` added to `build()` survived it. Built in here, the
      // same mutant fires 360 times in the hour and fails the count.
      fakeAsync((async) {
        final container = containerWith(
            [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
        container.listen(uspNotificationHistoryProvider, (_, __) {});
        async.flushMicrotasks();
        expect(container.read(uspNotificationHistoryProvider).hasValue, isTrue);

        async.elapse(const Duration(hours: 1));

        verify(() => service.fetchState()).called(1);
        verify(() => service.fetchHistory()).called(1);
        verifyNoMoreInteractions(service);
      });
    });

    test('a failed state read still surfaces as an error', () async {
      when(() => service.fetchState())
          .thenThrow(const UnexpectedError(detail: 'boom'));
      when(() => service.fetchHistory()).thenAnswer((_) async => []);
      final container = ProviderContainer(overrides: [
        uspNotificationHistoryServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(uspNotificationHistoryProvider.future),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });

  group('UspNotificationHistoryNotifier - refresh', () {
    test('refresh re-reads both, and only when asked', () async {
      final container = containerWith(
          [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
      await container.read(uspNotificationHistoryProvider.future);

      await container.read(uspNotificationHistoryProvider.notifier).refresh();

      verify(() => service.fetchState()).called(1);
      verify(() => service.fetchHistory()).called(2);
    });

    test('refresh re-reads the bodies of rows on screen', () async {
      // A row reads its body as it is built and keeps that read while it is on
      // screen, so without this a body that failed once would stay failed until
      // the row scrolled away. Pull-to-refresh is the page's one retry gesture.
      final container = containerWith(
          [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
      when(() => service.fetchDetail('m1')).thenAnswer(
        (_) async => NotificationDetailUIModel(
          entry: NotificationHistoryTestData.entry('m1', 'ValueChange'),
          body: const RawBodyUIModel(''),
        ),
      );
      await container.read(uspNotificationHistoryProvider.future);
      // Held the way an on-screen row holds it.
      final row =
          container.listen(notificationDetailProvider('m1'), (_, __) {});
      addTearDown(row.close);
      await container.read(notificationDetailProvider('m1').future);

      await container.read(uspNotificationHistoryProvider.notifier).refresh();
      await container.read(notificationDetailProvider('m1').future);

      verify(() => service.fetchDetail('m1')).called(2);
    });

    test('a filter chosen while the refresh is in flight survives it',
        () async {
      // `refresh()` used to take the state before its `await` and write it back
      // after, so a filter or a "Show more" the viewer applied during the fetch
      // was silently undone when the fetch returned.
      final container = containerWith([
        NotificationHistoryTestData.entry('m1', 'ValueChange'),
        NotificationHistoryTestData.entry('m2', 'OperationComplete'),
      ]);
      await container.read(uspNotificationHistoryProvider.future);
      final notifier = container.read(uspNotificationHistoryProvider.notifier);
      final fetch = Completer<List<NotificationHistoryEntryUIModel>>();
      when(() => service.fetchHistory()).thenAnswer((_) => fetch.future);

      final refreshing = notifier.refresh();
      notifier.setTypeFilter('OperationComplete');
      fetch.complete([
        NotificationHistoryTestData.entry('m1', 'ValueChange'),
        NotificationHistoryTestData.entry('m2', 'OperationComplete'),
        NotificationHistoryTestData.entry('m3', 'OperationComplete'),
      ]);
      await refreshing;

      final state = container.read(uspNotificationHistoryProvider).requireValue;
      expect(state.typeFilter, 'OperationComplete');
      expect(state.entries.map((e) => e.msgId), ['m1', 'm2', 'm3'],
          reason: 'the new rows land too — only the viewer\'s choice is kept');
    });

    test('a failed refresh keeps the loaded list, and says so to its caller',
        () async {
      // A pull that fails is not a reason to lose what the viewer was reading.
      // The failure goes to the caller, which reports it on the transient
      // channel; the state stays the list, so the page never swaps it for its
      // full-page error, whose retry is a reload that drops the filter.
      final container = containerWith(
          [NotificationHistoryTestData.entry('m1', 'ValueChange')]);
      await container.read(uspNotificationHistoryProvider.future);
      final notifier = container.read(uspNotificationHistoryProvider.notifier);
      notifier.setTypeFilter('ValueChange');
      when(() => service.fetchHistory())
          .thenThrow(const UnexpectedError(detail: 'boom'));

      await expectLater(notifier.refresh(), throwsA(isA<UnexpectedError>()));

      final after = container.read(uspNotificationHistoryProvider);
      expect(after.hasError, isFalse);
      expect(after.requireValue.entries.map((e) => e.msgId), ['m1']);
      expect(after.requireValue.typeFilter, 'ValueChange');

      when(() => service.fetchHistory()).thenAnswer((_) async => [
            NotificationHistoryTestData.entry('m1', 'ValueChange'),
            NotificationHistoryTestData.entry('m2', 'ValueChange'),
          ]);
      await notifier.refresh();

      expect(
          container
              .read(uspNotificationHistoryProvider)
              .requireValue
              .entries
              .map((e) => e.msgId),
          ['m1', 'm2'],
          reason: 'the retry ran: it is the page\'s one recovery gesture');
    });
  });

  group('UspNotificationHistoryNotifier - filtering and paging', () {
    test('the type filter narrows the visible rows', () async {
      final container = containerWith([
        NotificationHistoryTestData.entry('m1', 'ValueChange'),
        NotificationHistoryTestData.entry('m2', 'OperationComplete'),
        NotificationHistoryTestData.entry('m3', 'Unknown'),
      ]);
      await container.read(uspNotificationHistoryProvider.future);
      final notifier = container.read(uspNotificationHistoryProvider.notifier);

      notifier.setTypeFilter('OperationComplete');

      final state = container.read(uspNotificationHistoryProvider).requireValue;
      expect(state.visibleEntries.map((e) => e.msgId), ['m2']);
      // No second read: the whole window is already in hand.
      verify(() => service.fetchHistory()).called(1);
    });

    test('an Unknown row is filterable like any other type', () async {
      final container = containerWith([
        NotificationHistoryTestData.entry('m1', 'ValueChange'),
        NotificationHistoryTestData.entry('m3', 'Unknown'),
      ]);
      await container.read(uspNotificationHistoryProvider.future);
      final notifier = container.read(uspNotificationHistoryProvider.notifier);

      notifier.setTypeFilter('Unknown');

      expect(
        container
            .read(uspNotificationHistoryProvider)
            .requireValue
            .visibleEntries
            .map((e) => e.msgId),
        ['m3'],
      );
    });

    test('availableTypes lists what the window actually contains', () async {
      final container = containerWith([
        NotificationHistoryTestData.entry('m1', 'ValueChange'),
        NotificationHistoryTestData.entry('m2', 'OperationComplete'),
        NotificationHistoryTestData.entry('m3', 'ValueChange'),
      ]);

      final state = await container.read(uspNotificationHistoryProvider.future);

      expect(state.availableTypes, ['OperationComplete', 'ValueChange']);
    });

    test('the list shows one page and grows on request', () async {
      final rows = [
        for (var i = 0; i < 60; i++)
          NotificationHistoryTestData.entry('m$i', 'ValueChange',
              ms: 1757000000000 + i),
      ];
      final container = containerWith(rows);
      await container.read(uspNotificationHistoryProvider.future);
      final notifier = container.read(uspNotificationHistoryProvider.notifier);

      expect(
        container
            .read(uspNotificationHistoryProvider)
            .requireValue
            .visibleEntries,
        hasLength(NotificationHistoryState.pageSize),
      );
      expect(
        container.read(uspNotificationHistoryProvider).requireValue.hasMore,
        isTrue,
      );

      notifier.showMore();

      expect(
        container
            .read(uspNotificationHistoryProvider)
            .requireValue
            .visibleEntries,
        hasLength(NotificationHistoryState.pageSize * 2),
      );
      verify(() => service.fetchHistory()).called(1);
    });

    test('changing the filter resets paging to the first page', () async {
      final rows = [
        for (var i = 0; i < 60; i++)
          NotificationHistoryTestData.entry('m$i', 'ValueChange',
              ms: 1757000000000 + i),
      ];
      final container = containerWith(rows);
      await container.read(uspNotificationHistoryProvider.future);
      final notifier = container.read(uspNotificationHistoryProvider.notifier);
      notifier.showMore();

      notifier.setTypeFilter(null);

      expect(
        container
            .read(uspNotificationHistoryProvider)
            .requireValue
            .visibleEntries,
        hasLength(NotificationHistoryState.pageSize),
        reason: 'a filter change that kept the old offset would show a page '
            'from the middle of the new result',
      );
    });

    test('rows are ordered newest first regardless of served order', () async {
      // The endpoint promises newest-first, and the client sorts anyway: the
      // promise is a server behaviour, and the page reads `originTs` for its own
      // ordering rather than trusting a list order it cannot see broken.
      final container = containerWith([
        NotificationHistoryTestData.entry('old', 'ValueChange',
            ms: 1757000000000),
        NotificationHistoryTestData.entry('new', 'ValueChange',
            ms: 1757000060000),
      ]);

      final state = await container.read(uspNotificationHistoryProvider.future);

      expect(state.visibleEntries.map((e) => e.msgId), ['new', 'old']);
    });
  });

  group('notificationDetailProvider - one row per read', () {
    test('the detail provider reads exactly the row asked for', () async {
      final container = containerWith([]);
      when(() => service.fetchDetail('m1')).thenAnswer(
        (_) async => NotificationDetailUIModel(
          entry: NotificationHistoryTestData.entry('m1', 'ValueChange'),
          body: const ValueChangeBodyUIModel(
            paramPath: 'Device.WiFi.SSID.1.SSID',
            paramValue: 'x',
          ),
        ),
      );

      final detail =
          await container.read(notificationDetailProvider('m1').future);

      expect(detail.entry.msgId, 'm1');
      verify(() => service.fetchDetail('m1')).called(1);
    });

    test('a 404 reaches the caller as ResourceNotFoundError', () async {
      final container = containerWith([]);
      when(() => service.fetchDetail('gone'))
          .thenThrow(const ResourceNotFoundError(code: 404));

      await expectLater(
        container.read(notificationDetailProvider('gone').future),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });
  });

  test('a build with no service reports a service that is not there', () async {
    // What a local build reaches by hand-typed URL: no Guardian session, so no
    // bridge, so no service. The page renders its own not-available state from
    // `remoteReads == null` before this, so this path is the backstop.
    final container = ProviderContainer(overrides: [
      uspNotificationHistoryServiceProvider.overrideWithValue(null),
    ]);
    addTearDown(container.dispose);

    await expectLater(
      container.read(uspNotificationHistoryProvider.future),
      throwsA(isA<ServiceNotInitializedError>()),
    );
  });
}
