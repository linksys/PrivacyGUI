import 'package:equatable/equatable.dart';

/// Safe browsing preset — off or OpenDNS Family Shield.
enum SafeBrowsingType { off, openDNS }

/// Presentation Layer Model for safe browsing state.
///
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
/// Implements [Equatable] per Article XI.
class SafeBrowsingUIModel extends Equatable {
  final SafeBrowsingType type;

  /// Raw DNS value from the router — for display purposes only.
  final String currentDnsServers;

  const SafeBrowsingUIModel({
    required this.type,
    this.currentDnsServers = '',
  });

  bool get isEnabled => type != SafeBrowsingType.off;

  @override
  List<Object?> get props => [type, currentDnsServers];
}
