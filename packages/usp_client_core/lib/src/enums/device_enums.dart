/// Device-related enumerations for USP/TR-181 protocol.
///
/// These enums provide type-safe values for device configuration.
library;

/// Network interface type.
enum InterfaceType {
  wireless('Wireless'),
  wired('Wired'),
  infrastructure('Infrastructure');

  const InterfaceType(this.value);
  final String value;

  static InterfaceType? fromValue(String? value) {
    if (value == null) return null;
    return InterfaceType.values.cast<InterfaceType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }

  /// Convert from TR-181 InterfaceType value.
  static InterfaceType fromTr181(String? tr181Type) {
    if (tr181Type == '802.11') return InterfaceType.wireless;
    if (tr181Type == 'Ethernet') return InterfaceType.wired;
    return InterfaceType.wired; // Default
  }
}

/// Device type in the network.
enum DeviceType {
  computer('Computer'),
  mobile('Mobile'),
  tablet('Tablet'),
  printer('Printer'),
  camera('Camera'),
  tv('TV'),
  speaker('Speaker'),
  infrastructure('Infrastructure'),
  unknown('Unknown');

  const DeviceType(this.value);
  final String value;

  static DeviceType? fromValue(String? value) {
    if (value == null) return null;
    return DeviceType.values.cast<DeviceType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Mesh node type.
enum NodeType {
  master('Master'),
  slave('Slave');

  const NodeType(this.value);
  final String value;

  static NodeType? fromValue(String? value) {
    if (value == null) return null;
    return NodeType.values.cast<NodeType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Backhaul connection type.
enum BackhaulType {
  none('None'),
  wifi('Wi-Fi'),
  ethernet('Ethernet');

  const BackhaulType(this.value);
  final String value;

  static BackhaulType? fromValue(String? value) {
    if (value == null) return null;
    return BackhaulType.values.cast<BackhaulType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }

  /// Check if this is the master node (no backhaul).
  bool get isMaster => this == BackhaulType.none;

  /// Convert to connection type string.
  String get connectionType {
    switch (this) {
      case BackhaulType.wifi:
        return 'Wireless';
      case BackhaulType.ethernet:
        return 'Wired';
      case BackhaulType.none:
        return 'None';
    }
  }
}

/// MAC filter mode.
enum MacFilterMode {
  allow('Allow'),
  deny('Deny');

  const MacFilterMode(this.value);
  final String value;

  static MacFilterMode? fromValue(String? value) {
    if (value == null) return null;
    return MacFilterMode.values.cast<MacFilterMode?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }

  /// Convert from boolean isEnabled.
  static MacFilterMode fromEnabled(bool isEnabled) {
    return isEnabled ? MacFilterMode.allow : MacFilterMode.deny;
  }
}
