import 'dart:convert';

import 'package:equatable/equatable.dart';

/// status : 200
/// response : "{\"path\":\"antivirus\",\"build\":\"529\",\"version\":\"v7.2.0\",\"http_status\":200,\"name\":\"settings\",\"status\":\"success\",\"http_method\":\"GET\",\"serial\":\"\",\"results\":{\"grayware\":\"disable\",\"override-timeout\":\"0\",\"machine-learning-detection\":\"enable\",\"use-extreme-db\":\"disable\"}}"

class FCNResult extends Equatable {
  final int status;
  final FCNResponse response;

  const FCNResult({
    required this.status,
    required this.response,
  });

  FCNResult copyWith({
    int? status,
    FCNResponse? response,
  }) {
    return FCNResult(
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

  factory FCNResult.fromJson(Map<String, dynamic> json) {
    return FCNResult(
      status: json['status'],
      response: FCNResponse.fromJson(jsonDecode(json['response'])),
    );
  }

  @override
  List<Object> get props => [status, response];
}

class FCNResponse extends Equatable {
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

  const FCNResponse({
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

  FCNResponse copyWith({
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
    return FCNResponse(
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

  factory FCNResponse.fromJson(Map<String, dynamic> json) {
    return FCNResponse(
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
