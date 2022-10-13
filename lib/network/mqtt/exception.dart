
class MqttTimeoutException implements Exception {
  MqttTimeoutException(this.message);

  final String message;

  @override
  String toString() {
    return '$runtimeType: $message';
  }
}