import 'package:equatable/equatable.dart';

/// Abstract interface for all network entities (nodes and clients).
///
/// Provides a common interface for identity and display across the
/// MeshNetwork architecture. Implementers: [NodeEntity], [ClientDevice].
abstract class NetworkEntity with EquatableMixin {
  /// Unique identifier (MAC address, normalized uppercase).
  String get id;

  /// Display name for UI (computed from available name fields).
  String get displayName;

  /// Whether the entity is currently online/active.
  bool get isOnline;

  /// Primary IPv4 address, or null if unavailable.
  String? get ipAddress;

  /// All IPv6 addresses for this entity.
  List<String> get ipv6Addresses;
}
