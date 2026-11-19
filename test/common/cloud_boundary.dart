import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:privacy_gui/core/http/linksys_http_client.dart';

/// A request as the cloud received it.
class CloudRequest {
  CloudRequest(this.method, this.url, Map<String, String> headers, this.body)
      : _headers = {
          for (final MapEntry(:key, :value) in headers.entries)
            key.toLowerCase(): value,
        };

  final String method;
  final Uri url;
  final String body;
  final Map<String, String> _headers;

  /// The value of the header [name], which HTTP matches without case.
  String? header(String name) => _headers[name.toLowerCase()];

  /// The body decoded as JSON, or null for an empty body.
  Object? get json => body.isEmpty ? null : jsonDecode(body);
}

/// The Linksys cloud, as code under test meets it through
/// [LinksysHttpClient].
///
/// It answers each request from a table keyed by method and path, and records
/// every request in order. A request the table does not name fails the test,
/// naming it.
///
/// It replaces [send], beneath the client's retries, so a test never waits out
/// a retry delay. The client's own response handling still runs: an error
/// status with a JSON body becomes an `ErrorResponse`.
class CloudBoundary extends LinksysHttpClient {
  CloudBoundary() : super(getHost: () => 'https://cloud.test');

  final List<CloudRequest> requests = [];
  final Map<String, ({int status, String body, Map<String, String> headers})>
      _answers = {};
  final Map<String, Object> _failures = {};

  /// The cloud answers [method] [path] with [status] and [json].
  void answers(
    String method,
    String path, {
    int status = 200,
    Object? json,
    Map<String, String> headers = const {'content-type': 'application/json'},
  }) {
    _answers['$method $path'] = (
      status: status,
      body: json == null ? '' : jsonEncode(json),
      headers: headers,
    );
  }

  /// The cloud turns down [method] [path] with the error [code], in the body
  /// shape the cloud uses for errors.
  void answersError(String method, String path, String code,
      {int status = 400}) {
    answers(method, path, status: status, json: {
      'errors': [
        {
          'error': {'code': code, 'message': code},
        },
      ],
    });
  }

  /// A request to [method] [path] never gets an answer: [send] throws
  /// [error], as the client does when the connection fails.
  void fails(String method, String path, Object error) {
    _failures['$method $path'] = error;
  }

  /// The requests made to [path], oldest first.
  List<CloudRequest> requestsTo(String path) => [
        for (final request in requests)
          if (request.url.path == path) request,
      ];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.body : '';
    requests
        .add(CloudRequest(request.method, request.url, request.headers, body));
    final key = '${request.method} ${request.url.path}';
    final failure = _failures[key];
    if (failure != null) {
      throw failure;
    }
    final answer = _answers[key];
    if (answer == null) {
      throw StateError('The cloud was sent $key, which this test does not '
          'answer.');
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(answer.body)),
      answer.status,
      headers: answer.headers,
      request: request,
    );
  }
}
