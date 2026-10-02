import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';

/// Test data builder for the notification history feature (#1580).
///
/// Distinct from `scenes/notification_history_scene_data.dart`, and the split is
/// the one CLAUDE.md names: a scene is a whole composed state ready to hand to a
/// provider override, and this is an arrange-helper for a test that cares about
/// one property of one row. It started life in the scene file, where it was the
/// odd one out.
class NotificationHistoryTestData {
  const NotificationHistoryTestData._();

  /// One history row.
  ///
  /// Defined once rather than per suite: the notifier test and the view test each
  /// had an identical copy, which is the shape that lets a later widening of one
  /// drift from the other. [ms] is epoch milliseconds, the unit the endpoint
  /// serves.
  static NotificationHistoryEntryUIModel entry(
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
}
