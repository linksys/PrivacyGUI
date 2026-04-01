import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';

enum DiagnosticLoadState { idle, loading, loaded, error }

class CsDiagnosticState extends Equatable {
  final DiagnosticLoadState loadState;
  final List<DiagnosticClient> clients;
  final Map<String, dynamic>? wanStatus;
  final Map<String, dynamic>? routerHealth;
  final Map<String, dynamic>? deviceInfo;
  final int dhcpLeasesCount;
  final int dhcpPoolLimit;
  final Map<String, dynamic>? radioInfo;
  final Map<String, dynamic>? guestNetwork;
  final Map<String, dynamic>? firmwareUpdate;
  final Map<String, dynamic>? backhaulInfo;
  final Map<String, dynamic>? macFilter;
  final Map<String, dynamic>? networkSecurity;
  final Map<String, dynamic>? parentalControls;
  final Map<String, dynamic>? wirelessSchedule;
  final Map<String, dynamic>? channelInfo;
  final Map<String, dynamic>? ethernetPorts;
  final String? errorMessage;

  const CsDiagnosticState({
    this.loadState = DiagnosticLoadState.idle,
    this.clients = const [],
    this.wanStatus,
    this.routerHealth,
    this.deviceInfo,
    this.dhcpLeasesCount = 0,
    this.dhcpPoolLimit = 150,
    this.radioInfo,
    this.guestNetwork,
    this.firmwareUpdate,
    this.backhaulInfo,
    this.macFilter,
    this.networkSecurity,
    this.parentalControls,
    this.wirelessSchedule,
    this.channelInfo,
    this.ethernetPorts,
    this.errorMessage,
  });

  CsDiagnosticState copyWith({
    DiagnosticLoadState? loadState,
    List<DiagnosticClient>? clients,
    Map<String, dynamic>? wanStatus,
    Map<String, dynamic>? routerHealth,
    Map<String, dynamic>? deviceInfo,
    int? dhcpLeasesCount,
    int? dhcpPoolLimit,
    Map<String, dynamic>? radioInfo,
    Map<String, dynamic>? guestNetwork,
    Map<String, dynamic>? firmwareUpdate,
    Map<String, dynamic>? backhaulInfo,
    Map<String, dynamic>? macFilter,
    Map<String, dynamic>? networkSecurity,
    Map<String, dynamic>? parentalControls,
    Map<String, dynamic>? wirelessSchedule,
    Map<String, dynamic>? channelInfo,
    Map<String, dynamic>? ethernetPorts,
    String? errorMessage,
  }) => CsDiagnosticState(
    loadState: loadState ?? this.loadState,
    clients: clients ?? this.clients,
    wanStatus: wanStatus ?? this.wanStatus,
    routerHealth: routerHealth ?? this.routerHealth,
    deviceInfo: deviceInfo ?? this.deviceInfo,
    dhcpLeasesCount: dhcpLeasesCount ?? this.dhcpLeasesCount,
    dhcpPoolLimit: dhcpPoolLimit ?? this.dhcpPoolLimit,
    radioInfo: radioInfo ?? this.radioInfo,
    guestNetwork: guestNetwork ?? this.guestNetwork,
    firmwareUpdate: firmwareUpdate ?? this.firmwareUpdate,
    backhaulInfo: backhaulInfo ?? this.backhaulInfo,
    macFilter: macFilter ?? this.macFilter,
    networkSecurity: networkSecurity ?? this.networkSecurity,
    parentalControls: parentalControls ?? this.parentalControls,
    wirelessSchedule: wirelessSchedule ?? this.wirelessSchedule,
    channelInfo: channelInfo ?? this.channelInfo,
    ethernetPorts: ethernetPorts ?? this.ethernetPorts,
    errorMessage: errorMessage,
  );

  double get dhcpUtilization => dhcpPoolLimit > 0 ? dhcpLeasesCount / dhcpPoolLimit : 0;

  bool get wanConnected {
    if (wanStatus == null) return false;
    final status = wanStatus!['wanStatus'] as String?;
    return status == 'Connected' || status == 'connected';
  }

  int get routerUptimeSeconds {
    if (routerHealth == null) return 0;
    return (routerHealth!['uptimeInSeconds'] as int?) ?? 0;
  }

  List<DiagnosticClient> get flaggedClients => clients.where((c) => c.isFlagged).toList();

  int get complexityScore {
    int score = 0;
    score += (clients.length / 10).floor().clamp(0, 4);
    if (dhcpUtilization > 0.7) score += 2;
    if (!wanConnected) score += 1;
    if (routerUptimeSeconds < 3600) score += 2;
    return score.clamp(0, 10);
  }

  /// Whether band steering is enabled (from radioInfo).
  bool get bandSteeringEnabled {
    if (radioInfo == null) return false;
    return radioInfo!['isBandSteeringSupported'] == true;
  }

  /// Whether guest network is enabled.
  bool get guestNetworkEnabled {
    if (guestNetwork == null) return false;
    return guestNetwork!['isGuestNetworkEnabled'] == true;
  }

  /// Firmware update available.
  bool get firmwareUpdateAvailable {
    if (firmwareUpdate == null) return false;
    final status = firmwareUpdate!['firmwareUpdateStatus'] as String?;
    return status == 'UpdateAvailable';
  }

  String? get availableFirmwareVersion {
    return firmwareUpdate?['availableUpdate']?['firmwareVersion'] as String?;
  }

  /// MAC filter mode: 'Allow' (whitelist), 'Deny' (blacklist), or null if disabled/unavailable.
  String? get macFilterMode {
    if (macFilter == null) return null;
    final mode = macFilter!['macFilterMode'] as String?;
    // "Disabled" means MAC filtering is off — treat as null
    if (mode == null || mode == 'Disabled' || mode == 'disabled') return null;
    final enabled = macFilter!['isEnabled'] as bool? ?? true;
    if (!enabled) return null;
    return mode;
  }

  /// Whether parental controls are active.
  bool get parentalControlsEnabled {
    if (parentalControls == null) return false;
    return parentalControls!['isParentalControlEnabled'] == true;
  }

  /// Whether WiFi scheduling is active (WiFi turns off at certain times).
  bool get wirelessScheduleEnabled {
    if (wirelessSchedule == null) return false;
    return wirelessSchedule!['isWirelessSchedulerEnabled'] == true;
  }

  /// Security mode (WPA2, WPA3, etc).
  String? get securityMode {
    if (networkSecurity == null) return null;
    return networkSecurity!['securityMode'] as String? ??
        networkSecurity!['wpaPersonalSettings']?['securityMode'] as String?;
  }

  @override
  List<Object?> get props => [loadState, clients, wanStatus, routerHealth, deviceInfo, dhcpLeasesCount, dhcpPoolLimit, radioInfo, guestNetwork, firmwareUpdate, backhaulInfo, macFilter, networkSecurity, parentalControls, wirelessSchedule, channelInfo, ethernetPorts, errorMessage];
}
