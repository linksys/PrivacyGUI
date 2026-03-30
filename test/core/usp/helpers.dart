import 'dart:convert';

import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';

/// Create a fake SSE event with given type and data.
SseEvent fakeEvent(String event, String data, {String? id}) =>
    SseEvent(event: event, data: data, id: id);

/// Create a heartbeat SSE event.
SseEvent heartbeatEvent() => fakeEvent('heartbeat', '');

/// Create a connected SSE event.
SseEvent connectedEvent() => fakeEvent('connected', '');

/// Create a debug SSE event (synthetic, from UspBridgeClient internals).
SseEvent debugEvent(String message) => fakeEvent('_debug', message);

/// Create a notification SSE event with JSON payload.
SseEvent notificationEvent({
  required String subscriptionId,
  required String type,
  Map<String, dynamic>? valueChange,
  Map<String, dynamic>? objCreation,
  Map<String, dynamic>? objDeletion,
  Map<String, dynamic>? operComplete,
}) {
  final payload = <String, dynamic>{
    'subscription_id': subscriptionId,
    'type': type,
  };
  if (valueChange != null) payload['value_change'] = valueChange;
  if (objCreation != null) payload['obj_creation'] = objCreation;
  if (objDeletion != null) payload['obj_deletion'] = objDeletion;
  if (operComplete != null) payload['oper_complete'] = operComplete;

  return fakeEvent('notification', jsonEncode(payload));
}
