sealed class AddNodesException {
  final String? message;
  AddNodesException({required this.message});
}

class ExceptionSmartConnectNotReady extends AddNodesException {
  ExceptionSmartConnectNotReady()
      : super(message: 'SmartConnect is not ready');
}

class ExceptionSmartConnectTimeout extends AddNodesException {
  ExceptionSmartConnectTimeout()
      : super(message: 'SmartConnect timeout after max retries');
}
