import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';
import 'package:privacy_gui/page/notification_history/providers/usp_notification_history_state.dart';
import 'package:privacy_gui/page/notification_history/services/usp_notification_history_service.dart';

export 'package:privacy_gui/page/notification_history/providers/usp_notification_history_state.dart';

/// The notification history page's state.
///
/// `autoDispose`, because this is a leaf page whose data is scoped to one visit:
/// history is session-scoped on the server and there is nothing to cache across
/// navigations that a re-read would not answer more accurately.
///
/// **Nothing here is on a timer.** The spec prohibits polling these reads
/// outright — Guardian polls DynamoDB on our behalf roughly every ten seconds, so
/// a client-side loop would multiply the read volume the design budgets for. The
/// only re-read is [UspNotificationHistoryNotifier.refresh], wired to the page's
/// pull gesture, and `usp_notification_history_notifier_test.dart` asserts the
/// call count rather than trusting this paragraph.
final uspNotificationHistoryProvider = AsyncNotifierProvider.autoDispose<
    UspNotificationHistoryNotifier, NotificationHistoryState>(
  UspNotificationHistoryNotifier.new,
);

class UspNotificationHistoryNotifier
    extends AutoDisposeAsyncNotifier<NotificationHistoryState> {
  @override
  Future<NotificationHistoryState> build() async {
    final svc = ref.read(uspNotificationHistoryServiceProvider);
    if (svc == null) {
      // No Guardian session, so no bridge and no reads. The page renders its
      // "not available in this mode" state from `BridgeConfig.remoteReads`
      // before it ever watches this provider; reaching here means it was
      // navigated to some other way.
      throw const ServiceNotInitializedError(
        detail: 'Notification history needs a Remote Assistance session',
      );
    }

    try {
      // Sequential, not `Future.wait`: two reads against one proxy that both
      // land in the same 5-second budget, and a `wait` would report whichever
      // failed first while leaving the other's error unhandled.
      final sessionState = await svc.fetchState();
      final entries = await svc.fetchHistory();
      return NotificationHistoryState(
        sessionState: sessionState,
        entries: entries,
      );
    } on ServiceError catch (e) {
      logger.e('[USP][NotificationHistory]: Fetch failed', error: e);
      rethrow;
    }
  }

  /// Re-reads the history list. **User-triggered only.**
  ///
  /// History and not state: `lastBoot` / `lastUspActivity` are read once on open
  /// and deliberately freeze — see [NotificationHistoryState.sessionState]. The
  /// filter and the page offset survive a refresh, because the viewer set them
  /// and a refresh is not a reason to undo that.
  Future<void> refresh() async {
    final svc = ref.read(uspNotificationHistoryServiceProvider);
    final current = state.valueOrNull;
    if (svc == null || current == null) return;

    try {
      final entries = await svc.fetchHistory();
      state = AsyncData(current.copyWith(entries: entries));
    } on ServiceError catch (e) {
      logger.e('[USP][NotificationHistory]: Refresh failed', error: e);
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Narrows the list to one `notificationType`, or to all when null.
  ///
  /// Resets the page offset: keeping it would show a page from the middle of a
  /// result the viewer has not seen the start of.
  void setTypeFilter(String? type) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      typeFilter: type,
      clearTypeFilter: type == null,
      visibleCount: NotificationHistoryState.pageSize,
    ));
  }

  /// Shows one more page of the filtered list. No read — the window is in hand.
  void showMore() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      visibleCount: current.visibleCount + NotificationHistoryState.pageSize,
    ));
  }
}

/// Whether this build has a notification store to read at all.
///
/// The page's route is registered in every mode — the child routes of the shared
/// dashboard are one table — so a hand-typed URL reaches it locally. This is what
/// the view renders its "not available in this mode" state from, and it is a
/// property of the *transport*, not a mode read: `BridgeConfig.remoteReads` is
/// null exactly where there is nothing to read.
final notificationHistoryAvailableProvider = Provider<bool>(
  (ref) => ref.watch(bridgeConfigProvider)?.remoteReads != null,
);

/// One notification's stored body, fetched when its row is opened.
///
/// Separate from the list on purpose: the list endpoint carries no bodies because
/// a diagnostic body can be hundreds of KB, so fetching all of them to render a
/// table would move megabytes for a column nobody is looking at.
///
/// A `404` arrives as [ResourceNotFoundError] and means "no longer available" —
/// the spec makes it cover both "gone" and "not yours" without distinguishing
/// them, so there is one thing to report.
final notificationDetailProvider = FutureProvider.autoDispose
    .family<NotificationDetailUIModel, String>((ref, msgId) async {
  final svc = ref.watch(uspNotificationHistoryServiceProvider);
  if (svc == null) {
    throw const ServiceNotInitializedError(
      detail: 'Notification history needs a Remote Assistance session',
    );
  }
  return svc.fetchDetail(msgId);
});
