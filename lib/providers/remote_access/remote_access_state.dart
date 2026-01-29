import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Represents the remote access state of the application.
///
/// This immutable class holds information about whether the application
/// is currently in remote read-only mode, where router configuration
/// changes are disabled for security reasons.
class RemoteAccessState extends Equatable {
  /// Whether the application is in remote read-only mode.
  ///
  /// When true, all router configuration changes (JNAP SET operations)
  /// should be disabled in the UI and blocked at the service layer.
  final bool isRemoteReadOnly;

  const RemoteAccessState({
    required this.isRemoteReadOnly,
  });

  /// Creates a copy of this [RemoteAccessState] with the given fields replaced.
  ///
  /// Any parameter that is not provided will retain its current value.
  RemoteAccessState copyWith({
    bool? isRemoteReadOnly,
  }) {
    return RemoteAccessState(
      isRemoteReadOnly: isRemoteReadOnly ?? this.isRemoteReadOnly,
    );
  }

  /// Creates a [RemoteAccessState] from a JSON map.
  factory RemoteAccessState.fromMap(Map<String, dynamic> map) {
    return RemoteAccessState(
      isRemoteReadOnly: map['isRemoteReadOnly'] as bool? ?? false,
    );
  }

  /// Creates a [RemoteAccessState] from a JSON string.
  factory RemoteAccessState.fromJson(String source) =>
      RemoteAccessState.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Converts this [RemoteAccessState] to a JSON map.
  Map<String, dynamic> toMap() {
    return {
      'isRemoteReadOnly': isRemoteReadOnly,
    };
  }

  /// Converts this [RemoteAccessState] to a JSON string.
  String toJson() => jsonEncode(toMap());

  @override
  List<Object?> get props => [isRemoteReadOnly];
}
