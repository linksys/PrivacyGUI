/// Provider overrides for `usp_notification_history_view` (#1580).
///
/// Three providers, and all three are load-bearing. `notificationHistoryAvailableProvider`
/// is what the page checks *before* it watches anything: left at its real value it
/// reads `BridgeConfig.remoteReads`, which is null with no Guardian session, and
/// every cell would measure the page's "not available in this mode" state — a
/// centred icon over one sentence, which cannot overflow at any width. That is the
/// failure mode `kNotificationHistoryPageCase`'s `requires` exists to make
/// impossible, and this override is the other half of it.
///
/// The third is `notificationDetailProvider`, which every timeline row watches as it
/// is built. Left real, it throws `ServiceNotInitializedError` — there is no Guardian
/// session — and every row renders the one-word failure line in place of the path
/// and value it is there to measure. Nothing in `forbids` can see that, because the
/// failure line is plain text: this override is the only thing standing between the
/// gate and a sweep of the wrong content.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';
import 'package:privacy_gui/page/notification_history/providers/usp_notification_history_notifier.dart';

import '../test_data/scenes/notification_history_scene_data.dart';

/// A `uspNotificationHistoryProvider` pinned to one composed state.
///
/// `build()` is overridden rather than the service being mocked, because the page's
/// three mutators — `refresh`, `setTypeFilter`, `showMore` — all read the service
/// through `ref.read` and return early when it is null. So a pinned `build()` gives a
/// tree that renders every widget and answers no gesture, which is what a layout
/// sweep wants: the behaviour of those three is asserted against a mocked service in
/// `usp_notification_history_notifier_test.dart`.
class FixedNotificationHistoryNotifier extends UspNotificationHistoryNotifier {
  final NotificationHistoryState _fixed;

  FixedNotificationHistoryNotifier(this._fixed);

  @override
  Future<NotificationHistoryState> build() async => _fixed;
}

/// Overrides for the page, defaulting to [gateNotificationHistoryState].
///
/// Bodies come from [gateNotificationDetails]; a `msgId` it does not name gets an
/// empty raw body, which renders nothing inline rather than a failure.
List<Override> notificationHistoryOverrides([
  NotificationHistoryState? state,
]) =>
    [
      notificationDetailProvider.overrideWith(
        (ref, msgId) async => NotificationDetailUIModel(
          // The row it belongs to, or a stand-in when a state was passed that
          // this override does not know: nothing on the page reads `entry`, and
          // a lookup that threw would render every row's failure line instead.
          entry: (state ?? gateNotificationHistoryState).entries.firstWhere(
                (e) => e.msgId == msgId,
                orElse: () => notificationEntry(msgId, 'Unknown'),
              ),
          body: gateNotificationDetails[msgId] ?? const RawBodyUIModel(''),
        ),
      ),
      notificationHistoryAvailableProvider.overrideWithValue(true),
      uspNotificationHistoryProvider.overrideWith(
        () => FixedNotificationHistoryNotifier(
          state ?? gateNotificationHistoryState,
        ),
      ),
    ];
