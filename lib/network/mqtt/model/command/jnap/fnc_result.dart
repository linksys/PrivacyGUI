import 'dart:convert';

import 'package:equatable/equatable.dart';

/// status : 200
/// response : "{\"path\":\"antivirus\",\"build\":\"529\",\"version\":\"v7.2.0\",\"http_status\":200,\"name\":\"settings\",\"status\":\"success\",\"http_method\":\"GET\",\"serial\":\"\",\"results\":{\"grayware\":\"disable\",\"override-timeout\":\"0\",\"machine-learning-detection\":\"enable\",\"use-extreme-db\":\"disable\"}}"

class FNCResult extends Equatable {
  final int status;
  final FNCResponse response;

  const FNCResult({
    required this.status,
    required this.response,
  });

  FNCResult copyWith({
    int? status,
    FNCResponse? response,
  }) {
    return FNCResult(
      status: status ?? this.status,
      response: response ?? this.response,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'response': jsonEncode(response),
    };
  }

  factory FNCResult.fromJson(Map<String, dynamic> json) {
    return FNCResult(
      status: json['status'],
      response: FNCResponse.fromJson(jsonDecode(json['response'])),
    );
  }

  @override
  List<Object> get props => [status, response];
}

class FNCResponse extends Equatable {
  final String path;
  final String build;
  final String version;
  final int httpStatus;
  final String name;
  final String status;
  final String httpMethod;
  final String serial;
  final Map<String, dynamic> results;

  @override
  List<Object?> get props => [
        path,
        build,
        version,
        httpStatus,
        name,
        status,
        httpMethod,
        serial,
        results,
      ];

  const FNCResponse({
    required this.path,
    required this.build,
    required this.version,
    required this.httpStatus,
    required this.name,
    required this.status,
    required this.httpMethod,
    required this.serial,
    required this.results,
  });

  FNCResponse copyWith({
    String? path,
    String? build,
    String? version,
    int? httpStatus,
    String? name,
    String? status,
    String? httpMethod,
    String? serial,
    Map<String, dynamic>? results,
  }) {
    return FNCResponse(
      path: path ?? this.path,
      build: build ?? this.build,
      version: version ?? this.version,
      httpStatus: httpStatus ?? this.httpStatus,
      name: name ?? this.name,
      status: status ?? this.status,
      httpMethod: httpMethod ?? this.httpMethod,
      serial: serial ?? this.serial,
      results: results ?? this.results,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'build': build,
      'version': version,
      'http_status': httpStatus,
      'name': name,
      'status': status,
      'http_method': httpMethod,
      'serial': serial,
      'results': results,
    };
  }

  factory FNCResponse.fromJson(Map<String, dynamic> json) {
    return FNCResponse(
      path: json['path'],
      build: json['build'],
      version: json['version'],
      httpStatus: json['http_status'],
      name: json['name'],
      status: json['status'],
      httpMethod: json['http_method'],
      serial: json['serial'],
      results: json['results'] as Map<String, dynamic>,
    );
  }
}
