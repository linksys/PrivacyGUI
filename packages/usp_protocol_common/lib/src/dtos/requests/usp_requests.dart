import 'package:equatable/equatable.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

/// The base class for all USP requests.
sealed class UspRequest extends UspMessage {
  /// Creates a const [UspRequest].
  const UspRequest();
}

/// A USP request to add a new object to the data model.
class UspAddRequest extends UspRequest {
  /// A list of [UspObjectCreation] objects, each describing an object to be created.
  final List<UspObjectCreation> objects;

  /// Whether partial creation is allowed. If true, the agent will attempt to create all
  /// objects, even if some fail. If false, the entire operation will fail if any
  /// object creation fails.
  final bool allowPartial;

  /// Creates a new [UspAddRequest].
  const UspAddRequest(this.objects, {this.allowPartial = false});

  @override
  List<Object?> get props => [objects, allowPartial];
}

/// A helper class that describes the creation of a single object.
class UspObjectCreation extends Equatable {
  /// The path to the parent object under which the new object will be created.
  final UspPath parentPath;

  /// A map of parameters to be set on the newly created object.
  final Map<String, UspValue> parameters;

  /// Creates a new [UspObjectCreation].
  const UspObjectCreation(this.parentPath, {this.parameters = const {}});

  @override
  List<Object?> get props => [parentPath, parameters];
}

/// A USP request to delete an object from the data model.
class UspDeleteRequest extends UspRequest {
  /// A list of paths to the objects to be deleted.
  final List<UspPath> objPaths;

  /// Whether partial deletion is allowed. If true, the agent will attempt to delete all
  /// objects, even if some fail. If false, the entire operation will fail if any
  /// object deletion fails.
  final bool allowPartial;

  /// Creates a new [UspDeleteRequest].
  const UspDeleteRequest(this.objPaths, {this.allowPartial = false});

  @override
  List<Object?> get props => [objPaths, allowPartial];
}

/// A USP request to get parameter values from the data model.
class UspGetRequest extends UspRequest {
  /// A list of paths to the parameters to be retrieved. Wildcards are supported.
  final List<UspPath> paths;

  /// Creates a new [UspGetRequest].
  const UspGetRequest(this.paths);

  @override
  List<Object?> get props => [paths];
}

/// A USP request to execute a command on the agent.
class UspOperateRequest extends UspRequest {
  /// The command to be executed.
  final UspPath command;

  /// A map of input arguments for the command.
  final Map<String, UspValue> inputArgs;

  /// Creates a new [UspOperateRequest].
  const UspOperateRequest({required this.command, this.inputArgs = const {}});

  @override
  List<Object?> get props => [command, inputArgs];
}

/// A USP request to set parameter values in the data model.
class UspSetRequest extends UspRequest {
  /// A map of paths to the parameters to be updated, and the new values.
  final Map<UspPath, UspValue> updates;

  /// Whether partial updates are allowed. If true, the agent will attempt to update all
  /// parameters, even if some fail. If false, the entire operation will fail if any
  /// parameter update fails.
  final bool allowPartial;

  /// Creates a new [UspSetRequest].
  const UspSetRequest(this.updates, {this.allowPartial = false});

  @override
  List<Object?> get props => [updates, allowPartial];
}

// A USP request to get supported data model information from the agent.
class UspGetSupportedDMRequest extends UspRequest {
  // Use ["Device."] to get all
  final List<UspPath> objPaths;

  // Whether to only fetch the first level (Lazy Loading)
  final bool firstLevelOnly;

  // Whether to include Command information
  final bool returnCommands;

  // Whether to include Event information
  final bool returnEvents;

  // Whether to include Parameter information
  final bool returnParams;

  const UspGetSupportedDMRequest(
    this.objPaths, {
    this.firstLevelOnly = false,
    this.returnCommands = true,
    this.returnEvents = true,
    this.returnParams = true,
  });

  @override
  List<Object?> get props => [
    objPaths,
    firstLevelOnly,
    returnCommands,
    returnEvents,
    returnParams,
  ];
}

class UspGetInstancesRequest extends UspRequest {
  final List<UspPath> objPaths;
  final bool firstLevelOnly;

  const UspGetInstancesRequest(this.objPaths, {this.firstLevelOnly = false});

  @override
  List<Object?> get props => [objPaths, firstLevelOnly];
}

// ==========================================================================
// Notification DTOs
// ==========================================================================

/// The base class for all USP Notifications.
/// In USP, a Notify is technically a Request sent by the Agent to the Controller.
sealed class UspNotify extends UspRequest {
  /// An identifier for the subscription that triggered this notification.
  final String subscriptionId;

  /// Whether the Agent expects a response from the Controller.
  final bool sendResp;

  const UspNotify({this.subscriptionId = "", this.sendResp = false});

  @override
  List<Object?> get props => [subscriptionId, sendResp];
}

/// Notify of type ValueChange.
/// Triggered when a subscribed parameter's value changes.
class UspValueChangeNotify extends UspNotify {
  /// The path of the parameter that changed.
  final UspPath paramPath;

  /// The new value of the parameter (transmitted as String in Protobuf).
  final String paramValue;

  const UspValueChangeNotify({
    required this.paramPath,
    required this.paramValue,
    super.subscriptionId,
    super.sendResp,
  });

  @override
  List<Object?> get props => [...super.props, paramPath, paramValue];
}

/// Notify of type ObjectCreation.
/// Triggered when a new object instance is added to a subscribed table.
class UspObjectCreationNotify extends UspNotify {
  /// The path of the newly created object (e.g., Device.WiFi.SSID.1).
  final UspPath objPath;

  /// Unique keys of the created object (Optional map of param name -> value).
  final Map<String, String> uniqueKeys;

  const UspObjectCreationNotify({
    required this.objPath,
    this.uniqueKeys = const {},
    super.subscriptionId,
    super.sendResp,
  });

  @override
  List<Object?> get props => [...super.props, objPath, uniqueKeys];
}

/// Notify of type ObjectDeletion.
/// Triggered when an object instance is removed from a subscribed table.
class UspObjectDeletionNotify extends UspNotify {
  /// The path of the deleted object.
  final UspPath objPath;

  const UspObjectDeletionNotify({
    required this.objPath,
    super.subscriptionId,
    super.sendResp,
  });

  @override
  List<Object?> get props => [...super.props, objPath];
}

/// Notify of type OperationComplete.
/// Triggered when an asynchronous [Operate] command finishes.
class UspOperationCompleteNotify extends UspNotify {
  /// The path of the object where the command was executed.
  final UspPath objPath;

  /// The name of the command (e.g., "Reboot").
  final String commandName;

  /// The unique key associated with the original Operate request.
  final String commandKey;

  /// The output arguments if the operation succeeded (Map<String, String> in Proto).
  final Map<String, String> outputArgs;

  /// The error details if the operation failed. Null if successful.
  final UspException? commandFailure;

  const UspOperationCompleteNotify({
    required this.objPath,
    required this.commandName,
    required this.commandKey,
    this.outputArgs = const {},
    this.commandFailure,
    super.subscriptionId,
    super.sendResp,
  });

  bool get isSuccess => commandFailure == null;

  @override
  List<Object?> get props => [
    ...super.props,
    objPath,
    commandName,
    commandKey,
    outputArgs,
    commandFailure,
  ];
}

/// Notify of type OnBoardRequest.
/// Sent by the Agent when it first comes online or needs to establish a relationship.
class UspOnBoardRequestNotify extends UspNotify {
  final String oui;
  final String productClass;
  final String serialNumber;
  final String agentProtocolVersions;

  const UspOnBoardRequestNotify({
    required this.oui,
    required this.productClass,
    required this.serialNumber,
    required this.agentProtocolVersions,
    super.sendResp = true, // OnBoard usually requires a response
  });

  @override
  List<Object?> get props => [
    ...super.props,
    oui,
    productClass,
    serialNumber,
    agentProtocolVersions,
  ];
}
