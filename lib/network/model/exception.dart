
class MqttTimeoutException implements Exception {
  MqttTimeoutException(this.message);

  final String message;
}