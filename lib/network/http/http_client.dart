import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:moab_poc/config/cloud_environment_manager.dart';
import 'package:moab_poc/network/http/constant.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:http/io_client.dart';
import 'model/base_response.dart';


class MoabHttpClient extends http.BaseClient {

  MoabHttpClient({IOClient? client}): _inner = client ?? IOClient();

  factory MoabHttpClient.withCert(SecurityContext context) {
    return MoabHttpClient(client: IOClient(HttpClient(context: context)));
  }

  final IOClient _inner;

  final Map<String, String> defaultHeader = {
    moabSiteIdKey: moabRetailSiteId,
    HttpHeaders.contentTypeHeader: ContentType.json.value,
    HttpHeaders.acceptHeader: ContentType.json.value
  };

  String getHost() => CloudEnvironmentManager().currentConfig?.apiBase ?? '';
  String combineUrl(String endpoint, {Map<String, String>? args}) {
    String url = '${getHost()}$endpoint';
    if (args != null) {
      args.forEach((key, value) {
        url = url.replaceFirst(key, value);
      });
    }
    return url;
  }

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
        .delete(url, headers: headers, body: body, encoding: encoding).then((response) => _handleResponse(response));
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await super
        .patch(url, headers: headers, body: body, encoding: encoding).then((response) => _handleResponse(response));
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response =
        await super.put(url, headers: headers, body: body, encoding: encoding).then((response) => _handleResponse(response));
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response =
        await super.post(url, headers: headers, body: body, encoding: encoding).then((response) {
          logger.d('post');
             return _handleResponse(response);
        });
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = await super.get(url, headers: headers).then((response) => _handleResponse(response));
    _logResponse(response);
    return response;
  }

  @override
  Future<Response> head(Uri url, {Map<String, String>? headers}) async {
    final response = await super.head(url, headers: headers).then((response) => _handleResponse(response));
    _logResponse(response);
    return response;
  }

  _logRequest(http.BaseRequest request) {
    logger.i('\nREQUEST---------------------------------------------------\n'
        'URL: ${request.url}, METHOD: ${request.method}\n'
        'HEADERS: ${request.headers}\n'
        '${request is http.Request ? 'BODY: ${request.body}' : ''}\n'
        '---------------------------------------------------REQUEST END\n');
  }

  _logResponse(http.Response response) {
    final request = response.request;
    if (request != null) {
      logger.i('\nRESPONSE---------------------------------------------------\n'
          'URL: ${request.url}, METHOD: ${request.method}\n'
          'HEADERS: ${request.headers}\n'
          '${request is http.Request ? 'BODY: ${request.body}' : ''}\n'
          'RESPONSE: ${response.statusCode}, ${response.body}\n'
          '---------------------------------------------------RESPONSE END\n');
    }
  }

  setSecurityContext(SecurityContext context) {
  }

  ///
  /// Handling Cloud Error Response
  /// 400 -
  /// 500 -
  ///
  Response _handleResponse(Response response) {
    // TODO Revisit - needs to considering about 500 internal server error, 502/503 bad requests
    if (response.statusCode >= 400) {
      logger.i('Cloud Error: ${response.statusCode}, ${response.body}');
      throw ErrorResponse.fromJson(json.decode(response.body));
    }
    return response;
  }
}
