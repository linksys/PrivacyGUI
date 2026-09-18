/// Goldens for the Remote Assistance notification history page (#1580).
///
/// Three states, which are the three #1580's acceptance list names — and the reason
/// they are three rather than one is that two of them are *empty screens that must
/// not read as faults*:
///
/// - **`populated`** — the two session timestamps, the type filter, three rows and the
///   Show more button. Includes the `Unknown` row, because
///   `gateNotificationHistoryState` carries one.
/// - **`empty`** — a fresh session, which is the normal state at session open. Also
///   the em-dash rendering of both timestamps, since a device that has produced no
///   notification has reported no activity either.
/// - **`unknown_only`** — one row, `notificationType: Unknown`. Its own state despite
///   `populated` containing such a row, because that is the one this page could
///   plausibly *lose*: `Unknown` is a real stored value and treating it as a
///   placeholder to filter out is the mistake, so a golden of it alone is what shows
///   the row rendered rather than the empty state.
///
/// The fixture is the layout gate's own — `notification_history_scene_data.dart` — so
/// there is one composed state feeding both suites and no second copy to drift.
library;

import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';
import 'package:privacy_gui/page/notification_history/providers/usp_notification_history_state.dart';
import 'package:privacy_gui/page/notification_history/views/usp_notification_history_view.dart';

import '../../../../mocks/provider_overrides/mock_notification_history.dart';
import '../../../../mocks/test_data/scenes/notification_history_scene_data.dart';
import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';

/// One `Unknown` row and nothing else.
///
/// Built here rather than in the scene file because it exists for this suite alone:
/// the gate's populated scene already covers an `Unknown` row *among others*, and
/// what this adds is the case where it is the only thing that could render.
final _unknownOnlyState = NotificationHistoryState(
  sessionState: emptyNotificationHistoryState.sessionState,
  entries: [
    NotificationHistoryEntryUIModel(
      msgId: '9e0c4a83-71bd-4f2e-b6a5-3c81d92f0e47',
      originTs: DateTime.fromMillisecondsSinceEpoch(1757000000000),
      notificationType: 'Unknown',
    ),
  ],
);

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'notification_history',
      view: () => const UspNotificationHistoryView(),
      shell: ShellType.custom,
      states: {
        'populated': (overrides) => overrides.addAll(
              notificationHistoryOverrides(),
            ),
        'empty': (overrides) => overrides.addAll(
              notificationHistoryOverrides(emptyNotificationHistoryState),
            ),
        'unknown_only': (overrides) => overrides.addAll(
              notificationHistoryOverrides(_unknownOnlyState),
            ),
      },
    ),
  );
}
