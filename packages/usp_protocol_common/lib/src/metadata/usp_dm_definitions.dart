import 'package:equatable/equatable.dart';
import '../value_objects/usp_value_type.dart';

/// --------------------------------------------------------------------------
/// Metadata Type Alias (供 Repository 介面使用)
/// --------------------------------------------------------------------------

/// The top-level map of the entire Data Model's Supported Capabilities.
/// Key is the requested path, Value is the object definition at that path.
typedef UspSupportedDMObject = Map<String, UspObjectDefinition>;

/// --------------------------------------------------------------------------
/// Shared Metadata Structures (Used for GetSupportedDM)
/// --------------------------------------------------------------------------

/// Describes the "capabilities" of an Object
class UspObjectDefinition extends Equatable {
  final String path;
  final bool isMultiInstance;
  final String access; // "ReadOnly", "ReadWrite", etc.
  final Map<String, UspParamDefinition> supportedParams;
  final Map<String, UspCommandDefinition> supportedCommands;
  // For Add/Delete, this is the basis (e.g. MAC address may be a unique key)
  final List<List<String>> uniqueKeySets;
  // For complex XML, this is used to declare structural differences
  final List<String> divergentPaths;

  const UspObjectDefinition({
    required this.path,
    this.isMultiInstance = false,
    this.access = "ReadOnly",
    this.supportedParams = const {},
    this.supportedCommands = const {},
    this.uniqueKeySets = const [],
    this.divergentPaths = const [],
  });

  @override
  List<Object?> get props => [
    path,
    isMultiInstance,
    access,
    supportedParams,
    supportedCommands,
    uniqueKeySets,
    divergentPaths,
  ];
}

/// Describes the "capabilities" of a Parameter
class UspParamDefinition extends Equatable {
  final String name;
  final UspValueType type;
  final bool isWritable;
  final UspParamConstraints constraints;

  const UspParamDefinition({
    required this.name,
    required this.type,
    required this.isWritable,
    required this.constraints,
  });

  @override
  List<Object?> get props => [name, type, isWritable, constraints];
}

/// Describes the "capabilities" of a Command's Input/Output Arguments
class UspArgumentDefinition extends Equatable {
  final String name;
  final UspValueType type;

  const UspArgumentDefinition({required this.name, required this.type});

  @override
  List<Object?> get props => [name, type];
}

/// Describes the "capabilities" of a Command
class UspCommandDefinition extends Equatable {
  final String name;
  final Map<String, UspArgumentDefinition> inputArgs;
  final Map<String, UspArgumentDefinition> outputArgs;
  final bool isAsync;

  const UspCommandDefinition({
    required this.name,
    this.inputArgs = const {},
    this.outputArgs = const {},
    this.isAsync = false,
  });

  @override
  List<Object?> get props => [name, inputArgs, outputArgs, isAsync];
}

class UspParamConstraints extends Equatable {
  final int? min; // min (From XML <range minInclusive="...">)
  final int? max; // max (From XML <range maxInclusive="...">)
  final int? maxLength; // maxLength (From XML <size maxLength="...">)
  final List<String>
  enumeration; // enumeration (From XML <enumeration value="...">)

  const UspParamConstraints({
    this.min,
    this.max,
    this.maxLength,
    this.enumeration = const [],
  });

  @override
  List<Object?> get props => [min, max, maxLength, enumeration];
}
