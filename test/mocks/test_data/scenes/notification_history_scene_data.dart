/// The composed scene for `usp_notification_history_view` — the layout gate's, and
/// the golden suite's.
///
/// Written for #1580 rather than moved: the page is new, so there was no golden
/// fixture to promote. One file feeds both suites, which is the rule
/// `dmz_scene_data.dart` records and the reason the gate may not reach into
/// `test/golden_test/` (#1361).
///
/// Named `_scene_data` and not `_test_data` on purpose: the builders in
/// `test/mocks/test_data/` produce codegen models for behaviour assertions, while
/// this file holds a whole composed state ready to hand to a provider override.
/// Importing the wrong one yields a fixture that does not match its overrides, and
/// the page then renders `AppLoader` instead of itself — which is a green cell that
/// measured a spinner.
library;

import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';
import 'package:privacy_gui/page/notification_history/providers/usp_notification_history_state.dart';

/// A fixed instant rather than `DateTime.now()`.
///
/// The rendered stamp is `YYYY-MM-DD HH:MM:SS`, whose width does not vary with the
/// value — but a golden would still change every time it ran, and a fixture whose
/// output moves cannot be diffed. Local time, because that is what the page shows.
final _at = DateTime.fromMillisecondsSinceEpoch(1757000000000);

/// One history row, for a test that cares about a property rather than a scene.
///
/// Here rather than copied into each suite: it was defined identically in the notifier
/// test and the view test, which is the shape that lets a later widening of one drift
/// from the other. Distinct from the composed scenes below — those are whole states
/// ready for a provider override, this is an arrange-helper.
NotificationHistoryEntryUIModel notificationEntry(
  String msgId,
  String notificationType, {
  int ms = 1757000000000,
  String? commandKey,
}) =>
    NotificationHistoryEntryUIModel(
      msgId: msgId,
      originTs: DateTime.fromMillisecondsSinceEpoch(ms),
      notificationType: notificationType,
      commandKey: commandKey,
    );

/// Three rows, chosen so that between them every widget on the page renders.
///
/// - **`OperationComplete`** is the longest of USP's seven stored type names and the
///   only variant that carries a `commandKey`, so this row is both the widest type
///   label and the only one that renders the second field line. It is therefore the
///   worst case for the row's header `Wrap` — the type on the left, the timestamp on
///   the right, neither flexible — and the only row that can overflow on the
///   `commandKey` line.
/// - **`ValueChange`** is an ordinary row with no command key, which is what most
///   rows are. It proves the `commandKey` line is genuinely conditional rather than
///   rendered empty.
/// - **`Unknown`** is a **real stored value**, not a placeholder: it is what the
///   cloud records for a notify with no recognisable variant, and #1580's acceptance
///   4 is that such a row renders. Having it in the gate's fixture means a change
///   that started filtering it out fails here as well as in the widget test.
///
/// The ids are deliberately UUID-length, because that is what Guardian mints and a
/// short placeholder would make the field lines look narrower than they ever are.
final _gateEntries = [
  NotificationHistoryEntryUIModel(
    msgId: 'c1f0a5be-6d3c-4a71-9f42-8b0d5e7a1c93',
    originTs: _at.add(const Duration(minutes: 2)),
    notificationType: 'OperationComplete',
    commandKey: 'a7d2e914-3f65-4c08-b1ae-6d9052fb37c4',
  ),
  NotificationHistoryEntryUIModel(
    msgId: '4b8e2d17-90fa-4c53-8e6b-2f1a7c94d05e',
    originTs: _at.add(const Duration(minutes: 1)),
    notificationType: 'ValueChange',
  ),
  NotificationHistoryEntryUIModel(
    msgId: 'e59c7base-invalid-shaped-id-kept-short',
    originTs: _at,
    notificationType: 'Unknown',
  ),
];

/// The state every `page.notification_history` cell is measured against.
///
/// **`visibleCount: 2` with three rows is what puts the Show more button on screen**,
/// and it is why this scene is three rows rather than twenty-six. `hasMore` is
/// `filteredEntries.length > visibleCount`, so the honest alternative — 26 rows, one
/// past `NotificationHistoryState.pageSize` — would render 25 cards in every one of
/// 234 cells to exercise one centred button. Setting the offset instead measures the
/// same widget set at a fraction of the pump, and the paging arithmetic itself is
/// asserted in `usp_notification_history_notifier_test.dart`, where it belongs.
///
/// Both timestamps are present, which is the **wider** of the two session-state
/// renderings: the null case is an em dash. The em-dash case is what the golden
/// `empty` scene below covers, so neither is unmeasured.
final gateNotificationHistoryState = NotificationHistoryState(
  sessionState: SessionUspStateUIModel(
    deviceUuid: 'b3d81f27-5a4e-40c9-8f16-7e2b9d0a4c58',
    lastBoot: _at.subtract(const Duration(days: 3, hours: 7)),
    lastUspActivity: _at,
  ),
  entries: _gateEntries,
  visibleCount: 2,
);

/// A fresh support session: state read, nothing produced yet.
///
/// The page's other content state, and #1580's acceptance 2 — an ordinary empty
/// state rather than an error. Both timestamps null, because a device that has
/// produced no notification is also a device that has reported no activity, so this
/// scene is the em-dash rendering as well.
const emptyNotificationHistoryState = NotificationHistoryState(
  sessionState: SessionUspStateUIModel(
    deviceUuid: 'b3d81f27-5a4e-40c9-8f16-7e2b9d0a4c58',
  ),
);
