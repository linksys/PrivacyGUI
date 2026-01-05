import 'package:usp_protocol_common/src/exceptions/usp_exception.dart';

class InstanceId {
  final int id;

  InstanceId(this.id) {
    if (id < 0) {
      throw UspException(7003, 'InstanceId cannot be negative');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstanceId && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'InstanceId($id)';
}
