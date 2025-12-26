import 'package:equatable/equatable.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

/// The base class for all USP responses.
sealed class UspResponse extends UspMessage {
  /// Creates a const [UspResponse].
  const UspResponse();
}

/// A USP response to an [UspAddRequest].
class UspAddResponse extends UspResponse {
  /// A list of [UspCreatedObject] objects, each representing a successfully created object.
  final List<UspCreatedObject> createdObjects;

  /// A list of exceptions that occurred during the add operation.
  final List<UspException> errors;

  /// Creates a new [UspAddResponse].
  const UspAddResponse({
    this.createdObjects = const [],
    this.errors = const [],
  });

  @override
  List<Object?> get props => [createdObjects, errors];
}

/// A helper class that represents a successfully created object.
class UspCreatedObject extends Equatable {
  /// The path to the newly created object instance.
  final UspPath instantiatedPath;

  /// Creates a new [UspCreatedObject].
  const UspCreatedObject(this.instantiatedPath);

  @override
  List<Object?> get props => [instantiatedPath];
}

/// A USP response to a [UspDeleteRequest].
class UspDeleteResponse extends UspResponse {
  /// A list of paths to the objects that were successfully deleted.
  final List<UspPath> deletedPaths;

  /// A list of exceptions that occurred during the delete operation.
  final List<UspException> errors;

  /// Creates a new [UspDeleteResponse].
  const UspDeleteResponse({
    this.deletedPaths = const [],
    this.errors = const [],
  });

  @override
  List<Object?> get props => [deletedPaths, errors];
}

/// A USP error response.
class UspErrorResponse extends UspResponse {
  /// The exception that occurred.
  final UspException exception;

  /// Creates a new [UspErrorResponse].
  const UspErrorResponse(this.exception);

  @override
  List<Object?> get props => [exception];
}

/// A USP response to a [UspGetRequest].
class UspGetResponse extends UspResponse {
  /// A map of paths to the retrieved parameter values.
  final Map<UspPath, UspValue> results;

  /// Creates a new [UspGetResponse].
  const UspGetResponse(this.results);

  @override
  List<Object?> get props => [results];
}

/// A USP response to an [UspOperateRequest].
class UspOperateResponse extends UspResponse {
  /// A map of output arguments from the command execution.
  final Map<String, UspValue> outputArgs;

  /// Creates a new [UspOperateResponse].
  const UspOperateResponse({this.outputArgs = const {}});

  @override
  List<Object?> get props => [outputArgs];
}

/// A USP response to a [UspSetRequest].
class UspSetResponse extends UspResponse {
  /// A list of paths to the parameters that were successfully updated.
  final List<UspPath> successPaths;

  /// A map of paths to the parameters that failed to update, and the corresponding exceptions.
  final Map<UspPath, UspException> failurePaths;

  /// Creates a new [UspSetResponse].
  const UspSetResponse({
    this.successPaths = const [],
    this.failurePaths = const {},
  });

  /// Whether the set operation had any failures.
  bool get hasErrors => failurePaths.isNotEmpty;

  @override
  List<Object?> get props => [successPaths, failurePaths];
}

// A USP response to a [UspGetSupportedDMRequest].
class UspGetSupportedDMResponse extends UspResponse {
  // Path -> Object Definition
  final Map<String, UspObjectDefinition> results;

  const UspGetSupportedDMResponse(this.results);

  @override
  List<Object?> get props => [results];
}

/// A USP response to a [UspGetInstancesRequest].
class UspGetInstancesResponse extends UspResponse {
  // Path -> List of Instance Results (Map<ParamName, Value>)
  // If no Unique Key, Map is empty
  final Map<String, List<UspInstanceResult>> results;

  const UspGetInstancesResponse(this.results);

  @override
  List<Object?> get props => [results];
}

/// Describes the result of an instance retrieval.
class UspInstanceResult extends Equatable {
  final String instantiatedPath;
  final Map<String, String> uniqueKeys;

  const UspInstanceResult(this.instantiatedPath, {this.uniqueKeys = const {}});

  @override
  List<Object?> get props => [instantiatedPath, uniqueKeys];
}

/// A USP response to a [UspNotify] request.
/// Sent by the Controller to acknowledge receipt of a notification.
class UspNotifyResponse extends UspResponse {
  /// The subscription ID that caused the notification.
  /// This confirms to the Agent which subscription is being acknowledged.
  final String subscriptionId;

  /// Creates a new [UspNotifyResponse].
  const UspNotifyResponse({required this.subscriptionId});

  @override
  List<Object?> get props => [subscriptionId];
}
