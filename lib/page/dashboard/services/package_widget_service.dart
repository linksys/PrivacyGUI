import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/dashboard/models/cgi_call_result.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:privacy_gui/page/dashboard/providers/http_client_provider.dart';

final packageWidgetServiceProvider = Provider<PackageWidgetService>((ref) {
  return PackageWidgetService(
    usp: ref.watch(uspClientProvider),
    sse: ref.watch(sseManagerProvider),
    throttler: ref.watch(bridgeRequestThrottlerProvider),
    httpClient: ref.watch(httpClientProvider),
  );
});

/// Router I/O for package widgets (#766, #767): the USP reads and SSE
/// subscriptions of a widget's `subscription`, the CGI calls of its
/// `dataSource` and its actions, and the `apps.json` / template fetches of the
/// loader.
///
/// Stateless (constitution Article VI).
class PackageWidgetService {
  PackageWidgetService({
    required UspClient? usp,
    required SseManager? sse,
    required BridgeRequestThrottler throttler,
    required http.Client httpClient,
    String? baseUrl,
  })  : _usp = usp,
        _sse = sse,
        _throttler = throttler,
        _httpClient = httpClient,
        _baseUrl = baseUrl;

  final UspClient? _usp;
  final SseManager? _sse;
  final BridgeRequestThrottler _throttler;
  final http.Client _httpClient;
  final String? _baseUrl;

  /// USP GET of [paths], as one request.
  ///
  /// `null` when there is no USP client, i.e. no session.
  Future<Map<String, dynamic>?> fetchUspPaths(List<String> paths) async {
    final usp = _usp;
    if (usp == null) return null;
    try {
      return await usp.get(paths);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Subscribes to the value changes of a widget's [subscription] and hands
  /// each one to [onValueChange] as a full USP path and its new value.
  ///
  /// The subscription is `pkg-<widgetId>-valuechange` on the first path.
  /// Returns the cleanup that removes it, or `null` when there is no SSE
  /// manager (no session) and nothing was subscribed.
  Future<Future<void> Function()?> subscribeValueChanges({
    required String widgetId,
    required WidgetSubscriptionConfig subscription,
    required void Function(String path, Object? value) onValueChange,
  }) async {
    final sse = _sse;
    if (sse == null) return null;
    try {
      return await sse.subscribe(
        subscriptionId: 'pkg-$widgetId-valuechange',
        notifType: subscription.notifType,
        referenceList: subscription.paths.first,
        onNotification: (notification) {
          // Only a value change carries a value to hand on.
          if (notification.type != 'ValueChange') return;
          final path = notification.path;
          if (path == null) return;
          final valueChange =
              notification.payload['value_change'] as Map<String, dynamic>;
          onValueChange(path, valueChange['param_value']);
        },
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Fetches a widget's HTTP [dataSource] from the router and maps the JSON
  /// response through its `mapping`.
  ///
  /// `null`, with nothing sent, when the URL is not a local CGI path
  /// ([_isLocalCgiUrl]); `null` for a response that is not 200.
  Future<Map<String, dynamic>?> fetchHttpData(
    HttpDataSourceConfig dataSource,
  ) async {
    if (!_isLocalCgiUrl(dataSource.url)) {
      logger.w('[HTTP][PkgWidget]: Blocked non-local URL: ${dataSource.url}');
      return null;
    }
    try {
      final response = await _sendToCgi(
        url: dataSource.url,
        cacheKey: 'http:${dataSource.method}:${dataSource.url}',
        asGet: dataSource.method.toUpperCase() == 'GET',
        body: dataSource.body,
      );
      if (response.statusCode != 200) {
        logger.w('[HTTP][PkgWidget]: ${dataSource.url} returned '
            '${response.statusCode}');
        return null;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return applyMapping(json, dataSource.mapping);
    } catch (e) {
      throw _httpFailure(e);
    }
  }

  /// POSTs [body] to a CGI [url] on the router, for a template's `cgi_call`
  /// action: [CgiCallSuccess] on 200, [CgiCallFailure] with the status on any
  /// other answer, and [CgiCallSkipped], with nothing sent, when the URL is not
  /// a local CGI path ([_isLocalCgiUrl]).
  Future<CgiCallResult> postCgi({
    required String url,
    Map<String, dynamic>? body,
  }) async {
    if (!_isLocalCgiUrl(url)) {
      logger.w('[CGI][PkgWidget]: Blocked non-local URL: $url');
      return const CgiCallSkipped();
    }
    final http.Response response;
    try {
      response = await _sendToCgi(
        url: url,
        cacheKey: 'cgi:$url',
        asGet: false,
        body: body,
      );
    } catch (e) {
      throw _httpFailure(e);
    }
    if (response.statusCode == 200) return const CgiCallSuccess();
    logger.w('[CGI][PkgWidget]: $url returned ${response.statusCode}');
    return CgiCallFailure(statusCode: response.statusCode);
  }

  /// A package widget's request to a CGI [url] on the router: with the JWT
  /// ([_headers]), through the throttler at low priority under [cacheKey], and
  /// for a POST with [body] as JSON.
  Future<http.Response> _sendToCgi({
    required String url,
    required String cacheKey,
    required bool asGet,
    Map<String, dynamic>? body,
  }) {
    final targetUrl = Uri.parse('${_origin()}$url');
    final headers = _headers();
    return _throttler.enqueue<http.Response>(
      cacheKey: cacheKey,
      priority: RequestPriority.low,
      action: () => asGet
          ? _httpClient.get(targetUrl, headers: headers)
          : _httpClient.post(
              targetUrl,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            ),
    );
  }

  /// Reads `/api/apps.json` and returns the widget each installed app declares,
  /// as widget id → template URL. Apps without a widget, or whose widget lacks
  /// an id or a template URL, are skipped.
  ///
  /// `null` when apps.json is not 200.
  ///
  /// Not through the throttler, and with no headers: these are static files
  /// lighttpd serves.
  Future<Map<String, String>?> fetchWidgetEntries() async {
    try {
      final response =
          await _httpClient.get(Uri.parse('${_origin()}/api/apps.json'));
      if (response.statusCode != 200) {
        logger.w('[USP][PkgWidgets]: apps.json HTTP ${response.statusCode}');
        return null;
      }
      final appsJson = jsonDecode(response.body) as Map<String, dynamic>;
      final allApps = <Map<String, dynamic>>[
        ..._safeList(appsJson['apps']),
        ..._safeList(appsJson['userApps']),
      ];

      final entries = <String, String>{};
      for (final app in allApps) {
        final widget = app['widget'] as Map<String, dynamic>?;
        if (widget == null) continue;
        final templateUrl = widget['templateUrl'] as String?;
        final widgetId = widget['id'] as String?;
        if (templateUrl == null || widgetId == null) continue;
        entries[widgetId] = templateUrl;
      }
      return entries;
    } catch (e) {
      throw _httpFailure(e);
    }
  }

  /// Fetches one widget template and parses it. A [templateUrl] that starts
  /// with `http` is used as it is; any other is a path on the router.
  ///
  /// `null` when the template is not 200.
  Future<PackageWidgetTemplate?> fetchTemplate(String templateUrl) async {
    try {
      final fullUrl = templateUrl.startsWith('http')
          ? templateUrl
          : '${_origin()}$templateUrl';
      final response = await _httpClient.get(Uri.parse(fullUrl));
      if (response.statusCode != 200) {
        logger.w('[USP][PkgWidgets]: Template HTTP '
            '${response.statusCode} for $templateUrl');
        return null;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PackageWidgetTemplate.fromJson(json);
    } catch (e) {
      throw _httpFailure(e);
    }
  }

  /// A JSON value that should be a list of objects but may be a list, an
  /// empty object or absent.
  static List<Map<String, dynamic>> _safeList(dynamic value) {
    if (value is List) return value.cast<Map<String, dynamic>>();
    return [];
  }

  /// Whether [url] is a path under `/cgi-bin/` on the router itself — the only
  /// URLs a package widget's template may make the app call. A URL that does
  /// not parse is not one: nothing is sent for it either way.
  bool _isLocalCgiUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && !uri.hasAuthority && url.startsWith('/cgi-bin/');
  }

  /// The router's origin, read when a request is made: `Uri.base.origin`
  /// throws where the page has no origin, and that has to reach the caller as
  /// a failed request rather than as a failed service construction.
  String _origin() => _baseUrl ?? Uri.base.origin;

  /// An HTTP-side failure (a dropped request, a body that is not JSON, no
  /// origin) as a [ServiceError]. [UnexpectedError], as the other HTTP services
  /// do (`usp_notification_history_service.dart`): these endpoints are not USP,
  /// so `mapUspErrorToServiceError` has nothing to parse.
  ServiceError _httpFailure(Object e) =>
      UnexpectedError(originalError: e, detail: e.toString());

  /// The JWT lets a CGI endpoint verify the session if it chooses to.
  Map<String, String> _headers() {
    final token = _usp?.sessionToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

// =============================================================================
// Mapping helpers
// =============================================================================

/// Transform JSON response into flat map via dot-notation mapping.
///
/// Example:
///   json = `{"data": {"query": "1.2.3.4", "city": "Taipei"}}`
///   mapping = `{"ip": "data.query", "city": "data.city"}`
///   → `{"ip": "1.2.3.4", "city": "Taipei"}`
Map<String, dynamic> applyMapping(
  Map<String, dynamic> json,
  Map<String, String> mapping,
) {
  final result = <String, dynamic>{};
  for (final entry in mapping.entries) {
    result[entry.key] = resolvePath(json, entry.value);
  }
  return result;
}

/// Resolve dot-notation path: `"data.query"` → `json["data"]["query"]`
dynamic resolvePath(Map<String, dynamic> json, String path) {
  dynamic current = json;
  for (final segment in path.split('.')) {
    if (current is Map<String, dynamic>) {
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}
