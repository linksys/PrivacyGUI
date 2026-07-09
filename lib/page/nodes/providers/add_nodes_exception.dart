sealed class AddNodesException {
  final String? message;
  AddNodesException({required this.message});
}

class ExceptionSmartConnectTimeout extends AddNodesException {
  ExceptionSmartConnectTimeout()
      : super(message: 'SmartConnect timeout after max retries');
}
