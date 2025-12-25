/// Network-related enumerations for USP/TR-181 protocol.
///
/// These enums provide type-safe values for network configuration.
library;

/// WAN connection type.
enum WanType {
  dhcp('DHCP'),
  static_('Static'),
  pppoe('PPPoE'),
  pptp('PPTP'),
  l2tp('L2TP'),
  bridge('Bridge');

  const WanType(this.value);
  final String value;

  static WanType? fromValue(String? value) {
    if (value == null) return null;
    return WanType.values.cast<WanType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// WAN connection status.
enum WanStatus {
  connected('Connected'),
  disconnected('Disconnected'),
  connecting('Connecting');

  const WanStatus(this.value);
  final String value;

  static WanStatus? fromValue(String? value) {
    if (value == null) return null;
    return WanStatus.values.cast<WanStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Internet connection status.
enum InternetConnectionStatus {
  connected('InternetConnected'),
  disconnected('InternetDisconnected'),
  checking('Checking');

  const InternetConnectionStatus(this.value);
  final String value;

  static InternetConnectionStatus? fromValue(String? value) {
    if (value == null) return null;
    return InternetConnectionStatus.values
        .cast<InternetConnectionStatus?>()
        .firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Ethernet port speed.
enum EthernetSpeed {
  disconnected('Disconnected'),
  mbps10('10Mbps'),
  mbps100('100Mbps'),
  gbps1('1Gbps'),
  gbps2_5('2.5Gbps'),
  gbps5('5Gbps'),
  gbps10('10Gbps');

  const EthernetSpeed(this.value);
  final String value;

  static EthernetSpeed? fromValue(String? value) {
    if (value == null) return null;
    return EthernetSpeed.values.cast<EthernetSpeed?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }

  /// Convert from MaxBitRate value (in Mbps).
  static EthernetSpeed fromBitRate(int bitRate) {
    switch (bitRate) {
      case 10:
        return EthernetSpeed.mbps10;
      case 100:
        return EthernetSpeed.mbps100;
      case 1000:
        return EthernetSpeed.gbps1;
      case 2500:
        return EthernetSpeed.gbps2_5;
      case 5000:
        return EthernetSpeed.gbps5;
      case 10000:
        return EthernetSpeed.gbps10;
      default:
        return EthernetSpeed.disconnected;
    }
  }
}
