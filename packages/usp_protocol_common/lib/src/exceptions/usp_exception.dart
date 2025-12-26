import 'package:equatable/equatable.dart';

/// An exception that occurred during a USP operation.
class UspException extends Equatable implements Exception {
  /// The USP error code.
  final int errorCode;

  /// A human-readable message describing the error.
  final String message;

  /// Creates a new [UspException].
  const UspException(this.errorCode, this.message);

  @override
  String toString() => 'UspException($errorCode): $message';

  @override
  List<Object?> get props => [errorCode, message];
}
