
typedef DummyModel = Map<String, dynamic>;

class CloudException implements Exception {
  CloudException(this.code, this.message);

  final String message;
  final String code;
}