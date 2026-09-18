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
// WHY THIS TEST TYPE. Provider-level with a mocked service and `fakeAsync`-free
// real elapsed time: the claim is about call *counts* after time passes, and
// `FakeAsync` would only prove that a timer this notifier does not have would
// have fired.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';
import 'package:privacy_gui/page/notification_history/providers/usp_notification_history_notifier.dart';
import 'package:privacy_gui/page/notification_history/services/usp_notification_history_service.dart';

import '../../../mocks/test_data/scenes/notification_history_scene_data.dart';

class MockUspNotificationHistoryService extends Mock
    implements UspNotificationHistoryService {}

SessionUspStateUIModel _state({DateTime? boot}) => SessionUspStateUIModel(
      deviceUuid: 'uuid-1',
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
      final container = containerWith([notificationEntry('m1', 'ValueChange')]);

      final state = await container.read(uspNotificationHistoryProvider.future);

      expect(state.sessionState?.deviceUuid, 'uuid-1');
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

    test('nothing further is read as an hour passes', () async {
      // Acceptance 5. **An hour of fake time**, which is the correction: an earlier
      // version elapsed 600 ms of real time on the reasoning that "pumping a fake
      // clock proves only that an absent timer did not fire". That reasoning is
      // backwards — a fake clock is exactly what fires a timer that *is* there, and
      // 600 ms is shorter than the ~10 s interval a well-meaning poll would copy from
      // the server. `fakeAsync` fires a `Timer.periodic(10s)` 360 times in this
      // window, so the mutant cannot survive.
      final container = containerWith([notificationEntry('m1', 'ValueChange')]);
      await container.read(uspNotificationHistoryProvider.future);

      fakeAsync((async) => async.elapse(const Duration(hours: 1)));

      verify(() => service.fetchState()).called(1);
      verify(() => service.fetchHistory()).called(1);
      verifyNoMoreInteractions(service);
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
      final container = containerWith([notificationEntry('m1', 'ValueChange')]);
      await container.read(uspNotificationHistoryProvider.future);

      await container.read(uspNotificationHistoryProvider.notifier).refresh();

      verify(() => service.fetchState()).called(1);
      verify(() => service.fetchHistory()).called(2);
    });
  });

  group('UspNotificationHistoryNotifier - filtering and paging', () {
    test('the type filter narrows the visible rows', () async {
      final container = containerWith([
        notificationEntry('m1', 'ValueChange'),
        notificationEntry('m2', 'OperationComplete'),
        notificationEntry('m3', 'Unknown'),
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
        notificationEntry('m1', 'ValueChange'),
        notificationEntry('m3', 'Unknown'),
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
        notificationEntry('m1', 'ValueChange'),
        notificationEntry('m2', 'OperationComplete'),
        notificationEntry('m3', 'ValueChange'),
      ]);

      final state = await container.read(uspNotificationHistoryProvider.future);

      expect(state.availableTypes, ['OperationComplete', 'ValueChange']);
    });

    test('the list shows one page and grows on request', () async {
      final rows = [
        for (var i = 0; i < 60; i++)
          notificationEntry('m$i', 'ValueChange', ms: 1757000000000 + i),
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
          notificationEntry('m$i', 'ValueChange', ms: 1757000000000 + i),
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
        notificationEntry('old', 'ValueChange', ms: 1757000000000),
        notificationEntry('new', 'ValueChange', ms: 1757000060000),
      ]);

      final state = await container.read(uspNotificationHistoryProvider.future);

      expect(state.visibleEntries.map((e) => e.msgId), ['new', 'old']);
    });
  });

  group('notificationDetailProvider - one row on open', () {
    test('the detail provider reads exactly the row asked for', () async {
      final container = containerWith([]);
      when(() => service.fetchDetail('m1')).thenAnswer(
        (_) async => NotificationDetailUIModel(
          entry: notificationEntry('m1', 'ValueChange'),
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
