import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:moab_poc/util/logger.dart';

class MoabHttpClient extends http.BaseClient {
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    _logRequest(request);
    // TODO set client id, client secret, etc...
    return _inner.send(request).timeout(const Duration(seconds: 3));
  }

  @override
  Future<Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await super
        .delete(url, headers: headers, body: body, encoding: encoding);
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await super
        .patch(url, headers: headers, body: body, encoding: encoding);
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response =
        await super.put(url, headers: headers, body: body, encoding: encoding);
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response =
        await super.post(url, headers: headers, body: body, encoding: encoding);
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = await super.get(url, headers: headers);
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> head(Uri url, {Map<String, String>? headers}) async {
    final response = await super.head(url, headers: headers);
    _logResponse(response);
    return response;
  }

  _logRequest(http.BaseRequest request) {
    logger.i('\nREQUEST---------------------------------------------------\n'
        'URL: ${request.url}, METHOD: ${request.method}\n'
        'HEADERS: ${request.headers}\n'
        '${request is http.Request ? 'BODY: ${request.body}': ''}\n'
        '---------------------------------------------------REQUEST END\n');
  }

  _logResponse(http.Response response) {
    final request = response.request;
    if (request != null) {
      logger.i('\nRESPONSE---------------------------------------------------\n'
          'URL: ${request.url}, METHOD: ${request.method}\n'
          'HEADERS: ${request.headers}\n'
          '${request is http.Request ? 'BODY: ${request.body}': ''}\n'
          'RESPONSE: ${response.statusCode}, ${response.body}\n'
          '---------------------------------------------------RESPONSE END\n');
    }
  }
}
