
typedef DummyModel = Map<String, dynamic>;

@Deprecated('use [ErrorResponse] instead')
class CloudException implements Exception {
  CloudException(this.code, this.message);

  final String message;
  final String code;
}