import 'package:equatable/equatable.dart';

/// Guardian's per-device USP state, read once when the history page opens.
///
/// Both fields are nullable and **both being null is a normal answer** — it means
/// the device has produced no notification yet, which is exactly what a fresh
/// session looks like. The page renders those as an em dash, never as an error.
///
/// The endpoint also serves `deviceUuid`. It is not parsed: nothing on the page
/// shows it, and the session already knows which device it is talking to.
///
/// Naming follows constitution Section 3.3.4.
class SessionUspStateUIModel extends Equatable {
  /// When the device last booted, or `null` if it has never said.
  final DateTime? lastBoot;

  /// When the device last produced USP traffic, or `null`.
  final DateTime? lastUspActivity;

  const SessionUspStateUIModel({
    this.lastBoot,
    this.lastUspActivity,
  });

  @override
  List<Object?> get props => [lastBoot, lastUspActivity];
}

/// One row of the notification history list — metadata only, no body.
///
/// The list endpoint deliberately omits `body`, because a diagnostic body can be
/// hundreds of KB and the list would carry every one of them. The body is
/// fetched per row: as the row is built for a type that shows a line of it, and
/// when it is opened for the rest.
class NotificationHistoryEntryUIModel extends Equatable {
  final String msgId;

  /// The cloud broker's receive time. **Not comparable with a local clock** —
  /// it is the broker's, so anything that subtracts `DateTime.now()` from it is
  /// wrong in both directions.
  ///
  /// Null for a row served without one. Every stored notify should carry it, but
  /// a stand-in value would be a fabricated reading of this clock — epoch 0
  /// renders as a "1970-01-01" heading — so the absence is kept and rendered as
  /// absent.
  final DateTime? originTs;

  /// The stored notify variant. `Unknown` is a **real stored value**, not a
  /// placeholder: it is what the cloud records for a notify with no recognisable
  /// variant, and such a row is rendered like any other.
  final String notificationType;

  /// Present only on `OperationComplete` rows. Null everywhere else, which is
  /// the common case and not a defect.
  final String? commandKey;

  const NotificationHistoryEntryUIModel({
    required this.msgId,
    this.originTs,
    required this.notificationType,
    this.commandKey,
  });

  @override
  List<Object?> get props => [msgId, originTs, notificationType, commandKey];
}

/// A stored `notificationType` as the kebab-case key of an E2E identifier.
///
/// Article XVI §16.3 wants identifier values kebab-case and a per-instance key to
/// be a pure function of the data. The stored types are CamelCase with no
/// separator (`ValueChange`, `OnBoardRequest`), so the split is at each lowercase-
/// to-uppercase boundary — `value-change` — rather than a plain lowercase, which
/// would give `valuechange`. Anything else that is not a letter or digit becomes a
/// hyphen, so a type the cloud starts storing later still yields a key, and one
/// with nothing usable in it falls back to `unnamed`, the same sentinel
/// `ruleIdentifierKey` uses.
String notificationTypeIdentifierKey(String notificationType) {
  final slug = notificationType
      .trim()
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]}-${m[2]}')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'unnamed' : slug;
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

/// One history row together with its body.
class NotificationDetailUIModel extends Equatable {
  final NotificationHistoryEntryUIModel entry;
  final NotificationBodyUIModel body;

  const NotificationDetailUIModel({required this.entry, required this.body});

  @override
  List<Object?> get props => [entry, body];
}
