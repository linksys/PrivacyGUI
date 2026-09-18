import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/page/notification_history/models/notification_history_ui_model.dart';

/// Null when there is no bridge yet — the same window
/// `uspBridgeClientProvider` documents, before a Guardian session exists.
final uspNotificationHistoryServiceProvider =
    Provider<UspNotificationHistoryService?>((ref) {
  final bridge = ref.watch(uspBridgeClientProvider);
  if (bridge == null) return null;
  return UspNotificationHistoryService(bridge);
});

/// Reads Guardian's notification store for the current support session.
///
/// Three JSON reads on the Guardian proxy, none of which the on-router bridge
/// has a counterpart for — see `RemoteReads`. Every one of them works with the
/// device **offline**, which is the point: the store is the cloud's, not the
/// router's.
///
/// ## Two parse rules that fail silently if broken
///
/// **The envelope is camelCase, `body` is snake_case.** `msgId` / `originTs` /
/// `notificationType` / `commandKey` and `deviceUuid` / `lastBoot` /
/// `lastUspActivity` on one side; `value_change.param_path` on the other.
/// `CLOUD_GUARDIANS#205`'s body spells the envelope snake_case and the OpenAPI
/// spec spells it camelCase; the spec is the accurate one, and a parser written
/// from the issue returns nulls without raising.
///
/// **`originTs` and the two state timestamps are epoch milliseconds.** Read as
/// seconds they render as 1970 and nothing objects.
class UspNotificationHistoryService {
  final UspBridgeClient _bridge;

  UspNotificationHistoryService(this._bridge);

  /// Guardian's per-device state. Not session-scoped, unlike the two below.
  Future<SessionUspStateUIModel> fetchState() async {
    final json = await _read(_bridge.uspState);
    return SessionUspStateUIModel(
      deviceUuid: json['deviceUuid']?.toString() ?? '',
      lastBoot: _epochMillis(json['lastBoot']),
      lastUspActivity: _epochMillis(json['lastUspActivity']),
    );
  }

  /// This session's notification metadata, in the order served (newest first).
  ///
  /// An empty list is the normal state at session open, and a missing `entries`
  /// key is treated the same way: history is session-scoped, so there is nothing
  /// to read until the session produces something.
  Future<List<NotificationHistoryEntryUIModel>> fetchHistory() async {
    final json = await _read(_bridge.notificationsHistory);
    final entries = json['entries'];
    if (entries is! List) return const [];
    return entries
        .whereType<Map<String, dynamic>>()
        .map(_toEntry)
        .toList(growable: false);
  }

  /// One entry with its body, fetched when a row is opened.
  ///
  /// Throws [ResourceNotFoundError] on a `404`, which the spec makes cover both
  /// "does not exist" and "is not yours" without distinguishing them.
  Future<NotificationDetailUIModel> fetchDetail(String msgId) async {
    final json = await _read(() => _bridge.notification(msgId));
    return NotificationDetailUIModel(
      entry: _toEntry(json),
      body: _toBody(json['body']),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Parsing
  // ─────────────────────────────────────────────────────────────────────────

  NotificationHistoryEntryUIModel _toEntry(Map<String, dynamic> json) =>
      NotificationHistoryEntryUIModel(
        msgId: json['msgId']?.toString() ?? '',
        // Epoch 0 rather than null for a row that somehow carries no timestamp:
        // the field is non-nullable because every stored notify has one, and a
        // row is still worth showing without it.
        originTs: _epochMillis(json['originTs']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        // `Unknown` is a real stored value the cloud writes for an unrecognised
        // variant, so a missing type reads as the same thing rather than as an
        // empty string the UI would have to special-case.
        notificationType: json['notificationType']?.toString() ?? 'Unknown',
        commandKey: _nonEmpty(json['commandKey']),
      );

  /// Exactly one of six members, three of which are worth their own shape.
  NotificationBodyUIModel _toBody(Object? raw) {
    if (raw is! Map<String, dynamic>) return const RawBodyUIModel('');

    final valueChange = raw['value_change'];
    if (valueChange is Map<String, dynamic>) {
      return ValueChangeBodyUIModel(
        paramPath: valueChange['param_path']?.toString() ?? '',
        paramValue: valueChange['param_value']?.toString() ?? '',
      );
    }

    final operComplete = raw['oper_complete'];
    if (operComplete is Map<String, dynamic>) {
      // The failure member's *presence* is what marks the refusal, and the code
      // inside it is only detail — read under both spellings because the bridge
      // hands some payloads through with protobuf's camelCase intact. Same rule
      // and same reason as `OperateResult.refused` (#1579); this is a second,
      // independent parse of the same payload, so the rule has to be applied
      // twice.
      final failure = operComplete['cmd_failure'];
      final failureMap = failure is Map<String, dynamic> ? failure : null;
      return OperationCompleteBodyUIModel(
        commandName: operComplete['command_name']?.toString() ?? '',
        commandKey: operComplete['command_key']?.toString() ?? '',
        outputArgs: _stringMap(operComplete['output_args']),
        errorCode: _nonEmpty(failureMap?['err_code'] ?? failureMap?['errCode']),
        errorMessage:
            _nonEmpty(failureMap?['err_msg'] ?? failureMap?['errMsg']),
        refused: failureMap != null,
      );
    }

    final event = raw['event'];
    if (event is Map<String, dynamic>) {
      return EventBodyUIModel(
        eventName: event['event_name']?.toString() ?? '',
        params: _stringMap(event['params']),
      );
    }

    // `obj_creation`, `obj_deletion`, `on_board_request`, and whatever is stored
    // next. Legible rather than dropped — #1580 asks for three shapes plus a
    // fallback, not six widgets.
    return RawBodyUIModel(
      const JsonEncoder.withIndent('  ').convert(raw),
    );
  }

  Map<String, String> _stringMap(Object? raw) => raw is Map
      ? {
          for (final e in raw.entries) e.key.toString(): e.value.toString(),
        }
      : const {};

  /// Epoch **milliseconds** to local time, or null.
  ///
  /// Null is a normal answer for both state timestamps: the device has produced
  /// nothing yet.
  DateTime? _epochMillis(Object? raw) {
    final ms = raw is int ? raw : (raw is num ? raw.toInt() : null);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  }

  String? _nonEmpty(Object? raw) {
    final s = raw?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Errors
  // ─────────────────────────────────────────────────────────────────────────

  /// Maps the transport's vocabulary to [ServiceError], per constitution
  /// Article XIII. Nothing above this layer sees an HTTP status or a
  /// `SessionExpiredException`.
  ///
  /// **The last arm is a catch-all, and §13.3 requires it to be.** The typed arms
  /// above cover what this client throws deliberately; they do not cover what the
  /// stack underneath throws by itself. `_withAuthRetry` does a bare
  /// `await request()`, so an `http.ClientException` — a network drop, which is the
  /// *expected* failure on a page an agent reads over the public internet — and a
  /// `FormatException` out of `jsonDecode` both reach here untyped. Without this arm
  /// they escaped `ServiceError` entirely: `build()`'s `on ServiceError catch` missed
  /// them, and the view's `error is ServiceError ? error : null` then rendered a
  /// failure screen with no message on it at all.
  ///
  /// [UnexpectedError] rather than [NetworkError] for the drop, deliberately: telling
  /// the two apart needs `package:http`'s exception type in the service layer, and a
  /// guess between them would be a worse answer than the honest fallback whose
  /// `detail` the UI is allowed to surface.
  Future<Map<String, dynamic>> _read(
    Future<Map<String, dynamic>> Function() read,
  ) async {
    try {
      return await read();
    } on BridgeReadException catch (e) {
      throw e.isNotFound
          ? ResourceNotFoundError(code: e.statusCode, detail: e.toString())
          : UnexpectedError(code: e.statusCode, detail: e.toString());
    } on SessionExpiredException catch (e) {
      throw SessionTokenExpiredError(detail: e.message);
    } on StateError catch (e) {
      // The transport has no `RemoteReads`, i.e. this ran in a local build. The
      // page guards against that before calling, so reaching here means the
      // guard was removed — report it as a service that cannot serve rather than
      // letting a framework error reach the UI.
      throw ServiceNotInitializedError(detail: e.message);
    } catch (e) {
      throw UnexpectedError(detail: e.toString());
    }
  }
}
