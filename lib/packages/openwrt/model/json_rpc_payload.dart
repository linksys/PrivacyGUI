class JsonRpcPayload {
  const JsonRpcPayload(
      {required this.id, required this.method, required this.params});

  final String version = "2.0";
  final String id;
  final String method;
  final List<dynamic> params;

  Map toJson() =>
      {"jsonrpc": version, "id": id, "method": method, "params": params};

  static JsonRpcPayload fromJson(Map<String, dynamic> json) {
    return JsonRpcPayload(
        id: json['id'].toString(),
        method: json['method'].toString(),
        params: json['params']);
  }
}
