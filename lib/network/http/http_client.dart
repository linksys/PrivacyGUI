import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/network/jnap/jnap_command_executor_mixin.dart';
import 'package:linksys_moab/network/jnap/command/base_command.dart';
import 'package:linksys_moab/network/jnap/command/http_base_command.dart';
import 'package:linksys_moab/util/extensions.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:http/io_client.dart';
import 'package:linksys_moab/util/storage.dart';
import 'model/base_response.dart';

/// A error response stream
/// Everytime occurs error response the stream will emit #ErrorResponse
StreamController<ErrorResponse> _errorResponseStreamController =
    StreamController();

Stream<ErrorResponse> get errorResponseStream => _errorResponseStreamController.stream;

void releaseErrorResponseStream() {
  _errorResponseStreamController.close();
}

///
/// timeout - will throw Timeout exception on ${timeout} seconds
///
class MoabHttpClient extends http.BaseClient with JNAPCommandExecutor<Response> {
  MoabHttpClient({
    IOClient? client,
    int timeoutMs = 10000,
    int retries = 3,
    FutureOr<bool> Function(http.BaseResponse) when = _defaultWhen,
    FutureOr<bool> Function(Object, StackTrace) whenError = _defaultWhenError,
    Duration Function(int retryCount) delay = _defaultDelay,
    FutureOr<void> Function(BaseRequest, http.BaseResponse?, int retryCount)?
        onRetry,
  })  : _inner = client ?? IOClient(),
        _timeoutMs = timeoutMs,
        _retries = retries,
        _when = when,
        _whenError = whenError,
        _delay = delay,
        _onRetry = onRetry {
    RangeError.checkNotNegative(_retries, 'retries');
  }

  MoabHttpClient.withCert(
    SecurityContext context, {
    int timeoutMs = 10000,
    int retries = 3,
    FutureOr<bool> Function(http.BaseResponse) when = _defaultWhen,
    FutureOr<bool> Function(Object, StackTrace) whenError = _defaultWhenError,
    Duration Function(int retryCount) delay = _defaultDelay,
    FutureOr<void> Function(BaseRequest, http.BaseResponse?, int retryCount)?
        onRetry,
  }) : this(
          client: IOClient(HttpClient(context: context)),
          timeoutMs: timeoutMs,
          retries: retries,
          when: when,
          whenError: whenError,
          delay: delay,
          onRetry: onRetry,
        );

  final int _timeoutMs;
  final IOClient _inner;

  /// The number of times a request should be retried.
  final int _retries;

  /// The callback that determines whether a request should be retried.
  final FutureOr<bool> Function(http.BaseResponse) _when;

  /// The callback that determines whether a request when an error is thrown.
  final FutureOr<bool> Function(Object, StackTrace) _whenError;

  /// The callback that determines how long to wait before retrying a request.
  final Duration Function(int) _delay;

  /// The callback to call to indicate that a request is being retried.
  final FutureOr<void> Function(BaseRequest, http.BaseResponse?, int)? _onRetry;

  Map<String, String> get defaultHeader => {
        moabSiteIdKey: moabRetailSiteId,
        HttpHeaders.contentTypeHeader: ContentType.json.value,
        HttpHeaders.acceptHeader: ContentType.json.value
      };

  String getHost() => CloudEnvironmentManager().currentConfig?.apiBase ?? '';

  Future<String> combineUrl(String endpoint, {Map<String, String>? args}) async {
    await CloudEnvironmentManager().fetchCloudConfig();
    String url = '${getHost()}$endpoint';
    if (args != null) {
      args.forEach((key, value) {
        url = url.replaceFirst(key, value);
      });
    }
    return url;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final splitter = StreamSplitter(request.finalize());

    var i = 0;
    for (;;) {
      StreamedResponse? response;
      try {
        _logRequest(request, retry: i);
        final copied = _copyRequest(request, splitter.split());
        response = await _inner
            .send(copied)
            .timeout(Duration(milliseconds: _timeoutMs));
      } catch (error, stackTrace) {
        logger.e('Http Request Error: $error');
        if (i == _retries || !await _whenError(error, stackTrace)) rethrow;
      }

      if (response != null) {
        if (i == _retries || !await _when(response)) return response;

        // Make sure the response stream is listened to so that we don't leave
        // dangling connections.
        _unawaited(response.stream.listen((_) {}).cancel().catchError((_) {}));
      }

      await Future<void>.delayed(_delay(i));
      await _onRetry?.call(request, response, i);
      i++;
    }
  }

  /// Returns a copy of [original] with the given [body].
  StreamedRequest _copyRequest(BaseRequest original, Stream<List<int>> body) {
    final request = StreamedRequest(original.method, original.url)
      ..contentLength = original.contentLength
      ..followRedirects = original.followRedirects
      ..headers.addAll(original.headers)
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;

    body.listen(request.sink.add,
        onError: request.sink.addError,
        onDone: request.sink.close,
        cancelOnError: true);

    return request;
  }

  @override
  void close() => _inner.close();

  @override
  Future<Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await super
        .delete(url, headers: headers, body: body, encoding: encoding)
        .then((response) => _handleResponse(response));
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await super
        .patch(url, headers: headers, body: body, encoding: encoding)
        .then((response) => _handleResponse(response));
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await super
        .put(url, headers: headers, body: body, encoding: encoding)
        .then((response) => _handleResponse(response));
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await super
        .post(url, headers: headers, body: body, encoding: encoding)
        .then((response) => _handleResponse(response));
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers, bool ignoreResponse = false}) async {
    final response = await super
        .get(url, headers: headers)
        .then((response) => _handleResponse(response));
    _logResponse(response, ignoreResponse: ignoreResponse);
    return response;
  }

  @override
  Future<Response> head(Uri url, {Map<String, String>? headers}) async {
    final response = await super
        .head(url, headers: headers)
        .then((response) => _handleResponse(response));
    _logResponse(response);
    return response;
  }

  Future<bool> download(Uri url, Uri savedPathUri, {Map<String, String>? headers}) async {
    try {
      final response = await super
          .get(url, headers: headers)
          .then((response) => _handleResponse(response));
      _logResponse(response, ignoreResponse: true);
      Storage.saveByteFile(savedPathUri, response.bodyBytes);
    } catch (e) {
      logger.e('Download data failed!', e);
      return false;
    }
    return true;
  }

  _logRequest(http.BaseRequest request, {int retry = 0}) {
    logger.i('\nREQUEST---------------------------------------------------\n'
        '${retry == 0 ? '' : 'RETRY: $retry\n'}'
        'URL: ${request.url}, METHOD: ${request.method}\n'
        'HEADERS: ${request.headers}\n'
        '${request is http.Request ? 'BODY: ${request.body}' : ''}\n'
        '---------------------------------------------------REQUEST END\n');
  }

  _logResponse(http.Response response, {bool ignoreResponse = false}) {
    final request = response.request;
    if (request != null) {
      logger.i('\nRESPONSE---------------------------------------------------\n'
          'URL: ${request.url}, METHOD: ${request.method}\n'
          'REQUEST HEADERS: ${request.headers}\n'
          'RESPONSE HEADERS: ${response.headers}\n'
          'RESPONSE: ${response.statusCode}, ${ignoreResponse ? '' : response.body}\n'
          '---------------------------------------------------RESPONSE END\n');
    }
  }

  ///
  /// Handling Cloud Error Response
  /// 400 -
  /// 500 -
  ///
  Response _handleResponse(Response response) {
    // TODO Revisit - needs to considering about 500 internal server error, 502/503 bad requests
    if (response.statusCode >= 400 && response.body.isJsonFormat()) {
      logger.i('Cloud Error: ${response.statusCode}, ${response.body}');
      final error = ErrorResponse.fromJson(response.statusCode, json.decode(response.body));
      _errorResponseStreamController.add(error);
      throw error;
    }
    return response;
  }

  @override
  void dropCommand(String id) {
    // DO nothing
  }

  @override
  Future<Response> execute(BaseCommand command) async {
    if (command is JNAPHttpCommand) {
      return post(Uri.parse(command.url), headers: command.header, body: command.data);
    }
    throw Exception();
  }
}

bool _defaultWhen(http.BaseResponse response)  {
  try {
    logger.d('response: ${response.reasonPhrase}');
    if (response.statusCode == 503) {
      return true;
    }
    if (response.statusCode == 404) {
      return true;
    }
    if (response.statusCode == 401) {
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}

bool _defaultWhenError(Object error, StackTrace stackTrace) =>
    error is TimeoutException;

Duration _defaultDelay(int retryCount) =>
    const Duration(milliseconds: 500) * math.pow(1.5, retryCount);

void _unawaited(Future<void>? f) {}
