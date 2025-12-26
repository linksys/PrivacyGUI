import 'package:equatable/equatable.dart';

/// The base class for all USP messages (requests and responses).
abstract class UspMessage extends Equatable {
  /// Creates a const [UspMessage].
  const UspMessage();

  @override
  List<Object?> get props => [];
}
