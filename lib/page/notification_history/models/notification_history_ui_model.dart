import 'package:equatable/equatable.dart';

/// Guardian's per-device USP state, read once when the history page opens.
///
/// Two of the three fields are nullable and **both being null is a normal
/// answer** — it means the device has produced no notification yet, which is
/// exactly what a fresh session looks like. The page renders those as an em dash,
/// never as an error.
///
/// Naming follows constitution Section 3.3.4.
class SessionUspStateUIModel extends Equatable {
  final String deviceUuid;

  /// When the device last booted, or `null` if it has never said.
  final DateTime? lastBoot;

  /// When the device last produced USP traffic, or `null`.
  final DateTime? lastUspActivity;

  const SessionUspStateUIModel({
    required this.deviceUuid,
    this.lastBoot,
    this.lastUspActivity,
  });

  @override
  List<Object?> get props => [deviceUuid, lastBoot, lastUspActivity];
}

/// One row of the notification history list — metadata only, no body.
///
/// The list endpoint deliberately omits `body`, because a diagnostic body can be
/// hundreds of KB and the list would carry every one of them. The body is
/// fetched per row, on open.
class NotificationHistoryEntryUIModel extends Equatable {
  final String msgId;

  /// The cloud broker's receive time. **Not comparable with a local clock** —
  /// it is the broker's, so anything that subtracts `DateTime.now()` from it is
  /// wrong in both directions.
  final DateTime originTs;

  /// The stored notify variant. `Unknown` is a **real stored value**, not a
  /// placeholder: it is what the cloud records for a notify with no recognisable
  /// variant, and such a row is rendered like any other.
  final String notificationType;

  /// Present only on `OperationComplete` rows. Null everywhere else, which is
  /// the common case and not a defect.
  final String? commandKey;

  const NotificationHistoryEntryUIModel({
    required this.msgId,
    required this.originTs,
    required this.notificationType,
    this.commandKey,
  });

  @override
  List<Object?> get props => [msgId, originTs, notificationType, commandKey];
}

/// The parsed `body` of one notification.
///
/// Sealed with **three** named variants plus a raw fallback, and the count is
/// the decision: a notify body carries exactly one of six members, and #1580
/// says to render the three that carry information a support engineer acts on
/// and pretty-print the rest. Six variants would be six widgets to maintain for
/// three that nobody reads.
///
/// Sealed rather than a nullable-field bag so the view's `switch` is exhaustive —
/// a seventh member arriving upstream lands in [RawBodyUIModel] and is still
/// legible, rather than rendering as a column of nulls.
sealed class NotificationBodyUIModel extends Equatable {
  const NotificationBodyUIModel();
}

/// A parameter changed. The one variant whose two fields are the whole story.
final class ValueChangeBodyUIModel extends NotificationBodyUIModel {
  final String paramPath;
  final String paramValue;

  const ValueChangeBodyUIModel({
    required this.paramPath,
    required this.paramValue,
  });

  @override
  List<Object?> get props => [paramPath, paramValue];
}

/// A command finished — the variant a diagnostic result arrives on.
///
/// Carries either [outputArgs] or a failure, never both, and the **absence of
/// the failure** is what makes it a success. The same rule #1579 fixed on the
/// live SSE path, and it has to be applied again here because this is a second,
/// independent parse of the same payload — the stored copy.
final class OperationCompleteBodyUIModel extends NotificationBodyUIModel {
  final String commandName;
  final String commandKey;
  final Map<String, String> outputArgs;
  final String? errorCode;
  final String? errorMessage;

  /// Whether the stored payload carried a failure member **at all**.
  ///
  /// Set by the parser, not derived from [errorCode], for exactly the reason
  /// `OperateResult.refused` is not: a refusal the router named with a message
  /// and no code — or with a third spelling of the code — would otherwise read
  /// as a success on the one channel a refusal ever arrives on.
  final bool refused;

  const OperationCompleteBodyUIModel({
    required this.commandName,
    required this.commandKey,
    this.outputArgs = const {},
    this.errorCode,
    this.errorMessage,
    this.refused = false,
  });

  @override
  List<Object?> get props =>
      [commandName, commandKey, outputArgs, errorCode, errorMessage, refused];
}

/// A router event.
final class EventBodyUIModel extends NotificationBodyUIModel {
  final String eventName;
  final Map<String, String> params;

  const EventBodyUIModel({required this.eventName, this.params = const {}});

  @override
  List<Object?> get props => [eventName, params];
}

/// Anything else, kept readable rather than dropped.
///
/// Covers `obj_creation`, `obj_deletion`, `on_board_request`, a body that is
/// absent altogether, and whatever the cloud starts storing next.
final class RawBodyUIModel extends NotificationBodyUIModel {
  /// Pretty-printed JSON, or an empty string when there was no body at all.
  final String pretty;

  const RawBodyUIModel(this.pretty);

  bool get isEmpty => pretty.isEmpty;

  @override
  List<Object?> get props => [pretty];
}

/// One history row together with the body fetched when it was opened.
class NotificationDetailUIModel extends Equatable {
  final NotificationHistoryEntryUIModel entry;
  final NotificationBodyUIModel body;

  const NotificationDetailUIModel({required this.entry, required this.body});

  @override
  List<Object?> get props => [entry, body];
}
