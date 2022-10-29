import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/device.dart';

class LANState extends Equatable {
  final String ipAddress;
  final String subnetMask;
  final bool isDHCPEnabled;
  final String startIPAddress;
  final int maxNumUser;
  final int clientLeaseTime;
  final int maxAllowDHCPLeaseMinutes;
  final bool isAutoDNS;
  final String? dns1;
  final String? dns2;
  final String? dns3;
  final String? error;

  @override
  List<Object?> get props => [
        ipAddress,
        subnetMask,
        isDHCPEnabled,
        startIPAddress,
        maxNumUser,
        clientLeaseTime,
        maxAllowDHCPLeaseMinutes,
        isAutoDNS,
        dns1,
        dns2,
        dns3,
        error
      ];

  const LANState({
    required this.ipAddress,
    required this.subnetMask,
    required this.isDHCPEnabled,
    required this.startIPAddress,
    required this.maxNumUser,
    required this.clientLeaseTime,
    required this.maxAllowDHCPLeaseMinutes,
    required this.isAutoDNS,
    this.dns1,
    this.dns2,
    this.dns3,
    this.error,
  });

  factory LANState.init() {
    return const LANState(
      ipAddress: '',
      subnetMask: '',
      isDHCPEnabled: false,
      startIPAddress: '',
      maxNumUser: 0,
      clientLeaseTime: 0,
      maxAllowDHCPLeaseMinutes: 0,
      isAutoDNS: false,
      dns1: '',
      dns2: '',
      dns3: '',
      error: null,
    );
  }

  LANState copyWith({
    String? ipAddress,
    String? subnetMask,
    bool? isDHCPEnabled,
    String? startIPAddress,
    int? maxNumUser,
    int? clientLeaseTime,
    int? maxAllowDHCPLeaseMinutes,
    bool? isAutoDNS,
    String? dns1,
    String? dns2,
    String? dns3,
    String? error,
  }) {
    return LANState(
      ipAddress: ipAddress ?? this.ipAddress,
      subnetMask: subnetMask ?? this.subnetMask,
      isDHCPEnabled: isDHCPEnabled ?? this.isDHCPEnabled,
      startIPAddress: startIPAddress ?? this.startIPAddress,
      maxNumUser: maxNumUser ?? this.maxNumUser,
      clientLeaseTime: clientLeaseTime ?? this.clientLeaseTime,
      maxAllowDHCPLeaseMinutes:
          maxAllowDHCPLeaseMinutes ?? this.maxAllowDHCPLeaseMinutes,
      isAutoDNS: isAutoDNS ?? this.isAutoDNS,
      dns1: dns1 ?? this.dns1,
      dns2: dns2 ?? this.dns2,
      dns3: dns3 ?? this.dns3,
      error: error ?? this.error,
    );
  }
}
