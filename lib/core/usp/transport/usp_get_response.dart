import 'package:privacy_gui/core/usp/errors/usp_error.dart';

/// Decodes the unified GET response into the transport's flat path map.
///
/// Client failures are returned as fulfilled responses with error code 9999.
/// Preserve the underlying category in the standard error format so auth
/// recovery and the service error mapper see it before interpreting missing paths.
/// Ordinary per-path errors retain the existing partial-read contract: an
/// unsupported optional path is absent, while successful paths remain usable.
Map<String, String> decodeUspGetResponse(Object? response) {
  if (response is! Map ||
      response['result'] is! Map ||
      response['result']['data'] is! Map) {
    throw 'Get failed: Protocol error: Invalid GET response';
  }
  final result = response['result'] as Map;
  final errors = result['error'];
  if (errors is Map) {
    for (final error in errors.values) {
      if (error is! Map) continue;
      final code = error['errorCode'];
      if (code != 9999 && code != '9999') continue;
      final message = error['errorMessage']?.toString() ?? 'Request failed';
      throw 'Get failed: ${unwrapUspClientError(message)}';
    }
  }

  final data = result['data'] as Map;
  return {
    for (final entry in data.entries)
      entry.key?.toString() ?? '': entry.value?.toString() ?? '',
  };
}
