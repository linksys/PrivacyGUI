import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/wan_status.dart';

class InternetSettingsState extends Equatable {
  final String ipv4ConnectionType;
  final String ipv6ConnectionType;
  final List<String> supportedIPv4ConnectionType;
  final List<String> supportedIPv6ConnectionType;
  final List<SupportedWANCombination> supportedWANCombinations;
  final Map<String, Map> connectionData;
  final String duid;
  final bool isIPv6AutomaticEnabled;
  final int mtu;
  final bool macClone;
  final String macCloneAddress;
  final String? error;

  @override
  List<Object?> get props => [
        ipv4ConnectionType,
        ipv6ConnectionType,
        supportedIPv4ConnectionType,
        supportedIPv6ConnectionType,
        supportedWANCombinations,
        connectionData,
        duid,
        isIPv6AutomaticEnabled,
        mtu,
        macClone,
        macCloneAddress,
        error,
      ];

  const InternetSettingsState({
    required this.ipv4ConnectionType,
    required this.ipv6ConnectionType,
    required this.supportedIPv4ConnectionType,
    required this.supportedIPv6ConnectionType,
    required this.supportedWANCombinations,
    required this.connectionData,
    required this.duid,
    required this.isIPv6AutomaticEnabled,
    required this.mtu,
    required this.macClone,
    required this.macCloneAddress,
    this.error,
  });

  factory InternetSettingsState.init() {
    return const InternetSettingsState(
      ipv4ConnectionType: '',
      ipv6ConnectionType: '',
      supportedIPv4ConnectionType: [],
      supportedIPv6ConnectionType: [],
      supportedWANCombinations: [],
      connectionData: {},
      duid: '',
      isIPv6AutomaticEnabled: false,
      mtu: 0,
      macClone: false,
      macCloneAddress: '',
      error: null,
    );
  }

  InternetSettingsState copyWith({
    String? ipv4ConnectionType,
    String? ipv6ConnectionType,
    List<String>? supportedIPv4ConnectionType,
    List<String>? supportedIPv6ConnectionType,
    List<SupportedWANCombination>? supportedWANCombinations,
    Map<String, Map>? connectionData,
    String? duid,
    bool? isIPv6AutomaticEnabled,
    int? mtu,
    bool? macClone,
    String? macCloneAddress,
    String? error,
  }) {
    return InternetSettingsState(
      ipv4ConnectionType: ipv4ConnectionType ?? this.ipv4ConnectionType,
      ipv6ConnectionType: ipv6ConnectionType ?? this.ipv6ConnectionType,
      supportedIPv4ConnectionType:
          supportedIPv4ConnectionType ?? this.supportedIPv4ConnectionType,
      supportedIPv6ConnectionType:
          supportedIPv6ConnectionType ?? this.supportedIPv6ConnectionType,
      supportedWANCombinations:
          supportedWANCombinations ?? this.supportedWANCombinations,
      connectionData: connectionData ?? this.connectionData,
      duid: duid ?? this.duid,
      isIPv6AutomaticEnabled:
          isIPv6AutomaticEnabled ?? this.isIPv6AutomaticEnabled,
      mtu: mtu ?? this.mtu,
      macClone: macClone ?? this.macClone,
      macCloneAddress: macCloneAddress ?? this.macCloneAddress,
      error: error ?? this.error,
    );
  }
}
