/// Provider overrides for `usp_notification_history_view` (#1580).
///
/// Two providers, and both are load-bearing. `notificationHistoryAvailableProvider`
/// is what the page checks *before* it watches anything: left at its real value it
/// reads `BridgeConfig.remoteReads`, which is null with no Guardian session, and
/// every cell would measure the page's "not available in this mode" state — a
/// centred icon over one sentence, which cannot overflow at any width. That is the
/// failure mode `kNotificationHistoryPageCase`'s `requires` exists to make
/// impossible, and this override is the other half of it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
List<Override> notificationHistoryOverrides([
  NotificationHistoryState? state,
]) =>
    [
      notificationHistoryAvailableProvider.overrideWithValue(true),
      uspNotificationHistoryProvider.overrideWith(
        () => FixedNotificationHistoryNotifier(
          state ?? gateNotificationHistoryState,
        ),
      ),
    ];
